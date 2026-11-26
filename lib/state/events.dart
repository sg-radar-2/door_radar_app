import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../app/constants.dart';
import '../data/api/live_socket.dart';
import '../data/local_store.dart';
import '../data/photo_sync.dart';
import '../data/models/models.dart';
import '../data/notifications.dart';
import 'connection.dart';
import 'live.dart';
import 'settings.dart';

// ---------------------------------------------------------------- 최근 기록 (홈)

/// 홈의 최근 기록 2개. 연결될 때 `/api/events?limit=2`, 그 뒤로는 WebSocket 이벤트로 갱신.
/// 아직 못 읽었으면 null.
final recentEventsProvider = NotifierProvider<RecentEventsNotifier, List<Event>?>(RecentEventsNotifier.new);

const recentCount = 2;

/// 목록에 이벤트를 넣거나(같은 id 는 덮어쓰기, SPEC 8장) 최신순으로 [limit] 개만 남긴다.
List<Event> upsertEvent(List<Event> list, Event e, {int? limit}) {
  final next = [for (final x in list) if (x.id != e.id) x, e];
  next.sort((a, b) => b.time.compareTo(a.time));
  return limit == null || next.length <= limit ? next : next.sublist(0, limit);
}

class RecentEventsNotifier extends Notifier<List<Event>?> {
  @override
  List<Event>? build() {
    final api = ref.watch(piApiProvider);
    if (api == null) return null;

    final sub = ref.read(connectionProvider.notifier).messages.listen((m) {
      if (m is LiveEventMessage) state = upsertEvent(state ?? const [], m.event, limit: recentCount);
    });
    ref.onDispose(sub.cancel);

    // WebSocket 연결 성공 시 기존처럼 최근 기록 갱신
    ref.listen(connectionProvider.select((c) => c.status), (prev, next) {
      if (next == LinkStatus.connected && prev != LinkStatus.connected) {
        refresh();
      }
    });

    // 페어링 Token이 생기면 WebSocket 없이도 조회
    ref.listen(connectionProvider.select((c) => c.token), (prev, next) {
      if (next != null && next != prev) {
        refresh();
      }
    });

    // 앱 재시작 시 저장된 페어링 Token으로 조회
    scheduleMicrotask(() {
      if (ref.mounted && ref.read(connectionProvider).isPaired) {
        refresh();
      }
    });

    // 파이에 붙기 전·오프라인이면 폰 저장본으로 먼저 채운다
    scheduleMicrotask(() async {
      try {
        final local = await ref.read(localStoreProvider).latest(recentCount);
        if (ref.mounted && state == null) state = [for (final s in local) s.event];
      } catch (_) {}
    });
    return null;
  }

  Future<void> refresh() async {
    final api = ref.read(piApiProvider);
    if (api == null) return;
    try {
      final list = await api.events(limit: recentCount);
      if (ref.mounted && identical(ref.read(piApiProvider), api)) state = list;
    } catch (_) {
      // 다음 연결 때 다시
    }
  }
}

// ---------------------------------------------------------------- 이상 상황 배너 + 알림

/// 지금 홈에 띄운 이상 상황 (camera 이벤트). 없으면 null.
final homeAlertProvider = NotifierProvider<HomeAlertNotifier, Event?>(HomeAlertNotifier.new);

/// 알릴 이벤트인지: `notify` 목록에 있는 이상 상황의 camera 이벤트 (SPEC 7장, 1회만 나와도 알림)
bool shouldAlert(Event e, List<String> notify) =>
    e.kind == EventKind.camera && e.abnormal && notify.contains(e.situation);

class HomeAlertNotifier extends Notifier<Event?> {
  /// 배너 속 사람이 프레임에서 이만큼 안 보이면 배너를 접는다 (id 가 잠깐 끊기는 것 흘려보내기)
  static const goneAfter = Duration(seconds: 2);

  /// 다시 붙었을 때 빈 기간에 온 이벤트 중 이보다 오래된 건 알리지 않는다
  static const backfillMaxAge = Duration(minutes: 5);

  final _alerted = <int>{};
  DateTime? _goneSince;
  String? _lastFrameT;

  @override
  Event? build() {
    final conn = ref.read(connectionProvider.notifier);
    final subs = [
      conn.messages.listen((m) {
        if (m is LiveEventMessage) _consider(m.event);
      }),
      conn.reconnected.listen((_) => _backfill()),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        s.cancel();
      }
    });

    ref.listen(liveProvider, (_, live) => _onLive(live));
    // 연결 해제(토큰 삭제)되면 배너도 접는다
    ref.listen(connectionProvider.select((c) => c.isPaired), (_, paired) {
      if (!paired) state = null;
    });
    return null;
  }

  /// "확인"
  void dismiss() {
    _goneSince = null;
    state = null;
  }

  void _consider(Event e) {
    if (!shouldAlert(e, ref.read(notifySituationsProvider))) return;
    if (!_alerted.add(e.id)) return;
    _goneSince = null;
    state = e;
    ref.read(alertNotificationsProvider).show(e);
  }

  void _onLive(LiveState live) {
    if (live.frameT != null) _lastFrameT = live.frameT;
    final alert = state;
    if (alert == null || !live.hasFrame || ref.read(connectionProvider).status != LinkStatus.connected) return;
    if (live.find(alert.person) != null) {
      _goneSince = null;
      return;
    }
    final now = DateTime.tryParse(live.frameT!) ?? DateTime.now();
    _goneSince ??= now;
    if (now.difference(_goneSince!) >= goneAfter) dismiss();
  }

  /// 끊긴 동안 온 camera 이벤트를 `/api/events?since=` 로 확인
  Future<void> _backfill() async {
    final since = _lastFrameT;
    final api = ref.read(piApiProvider);
    if (since == null || api == null) return;
    try {
      final missed = await api.events(since: since, abnormal: true);
      if (!ref.mounted) return;
      final now = DateTime.now();
      // 최신순으로 오므로 가장 최근 것 하나만 배너로
      for (final e in missed) {
        if (now.difference(e.time) > backfillMaxAge) continue;
        if (shouldAlert(e, ref.read(notifySituationsProvider))) {
          _consider(e);
          break;
        }
      }
    } catch (_) {
      // 기록 화면(3차)에서 다시 채운다
    }
  }
}

// ---------------------------------------------------------------- 폰 저장소 · 동기화 (SPEC 6장)

/// main() 에서 연 저장소로 override 한다.
final localStoreProvider = Provider<LocalStore>((ref) => throw UnimplementedError('main 에서 override'));

/// 앱 시작 때 읽어 둔 휴대폰 보관 기간 (main 에서 override)
final initialKeepDaysProvider = Provider<int>((ref) => PhotoKeep.defaultDays);

/// 휴대폰 사진 보관 기간(일, 7~730). 앱에만 저장한다. 바꾸면 바로 정리한다.
final phoneKeepDaysProvider = NotifierProvider<PhoneKeepDaysNotifier, int>(PhoneKeepDaysNotifier.new);

class PhoneKeepDaysNotifier extends Notifier<int> {
  @override
  int build() => PhotoKeep.clamp(ref.read(initialKeepDaysProvider));

  Future<void> set(int days) async {
    state = PhotoKeep.clamp(days);
    await ref.read(appStorageProvider).saveKeepDays(state);
    await ref.read(eventSyncProvider.notifier).purge();
  }
}

/// 이벤트·사진을 폰 저장소로 모은다. 상태는 저장소가 바뀔 때마다 오르는 번호
/// (기록·상세 화면이 이걸 보고 다시 읽는다).
///
/// - 시작할 때: 보관 기간 지난 것 정리
/// - 연결될 때(처음·재연결): 마지막 이벤트 이후를 `/api/events?since=` 로 채우고 사진 동기화
/// - WebSocket 이벤트: 저장소에 넣고, 사진이 있으면 사진 동기화
final eventSyncProvider = NotifierProvider<EventSyncNotifier, int>(EventSyncNotifier.new);

class EventSyncNotifier extends Notifier<int> {
  PhotoSync? _photos;
  Future<void>? _catchingUp;

  /// 마지막 사진 동기화 결과 (기기 상태 화면·디버그용)
  PhotoSyncResult? lastPhotoSync;

  LocalStore get _store => ref.read(localStoreProvider);

  @override
  int build() {
    final api = ref.watch(piApiProvider);
    _photos = api == null ? null : PhotoSync(api, ref.read(localStoreProvider));
    _catchingUp = null;

    final sub = ref.read(connectionProvider.notifier).messages.listen((m) {
      if (m is LiveEventMessage) _onEvent(m.event);
    });
    ref.onDispose(sub.cancel);

    // WebSocket 재연결 시 기존처럼 누락된 기록 동기화
    ref.listen(connectionProvider.select((c) => c.status), (prev, next) {
      if (next == LinkStatus.connected && prev != LinkStatus.connected) {
        catchUp();
      }
    });

    // Cloud 페어링 성공 즉시 기록 동기화
    ref.listen(connectionProvider.select((c) => c.token), (prev, next) {
      if (next != null && next != prev) {
        catchUp();
      }
    });

    // 앱을 다시 실행한 경우에도 동기화
    scheduleMicrotask(() {
      if (!ref.mounted) return;

      purge();

      if (ref.read(connectionProvider).isPaired) {
        catchUp();
      }
    });

    return 0;
  }

  void _bump() {
    if (ref.mounted) state++;
  }

  Future<void> _onEvent(Event e) async {
    try {
      await _store.upsert(e);
      _bump();
    } catch (_) {}
    // 최종 판정은 상세(track·behaviors)까지 바로 받아 둔다 — 나중에 오프라인으로 열어도 보이게
    if (e.kind == EventKind.finalResult && !e.hasDetail) {
      try {
        final api = ref.read(piApiProvider);
        if (api != null) {
          await _store.upsert(await api.event(e.id));
          _bump();
        }
      } catch (_) {
        // 상세 화면을 열 때 다시 받는다
      }
    }
    if (e.photo || e.kind == EventKind.camera) await syncPhotos();
  }

  /// 보관 기간이 지난 이벤트·사진 지우기
  Future<void> purge() async {
    try {
      final n = await _store.purge(keepDays: ref.read(phoneKeepDaysProvider));
      if (n > 0) _bump();
    } catch (_) {}
  }

  /// 놓친 이벤트 채우기 + 사진 동기화. 겹쳐 부르면 하나로.
  Future<void> catchUp() => _catchingUp ??= _catchUp().whenComplete(() => _catchingUp = null);


  Future<void> _catchUp() async {
    final api = ref.read(piApiProvider);
    if (api == null) return;

    try {
      final since = await _store.latestT();

      final list = await api.events(
        since: since,
        limit: PiServer.maxEventsLimit,
      );

      await _store.upsertAll(list);
      _bump();

      debugPrint('Cloud Event 동기화 성공: ${list.length}건');
    } catch (e) {
      debugPrint('Cloud Event 동기화 실패: $e');
    }

    // 사진 API가 아직 없어도 Event 기록은 정상 처리
    try {
      await syncPhotos();
    } catch (e) {
      debugPrint('사진 동기화 보류: $e');
    }
  }


  Future<PhotoSyncResult?> syncPhotos() async {
    final sync = _photos;
    if (sync == null) return null;
    final r = await sync.run();
    lastPhotoSync = r;
    if (r.saved > 0 || r.acked > 0) _bump();
    return r;
  }

  /// 당겨서 새로고침: 그 날 0시 이후를 파이에서 다시 받는다. 실패하면 예외 (화면에서 안내).
  Future<void> refreshDay(DateTime day) async {
    final api = ref.read(piApiProvider);
    if (api == null) throw StateError('not paired');
    final start = DateTime(day.year, day.month, day.day);
    final list = await api.events(since: isoLocal(start.subtract(const Duration(milliseconds: 1))), limit: PiServer.maxEventsLimit);
    await _store.upsertAll(list);
    _bump();
    await syncPhotos();
  }

  /// 정답 표시 (null 이면 지우기). 파이가 돌려준 이벤트로 폰 저장소도 고친다.
  Future<Event> label(int id, String? situation) async {
    final api = ref.read(piApiProvider);
    if (api == null) throw StateError('not paired');
    final e = await api.label(id, situation);
    await _store.upsert(e);
    _bump();
    return e;
  }
}

/// 폰 시간대 시각을 오프셋이 붙은 ISO 문자열로 ("2026-11-19T00:00:00.000+09:00"). `since=` 용.
String isoLocal(DateTime t) {
  final local = t.toLocal();
  final off = local.timeZoneOffset;
  final sign = off.isNegative ? '-' : '+';
  final h = off.inHours.abs().toString().padLeft(2, '0');
  final m = (off.inMinutes.abs() % 60).toString().padLeft(2, '0');
  return '${DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(local)}$sign$h:$m';
}

// ---------------------------------------------------------------- 기록 화면

/// 그 날 폰 저장소의 이벤트 (최신순). 저장소가 바뀌면 다시 읽는다.
final dayEventsProvider = FutureProvider.autoDispose.family<List<StoredEvent>, DateTime>((ref, day) {
  ref.watch(eventSyncProvider);
  return ref.read(localStoreProvider).day(day);
});

/// 이벤트가 있는 날짜들 (날짜 고르기)
final eventDaysProvider = FutureProvider.autoDispose<List<DayCount>>((ref) {
  ref.watch(eventSyncProvider);
  return ref.read(localStoreProvider).days();
});

/// 기록 목록에 보일 것: 같은 사람의 최종 판정이 나왔으면 촬영(camera) 이벤트는 숨긴다
/// (사진은 최종 판정 쪽에서 보여 준다). 아직 진행 중인 사람의 촬영 이벤트는 남긴다.
List<StoredEvent> historyRows(List<StoredEvent> events) {
  final finals = {for (final s in events) if (s.event.kind == EventKind.finalResult) s.event.startedAt};
  return [
    for (final s in events)
      if (s.event.kind != EventKind.camera || !finals.contains(s.event.startedAt)) s,
  ];
}

class DaySummary {
  const DaySummary({required this.total, required this.abnormal, required this.photos});
  final int total;
  final int abnormal;
  final int photos;
}

/// 검은 요약 카드 (전체 / 이상 / 촬영) — [historyRows] 기준
DaySummary summarize(List<StoredEvent> rows) => DaySummary(
      total: rows.length,
      abnormal: rows.where((s) => s.event.abnormal).length,
      photos: rows.where((s) => s.event.photo).length,
    );

// ---------------------------------------------------------------- 이벤트 상세

/// 이벤트 상세: 폰 저장소 것을 먼저 보여 주고, 파이에 연결돼 있으면 상세(track·behaviors)를 받아 갱신.
final eventDetailProvider =
    AsyncNotifierProvider.autoDispose.family<EventDetailNotifier, StoredEvent?, int>(EventDetailNotifier.new);

class EventDetailNotifier extends AsyncNotifier<StoredEvent?> {
  EventDetailNotifier(this.id);

  final int id;

  LocalStore get _store => ref.read(localStoreProvider);

  @override
  Future<StoredEvent?> build() async {
    // 사진 동기화 등으로 저장소가 바뀌면 폰 저장본만 다시 읽는다
    ref.listen(eventSyncProvider, (_, _) => _reloadLocal());
    final local = await _withPhoto(await _store.get(id));
    final api = ref.watch(piApiProvider);
    if (api == null) return local;
    try {
      final e = await api.event(id);
      await _store.upsert(e);
      return await _withPhoto(await _store.get(id));
    } catch (e) {
      if (local != null) return local; // 파이에 못 붙어도 폰 저장본은 보여 준다
      rethrow;
    }
  }

  /// 자기 사진이 없으면 같은 사람의 촬영 사진
  Future<StoredEvent?> _withPhoto(StoredEvent? s) async {
    if (s == null || s.photoPath != null) return s;
    final p = await _store.photoFor(s.event);
    return p == null ? s : StoredEvent(s.event, photoPath: p);
  }

  Future<void> _reloadLocal() async {
    final s = await _withPhoto(await _store.get(id));
    if (s != null && ref.mounted) state = AsyncData(s);
  }

  /// 정답 표시 / 지우기(null)
  Future<void> setLabel(String? situation) async {
    final e = await ref.read(eventSyncProvider.notifier).label(id, situation);
    final cur = state.value;
    if (ref.mounted) state = AsyncData(StoredEvent(cur == null ? e : mergeEvent(cur.event, e), photoPath: cur?.photoPath));
  }
}
