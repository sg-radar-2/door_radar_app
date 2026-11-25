import 'dart:async';

import 'api/pi_api.dart';
import 'local_store.dart';
import 'models/models.dart';

class PhotoSyncResult {
  const PhotoSyncResult({this.saved = 0, this.shared = 0, this.failed = 0, this.acked = 0, this.error});

  /// 새로 받아 저장한 사진
  final int saved;

  /// 같은 사람의 camera 사진이 이미 폰에 있어서 받지 않은 final (메타만 저장)
  final int shared;

  /// 받다가 실패한 사진 (다음 동기화 때 다시)
  final int failed;

  /// 파이에 받았다고 알린 수
  final int acked;

  /// pending 목록부터 못 받았을 때
  final Object? error;

  PhotoSyncResult operator +(PhotoSyncResult o) => PhotoSyncResult(
      saved: saved + o.saved, shared: shared + o.shared, failed: failed + o.failed, acked: acked + o.acked, error: o.error ?? error);

  @override
  String toString() => 'PhotoSyncResult(saved: $saved, shared: $shared, failed: $failed, acked: $acked, error: $error)';
}

/// 파이에서 아직 안 받은 사진을 폰으로 옮긴다 (SPEC 6장).
///
/// 1. `GET /api/photos/pending` → id 목록
/// 2. 각 id 를 `/api/events/{id}`(메타) + `/photo`(원본)로 받아 [LocalStore] 에 저장
/// 3. 저장이 끝난 id 만 `POST /api/photos/ack`
///
/// 앱 시작 · WebSocket 재연결 · 새 camera 이벤트 때 부른다. 돌고 있는 중에 또 부르면
/// 새로 시작하지 않고, 지금 것이 끝난 뒤 한 번 더 돈다(그 사이 생긴 사진까지 받도록).
class PhotoSync {
  PhotoSync(this.api, this.store);

  final PiApi api;
  final LocalStore store;

  Future<PhotoSyncResult>? _running;
  bool _again = false;

  bool get isRunning => _running != null;

  Future<PhotoSyncResult> run() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    final f = _loop().whenComplete(() => _running = null);
    _running = f;
    return f;
  }

  Future<PhotoSyncResult> _loop() async {
    var total = const PhotoSyncResult();
    do {
      _again = false;
      total = total + await _once();
    } while (_again);
    return total;
  }

  Future<PhotoSyncResult> _once() async {
    final List<int> ids;
    try {
      ids = await api.pendingPhotos();
    } catch (e) {
      return PhotoSyncResult(error: e);
    }
    final done = <int>[];
    var saved = 0;
    var shared = 0;
    var failed = 0;
    for (final id in ids) {
      try {
        final have = await store.get(id);
        if (have?.photoPath == null) {
          final event = await api.event(id);
          if (event.kind == EventKind.finalResult && await store.photoFor(event) != null) {
            // final 은 같은 사람의 첫 camera 사진을 가리킨다. 그 사진이 이미 폰에 있으면 다시 받지 않는다
            // (상세·기록 화면은 photoFor 로 그 사진을 보여 준다).
            await store.upsert(event);
            shared++;
          } else {
            final jpeg = await api.photo(id);
            await store.savePhoto(event, jpeg);
            saved++;
          }
        }
        // 이미 폰에 있으면(지난번 ack 실패) 받지 않고 ack 만
        done.add(id);
      } catch (_) {
        failed++;
      }
    }
    var acked = 0;
    if (done.isNotEmpty) {
      try {
        await api.ackPhotos(done);
        acked = done.length;
      } catch (_) {
        // 다음 동기화 때 다시 pending 으로 오고, 폰에 있으니 ack 만 다시 한다
      }
    }
    return PhotoSyncResult(saved: saved, shared: shared, failed: failed, acked: acked);
  }
}
