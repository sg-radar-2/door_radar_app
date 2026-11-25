import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models/models.dart';

/// 폰에 보관한 이벤트 (+ 사진 파일 경로)
class StoredEvent {
  const StoredEvent(this.event, {this.photoPath});

  final Event event;

  /// 폰에 저장한 사진 파일. 없으면 null (파이에서 받아 보여 준다).
  final String? photoPath;

  bool get hasLocalPhoto => photoPath != null;
}

/// 날짜별 이벤트 수 (날짜 고르기)
class DayCount {
  const DayCount(this.day, this.count);
  final DateTime day;
  final int count;
}

/// 폰 저장소 (SPEC 6장). 파이에 연결이 안 돼도 기록 화면은 여기서 보여 준다.
/// 앱은 [SqliteLocalStore], 위젯 테스트·DB 를 못 열었을 때는 [MemoryLocalStore].
abstract interface class LocalStore {
  /// 이벤트 넣기/덮어쓰기 (같은 id 는 덮어쓴다, SPEC 8장). 사진 경로는 남기고,
  /// 새 것에 상세(track·behaviors)가 없으면 예전 상세를 남긴다([mergeEvent]).
  Future<void> upsert(Event e);
  Future<void> upsertAll(Iterable<Event> events);

  /// 사진을 저장하고 이벤트와 묶는다. 저장이 끝나야 ack 한다(SPEC 6장).
  Future<StoredEvent> savePhoto(Event e, Uint8List jpeg);

  Future<StoredEvent?> get(int id);

  /// 그 날(폰 시간대 기준)의 이벤트, 최신순
  Future<List<StoredEvent>> day(DateTime day);

  /// 이벤트가 있는 날짜들, 최신순
  Future<List<DayCount>> days();

  /// 가장 최근 이벤트 [n]개 (홈 최근 기록, 오프라인일 때)
  Future<List<StoredEvent>> latest(int n);

  /// 가장 최근 이벤트의 `t` (파이 문자열 그대로) — 놓친 기간을 `/api/events?since=` 로 채울 때
  Future<String?> latestT();

  /// 자기 사진이 없으면 같은 사람(같은 `started_at`)의 촬영 사진
  Future<String?> photoFor(Event e);

  /// 휴대폰 보관 기간이 지난 이벤트와 사진 지우기. 지운 이벤트 수.
  Future<int> purge({required int keepDays, DateTime? now});

  Future<void> close();
}

/// sqflite + 앱 문서 폴더의 `photos/{id}.jpg`
class SqliteLocalStore implements LocalStore {
  SqliteLocalStore._(this._db, this.photoDir);

  final Database _db;
  final Directory photoDir;

  static const _table = 'events';

  /// [factory]·[dbPath]·[photoDir] 는 테스트용 (sqflite_common_ffi, 임시 폴더)
  static Future<SqliteLocalStore> open({DatabaseFactory? factory, String? dbPath, Directory? photoDir}) async {
    final f = factory ?? databaseFactory;
    final docs = photoDir == null || dbPath == null ? await getApplicationDocumentsDirectory() : null;
    final path = dbPath ?? '${docs!.path}${Platform.pathSeparator}door_radar.db';
    final photos = photoDir ?? Directory('${docs!.path}${Platform.pathSeparator}photos');
    await photos.create(recursive: true);
    final db = await f.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE $_table(
              id INTEGER PRIMARY KEY,
              t_ms INTEGER NOT NULL,
              day TEXT NOT NULL,
              started TEXT NOT NULL,
              kind TEXT NOT NULL,
              json TEXT NOT NULL,
              photo_path TEXT
            )''');
          await db.execute('CREATE INDEX events_day ON $_table(day)');
          await db.execute('CREATE INDEX events_t ON $_table(t_ms)');
          await db.execute('CREATE INDEX events_started ON $_table(started)');
        },
      ),
    );
    return SqliteLocalStore._(db, photos);
  }

  @override
  Future<void> close() => _db.close();

  /// 이벤트 넣기/덮어쓰기 (같은 id 는 덮어쓴다, SPEC 8장). 사진 경로는 남기고,
  /// 새 것에 상세(track·behaviors)가 없으면 예전 상세를 남긴다.
  @override
  Future<void> upsert(Event e) => upsertAll([e]);

  @override
  Future<void> upsertAll(Iterable<Event> events) async {
    if (events.isEmpty) return;
    await _db.transaction((tx) async {
      for (final e in events) {
        final old = await _read(tx, e.id);
        final merged = old == null ? e : mergeEvent(old.event, e);
        await tx.insert(_table, _row(merged, old?.photoPath), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// 사진을 파일로 쓰고 이벤트와 함께 저장. 저장이 끝나야 ack 한다(SPEC 6장).
  @override
  Future<StoredEvent> savePhoto(Event e, Uint8List jpeg) async {
    final file = File('${photoDir.path}${Platform.pathSeparator}${e.id}.jpg');
    final tmp = File('${file.path}.part');
    await tmp.writeAsBytes(jpeg, flush: true);
    await tmp.rename(file.path);
    late StoredEvent saved;
    await _db.transaction((tx) async {
      final old = await _read(tx, e.id);
      final merged = old == null ? e : mergeEvent(old.event, e);
      await tx.insert(_table, _row(merged, file.path), conflictAlgorithm: ConflictAlgorithm.replace);
      saved = StoredEvent(merged, photoPath: file.path);
    });
    return saved;
  }

  @override
  Future<StoredEvent?> get(int id) => _read(_db, id);

  /// 그 날(폰 시간대 기준)의 이벤트, 최신순
  @override
  Future<List<StoredEvent>> day(DateTime day) async {
    final rows = await _db.query(_table, where: 'day = ?', whereArgs: [dayKey(day)], orderBy: 't_ms DESC');
    return rows.map(_fromRow).toList();
  }

  /// 이벤트가 있는 날짜들, 최신순
  @override
  Future<List<StoredEvent>> latest(int n) async =>
      (await _db.query(_table, orderBy: 't_ms DESC', limit: n)).map(_fromRow).toList();

  @override
  Future<List<DayCount>> days() async {
    final rows = await _db.rawQuery('SELECT day, COUNT(*) AS n FROM $_table GROUP BY day ORDER BY day DESC');
    return [for (final r in rows) DayCount(DateTime.parse(r['day']! as String), r['n']! as int)];
  }

  /// 가장 최근 이벤트의 `t` (파이 문자열 그대로) — 놓친 기간을 `/api/events?since=` 로 채울 때
  @override
  Future<String?> latestT() async {
    final rows = await _db.query(_table, columns: ['json'], orderBy: 't_ms DESC', limit: 1);
    if (rows.isEmpty) return null;
    return (jsonDecode(rows.first['json']! as String) as Map<String, Object?>)['t'] as String?;
  }

  /// 같은 사람의 촬영 사진 (최종 판정 이벤트에 사진 파일이 따로 없을 때)
  @override
  Future<String?> photoFor(Event e) async {
    final own = await get(e.id);
    if (own?.photoPath != null) return own!.photoPath;
    final rows = await _db.query(_table,
        columns: ['photo_path'],
        where: 'started = ? AND photo_path IS NOT NULL AND id != ?',
        whereArgs: [e.startedAt, e.id],
        limit: 1);
    return rows.isEmpty ? null : rows.first['photo_path'] as String?;
  }

  /// 휴대폰 보관 기간이 지난 이벤트와 사진 지우기. 지운 이벤트 수.
  @override
  Future<int> purge({required int keepDays, DateTime? now}) async {
    final limit = (now ?? DateTime.now()).subtract(Duration(days: keepDays)).millisecondsSinceEpoch;
    final old = await _db.query(_table, columns: ['photo_path'], where: 't_ms < ?', whereArgs: [limit]);
    for (final r in old) {
      final p = r['photo_path'] as String?;
      if (p == null) continue;
      try {
        await File(p).delete();
      } on FileSystemException {
        // 이미 없으면 그만
      }
    }
    return _db.delete(_table, where: 't_ms < ?', whereArgs: [limit]);
  }

  Future<StoredEvent?> _read(DatabaseExecutor db, int id) async {
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  static Map<String, Object?> _row(Event e, String? photoPath) => {
        'id': e.id,
        't_ms': e.time.millisecondsSinceEpoch,
        'day': dayKey(e.time.toLocal()),
        'started': e.startedAt,
        'kind': e.kind == EventKind.camera ? 'camera' : 'final',
        'json': jsonEncode(e.toJson()),
        'photo_path': photoPath,
      };

  static StoredEvent _fromRow(Map<String, Object?> r) => StoredEvent(
        Event.fromJson(jsonDecode(r['json']! as String) as Map<String, Object?>),
        photoPath: r['photo_path'] as String?,
      );
}

/// 폰 시간대 날짜 키 "2026-11-19"
String dayKey(DateTime local) => DateFormat('yyyy-MM-dd').format(local);

/// 같은 id 를 다시 받았을 때: 새 값이 이기되, 새 것에 없는 상세는 예전 것을 남긴다.
Event mergeEvent(Event old, Event next) => next.copyWith(
      behaviors: next.behaviors ?? old.behaviors,
      track: next.track ?? old.track,
      reason: next.reason ?? old.reason,
      path: next.path ?? old.path,
      endSituation: next.endSituation ?? old.endSituation,
      endedAt: next.endedAt ?? old.endedAt,
    );

/// 메모리 저장소 (위젯 테스트, sqlite 를 못 열었을 때). 앱을 끄면 사라진다.
class MemoryLocalStore implements LocalStore {
  final _rows = <int, StoredEvent>{};

  /// 저장한 사진 바이트 (경로는 "memory://{id}" — 파일이 없어 화면에서는 파이 사진을 쓴다)
  final photos = <int, Uint8List>{};

  @override
  Future<void> upsert(Event e) => upsertAll([e]);

  @override
  Future<void> upsertAll(Iterable<Event> events) async {
    for (final e in events) {
      final old = _rows[e.id];
      _rows[e.id] = StoredEvent(old == null ? e : mergeEvent(old.event, e), photoPath: old?.photoPath);
    }
  }

  @override
  Future<StoredEvent> savePhoto(Event e, Uint8List jpeg) async {
    photos[e.id] = jpeg;
    final old = _rows[e.id];
    return _rows[e.id] = StoredEvent(old == null ? e : mergeEvent(old.event, e), photoPath: 'memory://${e.id}');
  }

  @override
  Future<StoredEvent?> get(int id) async => _rows[id];

  List<StoredEvent> get _sorted => _rows.values.toList()..sort((a, b) => b.event.time.compareTo(a.event.time));

  @override
  Future<List<StoredEvent>> day(DateTime day) async =>
      _sorted.where((s) => dayKey(s.event.time.toLocal()) == dayKey(day)).toList();

  @override
  Future<List<DayCount>> days() async {
    final counts = <String, int>{};
    for (final s in _sorted) {
      final k = dayKey(s.event.time.toLocal());
      counts[k] = (counts[k] ?? 0) + 1;
    }
    return [for (final e in counts.entries) DayCount(DateTime.parse(e.key), e.value)];
  }

  @override
  Future<List<StoredEvent>> latest(int n) async => _sorted.take(n).toList();

  @override
  Future<String?> latestT() async => _sorted.firstOrNull?.event.t;

  @override
  Future<String?> photoFor(Event e) async {
    final own = _rows[e.id]?.photoPath;
    if (own != null) return own;
    for (final s in _rows.values) {
      if (s.event.id != e.id && s.event.startedAt == e.startedAt && s.photoPath != null) return s.photoPath;
    }
    return null;
  }

  @override
  Future<int> purge({required int keepDays, DateTime? now}) async {
    final limit = (now ?? DateTime.now()).subtract(Duration(days: keepDays));
    final old = [for (final s in _rows.values) if (s.event.time.isBefore(limit)) s.event.id];
    for (final id in old) {
      _rows.remove(id);
      photos.remove(id);
    }
    return old.length;
  }

  @override
  Future<void> close() async {}
}