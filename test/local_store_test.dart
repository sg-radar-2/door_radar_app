import 'dart:io';
import 'dart:typed_data';

import 'package:door_radar_app/data/local_store.dart';
import 'package:door_radar_app/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Event ev(int id, DateTime t,
        {String kind = 'final', String? started, bool photo = false, List<List<double>>? track, String? label}) =>
    Event.fromJson({
      'id': id, 'kind': kind, 'person': 'T1', 't': t.toIso8601String(),
      'started_at': started ?? t.toIso8601String(), 'situation': '방문', 'prob': 0.9, 'abnormal': false,
      'photo': photo, 'track': track, 'label': label,
    });

void main() {
  sqfliteFfiInit();

  // 같은 동작을 sqlite 와 메모리 저장소 모두에서 확인한다
  for (final kind in ['sqlite', 'memory']) {
    group(kind, () {
      late LocalStore store;
      late Directory dir;

      setUp(() async {
        dir = await Directory.systemTemp.createTemp('door_radar_test');
        store = kind == 'sqlite'
            ? await SqliteLocalStore.open(
                factory: databaseFactoryFfi, dbPath: inMemoryDatabasePath, photoDir: Directory('${dir.path}/photos'))
            : MemoryLocalStore();
      });
      tearDown(() async {
        await store.close();
        await dir.delete(recursive: true);
      });

      final day1 = DateTime(2026, 11, 19, 15, 3);
      final day0 = DateTime(2026, 11, 18, 9, 0);

      test('날짜별로 최신순, 날짜 목록·마지막 t', () async {
        await store.upsertAll([ev(1, day1.subtract(const Duration(hours: 2))), ev(2, day1), ev(3, day0)]);
        expect((await store.day(DateTime(2026, 11, 19))).map((s) => s.event.id), [2, 1]);
        expect((await store.day(DateTime(2026, 11, 18))).map((s) => s.event.id), [3]);
        final days = await store.days();
        expect(days.map((d) => (d.day, d.count)), [(DateTime(2026, 11, 19), 2), (DateTime(2026, 11, 18), 1)]);
        expect(await store.latestT(), day1.toIso8601String());
        expect((await store.latest(2)).map((s) => s.event.id), [2, 1]);
      });

      test('같은 id 는 덮어쓰되 상세(track)·사진 경로는 남긴다', () async {
        await store.upsert(ev(1, day1, track: [[0, 1, 2], [0.2, 1, 1.8]]));
        await store.savePhoto(ev(1, day1, photo: true), Uint8List.fromList([1, 2, 3]));
        await store.upsert(ev(1, day1, photo: true, label: '배달')); // WebSocket 으로 다시 온 요약
        final s = (await store.get(1))!;
        expect(s.event.label, '배달');
        expect(s.event.track, hasLength(2));
        expect(s.photoPath, isNotNull);
        if (kind == 'sqlite') expect(File(s.photoPath!).readAsBytesSync(), [1, 2, 3]);
      });

      test('최종 판정에 사진이 없으면 같은 사람의 촬영 사진', () async {
        final start = day1.subtract(const Duration(minutes: 1)).toIso8601String();
        await store.savePhoto(ev(10, day1, kind: 'camera', started: start, photo: true), Uint8List(4));
        await store.upsert(ev(11, day1.add(const Duration(seconds: 30)), started: start));
        expect(await store.photoFor((await store.get(11))!.event), (await store.get(10))!.photoPath);
        expect(await store.photoFor(ev(12, day1)), isNull);
      });

      test('보관 기간이 지난 이벤트와 사진 파일을 지운다', () async {
        final now = DateTime(2026, 11, 25);
        await store.savePhoto(ev(1, now.subtract(const Duration(days: 301)), photo: true), Uint8List(4));
        await store.upsert(ev(2, now.subtract(const Duration(days: 299))));
        final oldPath = (await store.get(1))!.photoPath!;

        expect(await store.purge(keepDays: 300, now: now), 1);
        expect(await store.get(1), isNull);
        expect(await store.get(2), isNotNull);
        if (kind == 'sqlite') expect(File(oldPath).existsSync(), isFalse);
      });
    });
  }

  test('mergeEvent: 새 값이 이기고, 없는 상세만 예전 것', () {
    final old = ev(1, DateTime(2026), track: [[0, 0, 1]]).copyWith(reason: '근거', path: '경로');
    final next = ev(1, DateTime(2026), label: '통과');
    final m = mergeEvent(old, next);
    expect(m.label, '통과');
    expect(m.track, [[0, 0, 1]]);
    expect(m.reason, '근거');
  });
}
