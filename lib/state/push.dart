import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/push.dart';
import 'connection.dart';
import 'package:flutter/foundation.dart';

/// 이 폰의 FCM 토큰 (기기 상태 화면에서 복사해 Firebase 콘솔 테스트 메시지에 쓴다)
final fcmTokenProvider = FutureProvider<String?>((ref) => ref.watch(pushMessagingProvider).token());

/// 클라우드에 연결될 때마다 FCM 토큰을 `PUT /api/push_token`으로 등록한다 (SPEC 9.1·9.4).
/// 토큰이 바뀌면 다시 등록. 상태는 마지막으로 등록에 성공한 FCM 토큰.
final pushRegistrationProvider = NotifierProvider<PushRegistration, String?>(PushRegistration.new);

class PushRegistration extends Notifier<String?> {
  /// 마지막으로 등록한 앱 토큰 (다시 페어링하면 새 앱 토큰으로 다시 등록)
  String? _registeredFor;

  @override
  String? build() {
    final push = ref.watch(pushMessagingProvider);
    final sub = push.tokenRefresh.listen((t) => register(fcm: t));
    ref.onDispose(sub.cancel);

    ref.listen(
      connectionProvider.select((c) => c.token),
      (prev, next) {
        if (next != null && next != prev) {
          register();
        }
      },
    );

    scheduleMicrotask(() {
      if (ref.mounted && ref.read(connectionProvider).isPaired) {
        register();
      }
    });

    return null;
  }

  Future<void> register({String? fcm}) async {
    final api = ref.read(piApiProvider);
    final appToken = ref.read(connectionProvider).token;
    if (api == null || appToken == null) return;
    final token = fcm ?? await ref.read(pushMessagingProvider).token();
    if (token == null || !ref.mounted) return;
    if (token == state && appToken == _registeredFor) return; // 이미 등록함
    try {
      await api.pushToken(token);
      if (!ref.mounted) return;
      _registeredFor = appToken;
      state = token;
    } catch (e) {
      debugPrint('FCM Cloud 등록 실패: $e');
    }
  }
}
