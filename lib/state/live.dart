import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/constants.dart';
import '../data/api/live_socket.dart';
import '../data/models/models.dart';
import 'connection.dart';

/// 궤적으로 남기는 시간
const trailWindow = Duration(seconds: 5);

/// "나타난 곳"을 문 쪽으로 볼 거리 (m)
const doorZoneM = 1.0;

class TrailPoint {
  const TrailPoint(this.t, this.x, this.y);
  final DateTime t; // 파이 시각 (frame.t)
  final double x;
  final double y;
}

/// 프레임 속 한 사람 + 최근 궤적
class TrackedPerson {
  const TrackedPerson({required this.person, required this.trail, required this.firstX, required this.firstY});

  final LivePerson person;

  /// 오래된 것 → 최신, 최근 [trailWindow] 동안 (지금 위치 포함)
  final List<TrailPoint> trail;

  /// 처음 보인 위치 ("나타난 곳")
  final double firstX;
  final double firstY;

  String get id => person.id;
  bool get abnormal => person.abnormal;

  /// 문(레이더)에서의 거리 (m)
  double get distance => math.sqrt(person.x * person.x + person.y * person.y);

  String get appearedAt => appearedFrom(firstX, firstY);
}

/// 처음 보인 위치 → "문 쪽" / "외곽"
String appearedFrom(double x, double y) => math.sqrt(x * x + y * y) <= doorZoneM ? '문 쪽' : '외곽';

/// 진행 중 판정 카드 순서: 이상 상황인 사람 먼저, 그다음 문에서 가까운 사람.
List<TrackedPerson> cardOrder(Iterable<TrackedPerson> people) {
  final list = [...people];
  list.sort((a, b) {
    if (a.abnormal != b.abnormal) return a.abnormal ? -1 : 1;
    return a.distance.compareTo(b.distance);
  });
  return list;
}

/// 사람 id 가 같은 사람인지. 서버가 타깃을 묶으면 "T3" 가 "T3+7" 이 되므로 조각이 겹치면 같은 사람으로 본다.
/// "T3+7" 의 조각은 "T3", "7" 이라 앞 글자를 떼고 번호로 비교한다.
bool samePerson(String a, String b) {
  if (a == b) return true;
  Set<String> parts(String id) => id.split('+').map((p) => p.replaceFirst(RegExp(r'^[^0-9]+'), '')).toSet();
  final pa = parts(a);
  return parts(b).any(pa.contains);
}

class LiveState {
  const LiveState({this.people = const [], this.radar, this.pi, this.frameT, this.frameCount = 0});

  /// 프레임에 온 순서 그대로
  final List<TrackedPerson> people;

  /// 마지막 프레임의 `radar` ("ok" 이면 정상). 프레임을 아직 못 받았으면 null.
  final String? radar;

  /// 마지막 프레임의 `pi` (클라우드, SPEC 9.1). "offline" 이면 파이가 클라우드에 안 붙어 있다.
  final String? pi;

  /// 마지막 프레임의 `t` (파이 시각 문자열). 다시 붙었을 때 `since=` 에 쓴다.
  final String? frameT;

  /// 연결 후 받은 프레임 수 (이상 배너 접기 판단 등)
  final int frameCount;

  bool get hasFrame => frameT != null;
  bool get radarOk => radar == 'ok';
  bool get piOffline => pi == 'offline';

  TrackedPerson? find(String id) {
    for (final p in people) {
      if (samePerson(p.id, id)) return p;
    }
    return null;
  }
}

/// 프레임 하나를 반영한 다음 상태. 순수 함수라 테스트에서 바로 쓴다.
LiveState applyFrame(LiveState prev, LiveFrame frame) {
  final t = DateTime.tryParse(frame.t) ?? DateTime.now();
  final cutoff = t.subtract(trailWindow);
  final before = {for (final p in prev.people) p.id: p};

  final people = <TrackedPerson>[];
  for (final p in frame.people) {
    final old = before[p.id];
    final trail = <TrailPoint>[
      if (old != null) ...old.trail.where((e) => !e.t.isBefore(cutoff)),
      // 가려진(hidden) 사람은 마지막 위치에 그대로 두고 궤적을 늘리지 않는다
      if (!p.hidden || old == null) TrailPoint(t, p.x, p.y),
    ];
    people.add(TrackedPerson(
      person: p,
      trail: trail,
      firstX: old?.firstX ?? p.x,
      firstY: old?.firstY ?? p.y,
    ));
  }
  return LiveState(
      people: people, radar: frame.radar, pi: frame.pi, frameT: frame.t, frameCount: prev.frameCount + 1);
}

final liveProvider = NotifierProvider<LiveNotifier, LiveState>(LiveNotifier.new);

/// `/ws/live` 의 frame 을 받아 사람별 최근 궤적과 진행 중 판정을 유지한다.
class LiveNotifier extends Notifier<LiveState> {
  @override
  LiveState build() {
    final sub = ref.read(connectionProvider.notifier).messages.listen((m) {
      if (m is LiveFrameMessage) state = applyFrame(state, m.frame);
    });
    ref.onDispose(sub.cancel);

    // 끊기면 사람은 지운다(오래된 위치를 실시간처럼 보이지 않게). 마지막 frameT 는 since= 용으로 남긴다.
    ref.listen(connectionProvider.select((c) => c.status), (prev, next) {
      if (next != LinkStatus.connected) {
        state = LiveState(radar: null, frameT: state.frameT);
      }
    });
    return const LiveState();
  }
}

// ---------------------------------------------------------------- 기기 상태 (/api/status)

/// 레이더·카메라 칩과 기기 상태 화면. 연결될 때와 [refreshEvery] 마다 다시 읽는다.
final deviceStatusProvider = NotifierProvider<DeviceStatusNotifier, DeviceStatus?>(DeviceStatusNotifier.new);

class DeviceStatusNotifier extends Notifier<DeviceStatus?> {
  static const refreshEvery = Duration(seconds: 30);

  @override
  DeviceStatus? build() {
    final api = ref.watch(piApiProvider);
    if (api == null) return null;

    final timer = Timer.periodic(refreshEvery, (_) {
      if (ref.read(connectionProvider).status == LinkStatus.connected) refresh();
    });
    ref.onDispose(timer.cancel);
    ref.listen(connectionProvider.select((c) => c.status), (prev, next) {
      if (next == LinkStatus.connected && prev != LinkStatus.connected) refresh();
    });
    if (ref.read(connectionProvider).status == LinkStatus.connected) scheduleMicrotask(refresh);
    return null;
  }

  Future<void> refresh() async {
    final api = ref.read(piApiProvider);
    if (api == null) return;
    try {
      final s = await api.status();
      if (ref.mounted && identical(ref.read(piApiProvider), api)) state = s;
    } catch (_) {
      // 못 읽으면 이전 값 유지 (연결 상태 칩이 따로 보인다)
    }
  }
}

// ---------------------------------------------------------------- 화면 문구

/// 파이가 클라우드에 안 붙어 있을 때 (SPEC 9.1 `pi: "offline"`)
const piOfflineLabel = '기기 꺼짐';
const piOfflineHint = '기기가 꺼져 있거나 인터넷에 연결되지 않았어요';

String radarLabel(String? radar) => switch (radar) {
      'ok' => '레이더 연결',
      'connecting' => '레이더 연결 중',
      'stale' => '레이더 응답 없음',
      'disconnected' => '레이더 끊김',
      null => '레이더 확인 중',
      _ => '레이더 확인 필요',
    };

/// `/api/status` 의 `camera`: ok · error(마지막 촬영 실패) · none(카메라 없음)
String cameraLabel(String camera) => switch (camera) {
      'ok' => '카메라 정상',
      'error' => '카메라 오류',
      'none' => '카메라 없음',
      _ => '카메라 확인 필요',
    };

/// 6.5 → "6.5초", 72 → "1분 12초"
String formatSeconds(double s) {
  if (s < 10) return '${(s * 10).round() / 10}초'.replaceFirst('.0초', '초');
  final total = s.round();
  if (total < 60) return '$total초';
  final m = total ~/ 60;
  final r = total % 60;
  return r == 0 ? '$m분' : '$m분 $r초';
}

/// 지도 위 사람 옆 라벨: "방문 82%", 이상이면 "장시간 체류 · 36초"
String personLabel(LivePerson p) {
  if (p.situation == Situations.deciding) return Situations.deciding;
  if (p.abnormal) {
    final s = p.situation == '장시간 체류' ? p.stillS : p.elapsedS;
    return '${p.situation} · ${formatSeconds(s)}';
  }
  return '${p.situation} ${(p.prob * 100).round()}%';
}
