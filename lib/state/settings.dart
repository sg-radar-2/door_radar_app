import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/constants.dart';
import '../data/models/models.dart';
import 'connection.dart';

/// 파이 설정 (`/api/settings`). 연결될 때마다 다시 읽는다. 못 읽었으면 null.
/// 바꾸기(PUT)와 휴대폰 보관 기간은 4차(설정 화면)에서.
final piSettingsProvider = NotifierProvider<PiSettingsNotifier, PiSettings?>(PiSettingsNotifier.new);

/// 알림 받을 상황. 설정을 아직 못 읽었으면 파이 기본값(이상 3가지 전부).
final notifySituationsProvider = Provider<List<String>>(
  (ref) => ref.watch(piSettingsProvider.select((s) => s?.notify)) ?? Situations.abnormal,
);

class PiSettingsNotifier extends Notifier<PiSettings?> {
  @override
  PiSettings? build() {
    final api = ref.watch(piApiProvider);
    if (api == null) return null;
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
      final s = await api.settings();
      if (ref.mounted && identical(ref.read(piApiProvider), api)) state = s;
    } catch (_) {
      // 다음 연결 때 다시
    }
  }

  /// 설정 바꾸기 (`PUT /api/settings`, 바꾼 키만). 화면에는 바로 반영하고, 실패하면 되돌린 뒤 예외를 다시 던진다.
  Future<void> change({List<String>? notify, bool? cameraOn}) async {
    final api = ref.read(piApiProvider);
    final before = state;
    if (api == null || before == null) throw StateError('not connected');
    state = before.copyWith(notify: notify ?? before.notify, cameraOn: cameraOn ?? before.cameraOn);
    try {
      final saved = await api.updateSettings(notify: notify, cameraOn: cameraOn);
      if (ref.mounted) state = saved;
    } catch (_) {
      if (ref.mounted) state = before;
      rethrow;
    }
  }
}

/// notify 목록에서 하나 켜고 끄기. 순서는 이상 상황 순서(장시간 체류 · 배회 · 반복 접근)로 맞춘다.
List<String> toggleNotify(List<String> current, String situation, bool on) => [
      for (final s in Situations.abnormal)
        if (s == situation ? on : current.contains(s)) s,
    ];
