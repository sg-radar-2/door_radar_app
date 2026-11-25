import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:door_radar_app/data/local_store.dart';
import 'package:door_radar_app/data/models/models.dart';
import 'package:door_radar_app/data/photo_sync.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// 200 이상은 같은 사람(같은 started_at)의 final
Map<String, Object?> eventBody(int id) => {
      'id': id, 'kind': id >= 200 ? 'final' : 'camera', 'person': 'T1', 't': '2026-11-19T15:03:10+09:00',
      'started_at': '2026-11-19T15:02:17+09:00', 'situation': '장시간 체류', 'prob': 1.0, 'abnormal': true,
      'photo': true, 'label': null,
    };

void main() {
  late List<int> pending;
  late List<List<int>> acks;
  late Set<int> brokenPhotos;
  late List<int> photoFetched;
  late FakeAdapter adapter;
  late MemoryLocalStore store;
  late PhotoSync sync;

  setUp(() {
    pending = [128, 131, 140];
    acks = [];
    brokenPhotos = {};
    photoFetched = [];
    store = MemoryLocalStore();
    adapter = FakeAdapter((RequestOptions o) {
      final path = o.path;
      if (path == '/api/photos/pending') return (200, {'ids': pending});
      if (path == '/api/photos/ack') {
        final ids = [for (final i in (o.data as Map)['ids'] as List) i as int];
        acks.add(ids);
        pending = pending.where((p) => !ids.contains(p)).toList();
        return (200, {'acked': ids.length});
      }
      final m = RegExp(r'^/api/events/(\d+)(/photo)?$').firstMatch(path);
      if (m != null) {
        final id = int.parse(m[1]!);
        if (m[2] != null) photoFetched.add(id);
        if (m[2] != null) return brokenPhotos.contains(id) ? (500, {'error': 'x', 'message': ''}) : (200, 'JPEG$id');
        return (200, eventBody(id));
      }
      return (404, {'error': 'not_found', 'message': ''});
    });
    sync = PhotoSync(fakeApi(const PiDevice(host: 'pi'), 'tok', adapter), store);
  });

  test('pending → 메타·사진 받아 저장 → 저장한 것만 ack', () async {
    brokenPhotos = {131};
    final r = await sync.run();
    expect(r.saved, 2);
    expect(r.failed, 1);
    expect(acks, [
      [128, 140],
    ]);
    expect(pending, [131]); // 실패한 건 다음에 다시
    expect((await store.get(128))!.photoPath, isNotNull);
    expect(await store.get(131), isNull);

    brokenPhotos = {};
    final r2 = await sync.run();
    expect(r2.saved, 1);
    expect(pending, isEmpty);
  });

  test('final 은 같은 사람의 camera 사진이 폰에 있으면 다시 받지 않고 ack 만', () async {
    pending = [128, 200];
    final r = await sync.run();
    expect(photoFetched, [128]);
    expect(r.saved, 1);
    expect(r.shared, 1);
    expect(acks, [
      [128, 200],
    ]);
    final fin = (await store.get(200))!;
    expect(fin.photoPath, isNull);
    expect(await store.photoFor(fin.event), (await store.get(128))!.photoPath);
  });

  test('camera 사진을 못 받았으면 final 사진은 따로 받는다', () async {
    pending = [128, 200];
    brokenPhotos = {128};
    final r = await sync.run();
    expect(photoFetched, [128, 200]);
    expect(r.saved, 1);
    expect(acks, [
      [200],
    ]);
  });

  test('이미 폰에 있는 사진(지난번 ack 실패)은 다시 받지 않고 ack 만', () async {
    await store.savePhoto(Event.fromJson(eventBody(128)), Uint8List(1));
    final r = await sync.run();
    expect(r.saved, 2);
    expect(acks.single, [128, 131, 140]);
    expect(adapter.requests.where((o) => o.path == '/api/events/128/photo'), isEmpty);
  });

  test('동시에 두 번 돌지 않는다 (돌던 것이 끝난 뒤 한 번 더)', () async {
    final a = sync.run();
    final b = sync.run();
    expect(identical(a, b), isTrue);
    expect(sync.isRunning, isTrue);
    await a;
    expect(sync.isRunning, isFalse);
    // pending 조회: 첫 바퀴 + 다시 돌기 한 번
    expect(adapter.requests.where((o) => o.path == '/api/photos/pending').length, 2);
    expect(acks, hasLength(1));
  });

  test('pending 을 못 받으면 error 만 담고 끝', () async {
    adapter = FakeAdapter((_) => (503, {'error': 'radar', 'message': ''}));
    sync = PhotoSync(fakeApi(const PiDevice(host: 'pi'), 'tok', adapter), store);
    final r = await sync.run();
    expect(r.error, isNotNull);
    expect(r.saved, 0);
  });
}
