// 가짜 파이 서버(mock_server/server.py)에 실제로 붙어 보는 통합 테스트.
// 서버가 없으면 건너뛴다. 실행:
//   (mock_server) $env:MOCK_PAIR_CODE="482913"; python server.py
//   $env:DOOR_RADAR_MOCK="127.0.0.1:8080"; flutter test test/mock_server_test.dart
import 'dart:io';

import 'package:door_radar_app/data/api/live_socket.dart';
import 'package:door_radar_app/data/api/pi_api.dart';
import 'package:door_radar_app/data/models/models.dart';
import 'package:door_radar_app/data/storage.dart';
import 'package:door_radar_app/state/connection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final address = Platform.environment['DOOR_RADAR_MOCK'];
  final code = Platform.environment['DOOR_RADAR_CODE'] ?? '482913';
  final skip = address == null ? 'DOOR_RADAR_MOCK 이 없어 건너뜀' : null;
  final device = PiDevice.tryParse(address ?? '127.0.0.1');

  test('REST: info → pair → status / events / settings / pending / 401', () async {
    final api = PiApi(device: device!);
    final info = await api.info();
    expect(info.region.fovDeg, 135);

    await expectLater(api.pair('000000'), throwsA(isA<PiApiException>().having((e) => e.code, 'code', 'bad_code')));
    final token = await api.pair(code);
    expect(token, isNotEmpty);

    final status = await api.status();
    expect(status.radarOk, isTrue);

    final events = await api.events(limit: 50);
    expect(events, isNotEmpty);
    final detail = await api.event(events.firstWhere((e) => e.kind == EventKind.finalResult).id);
    expect(detail.hasDetail, isTrue);

    // since 의 +09:00 이 그대로 전달되는지 (공백으로 바뀌면 400)
    final since = await api.events(since: events.last.t);
    expect(since.length, lessThan(events.length));

    final settings = await api.settings();
    expect(settings.deviceKeepDays, 30);
    expect((await api.pendingPhotos()), isNotEmpty);

    await expectLater(
      PiApi(device: device, token: 'wrong').status(),
      throwsA(isA<PiApiException>().having((e) => e.isUnauthorized, '401', isTrue)),
    );
    api.close();
  }, skip: skip);

  test('연결 상태: 페어링 → 연결됨 → 실시간 프레임 받기', () async {
    final kv = MemoryKv();
    final container = ProviderContainer(overrides: [appStorageProvider.overrideWithValue(AppStorage(kv))]);
    addTearDown(container.dispose);
    container.listen(connectionProvider, (_, _) {});

    final notifier = container.read(connectionProvider.notifier);
    final frames = <LiveFrame>[];
    notifier.messages.whereType<LiveFrameMessage>().listen((m) => frames.add(m.frame));

    await notifier.pair(code);
    expect(kv.values['pi_token'], isNotNull);

    final end = DateTime.now().add(const Duration(seconds: 5));
    while (frames.length < 3 && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final conn = container.read(connectionProvider);
    expect(conn.status, LinkStatus.connected);
    expect(conn.info?.name, 'doorradar');
    expect(frames.length, greaterThanOrEqualTo(3)); // 초당 5번
  }, skip: skip);

  test('저장된 토큰이 서버에서 사라졌으면(서버 재시작) 연결 화면으로', () async {
    final kv = MemoryKv();
    final container = ProviderContainer(overrides: [
      appStorageProvider.overrideWithValue(AppStorage(kv)),
      savedSessionProvider.overrideWithValue(SavedSession(device: device, token: 'stale')),
    ]);
    addTearDown(container.dispose);
    container.listen(connectionProvider, (_, _) {});
    expect(container.read(connectionProvider).status, LinkStatus.connecting);

    final end = DateTime.now().add(const Duration(seconds: 5));
    while (container.read(connectionProvider).isPaired && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final conn = container.read(connectionProvider);
    expect(conn.isPaired, isFalse);
    expect(conn.message, contains('페어링 코드를 다시'));
    expect(conn.device, device); // 주소는 남는다
  }, skip: skip);
}

extension<T> on Stream<T> {
  Stream<S> whereType<S>() => where((m) => m is S).cast<S>();
}
