import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 앱이 꺼져 있을 때 이상 상황 알림 (FCM, SPEC 9.4).
/// 클라우드가 FCM 으로 보내고, 앱은 토큰을 클라우드에 등록하고 알림을 눌렀을 때 상세로 보낸다.
/// 앱이 화면에 있으면 WebSocket 으로 이미 알리므로 앞에 있을 때 온 푸시는 무시한다.
abstract class PushMessaging {
  /// FCM 토큰. 못 받으면 null (Firebase 설정이 없거나 Google Play 서비스가 없는 기기)
  Future<String?> token();

  /// 토큰이 바뀔 때 (앱 데이터 삭제, 재설치 등)
  Stream<String> get tokenRefresh;

  /// 푸시 알림을 눌러 앱이 열렸을 때 이벤트 id (앱이 꺼져 있다 열린 경우 포함)
  Stream<int> get taps;
}

/// 푸시를 못 쓸 때 (Firebase 초기화 실패, 테스트)
class NoPush implements PushMessaging {
  const NoPush();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<int> get taps => const Stream.empty();
}

/// FCM `data.event_id`(문자열) → 이벤트 id
int? eventIdOf(Map<String, dynamic> data) => int.tryParse('${data['event_id'] ?? ''}');

class FcmPush implements PushMessaging {
  FcmPush([FirebaseMessaging? messaging]) : _m = messaging ?? FirebaseMessaging.instance {
    // 앱이 백그라운드에 있을 때 알림을 눌러 열림
    _sub = FirebaseMessaging.onMessageOpenedApp.listen(_open);
    // 앱이 꺼져 있을 때 알림을 눌러 켜짐 (한 번만)
    _m.getInitialMessage().then((m) {
      if (m != null) _open(m);
    }).catchError((Object e) {
      debugPrint('FCM 첫 메시지 확인 실패: $e');
    });
  }

  final FirebaseMessaging _m;
  final _taps = StreamController<int>.broadcast();
  StreamSubscription<RemoteMessage>? _sub;

  /// getInitialMessage 가 첫 화면이 구독하기 전에 올 수 있어서 마지막 것을 기억해 둔다
  int? _pending;

  void _open(RemoteMessage m) {
    final id = eventIdOf(m.data);
    if (id == null) return;
    if (_taps.hasListener) {
      _taps.add(id);
    } else {
      _pending = id;
    }
  }

  // firebase_messaging 17 은 getToken/onTokenRefresh 를 deprecated 로 두고 register()/onRegistered(설치 ID, FID)를
  // 권한다. 하지만 Firebase 콘솔 "테스트 메시지"와 서버 firebase-admin 의 Message(token=...)는 기존 등록 토큰을 받으므로
  // 클라우드가 FID 직접 보내기로 바꾸기 전까지는 등록 토큰을 쓴다 (SPEC 9.4).

  @override
  Future<String?> token() async {
    try {
      // ignore: deprecated_member_use
      return await _m.getToken();
    } catch (e) {
      debugPrint('FCM 토큰을 받지 못함: $e');
      return null;
    }
  }

  @override
  // ignore: deprecated_member_use
  Stream<String> get tokenRefresh => _m.onTokenRefresh;

  @override
  Stream<int> get taps {
    final p = _pending;
    if (p != null) {
      _pending = null;
      scheduleMicrotask(() => _taps.add(p));
    }
    return _taps.stream;
  }

  void dispose() {
    _sub?.cancel();
    _taps.close();
  }
}

/// main() 에서 Firebase 초기화에 성공하면 [FcmPush] 로 override 한다.
final pushMessagingProvider = Provider<PushMessaging>((ref) => const NoPush());
