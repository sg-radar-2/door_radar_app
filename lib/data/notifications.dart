import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'models/models.dart';

/// 이상 상황 알림 (소리·진동). 테스트에서는 가짜로 바꾼다.
abstract class AlertNotifications {
  /// Android 13+ 알림 권한 요청. 이미 허용·거절했으면 시스템이 다시 묻지 않는다.
  Future<void> requestPermission();

  Future<void> show(Event event);

  Future<void> cancel(int eventId);

  /// 알림을 눌렀을 때 이벤트 id
  Stream<int> get taps;
}

final alertNotificationsProvider = Provider<AlertNotifications>((ref) {
  final n = LocalAlertNotifications();
  ref.onDispose(n.dispose);
  return n;
});

class LocalAlertNotifications implements AlertNotifications {
  LocalAlertNotifications([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'abnormal';

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<int>.broadcast();
  Future<bool>? _ready;

  @override
  Stream<int> get taps => _taps.stream;

  Future<bool> _init() => _ready ??= () async {
        try {
          await _plugin.initialize(
            settings: const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestBadgePermission: false,
                requestSoundPermission: false,
              ),
            ),
            onDidReceiveNotificationResponse: (r) {
              final id = int.tryParse(r.payload ?? '');
              if (id != null && !_taps.isClosed) _taps.add(id);
            },
          );
          return true;
        } catch (e) {
          debugPrint('알림 초기화 실패: $e');
          return false;
        }
      }();

  @override
  Future<void> requestPermission() async {
    if (!await _init()) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true);
    } catch (e) {
      debugPrint('알림 권한 요청 실패: $e');
    }
  }

  @override
  Future<void> show(Event event) async {
    if (!await _init()) return;
    final time = DateFormat('HH:mm:ss').format(event.time.toLocal());
    try {
      await _plugin.show(
        id: event.id,
        title: '${event.situation} 감지',
        body: event.photo ? '현관 · $time 촬영됨' : '현관 · $time',
        payload: '${event.id}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            '이상 상황',
            channelDescription: '장시간 체류 · 배회 · 반복 접근이 감지되면 알려요',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
      );
    } catch (e) {
      debugPrint('알림 표시 실패: $e');
    }
  }

  @override
  Future<void> cancel(int eventId) async {
    if (!await _init()) return;
    try {
      await _plugin.cancel(id: eventId);
    } catch (_) {}
  }

  void dispose() => _taps.close();
}
