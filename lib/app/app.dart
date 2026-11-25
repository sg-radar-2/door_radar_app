import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/notifications.dart';
import '../data/push.dart';
import '../state/connection.dart';
import '../state/events.dart';
import '../state/push.dart';
import 'router.dart';
import 'theme.dart';

class DoorRadarApp extends ConsumerStatefulWidget {
  const DoorRadarApp({super.key});

  @override
  ConsumerState<DoorRadarApp> createState() => _DoorRadarAppState();
}

class _DoorRadarAppState extends ConsumerState<DoorRadarApp> {
  StreamSubscription<int>? _taps;
  StreamSubscription<int>? _pushTaps;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    void open(int id) => ref.read(routerProvider).go('/events/$id');
    // 이상 상황 알림(앱이 켜져 있을 때)이나 푸시(앱이 꺼져 있을 때, SPEC 9.4)를 누르면 그 이벤트 상세로
    _taps = ref.read(alertNotificationsProvider).taps.listen(open);
    _pushTaps = ref.read(pushMessagingProvider).taps.listen(open);
    // 화면에서 사라지면 실시간 연결을 끊고(배터리), 다시 보이면 붙어서 빈 기간을 채운다.
    // 그동안의 알림은 클라우드가 FCM 푸시로 보낸다.
    _lifecycle = AppLifecycleListener(
      onHide: () => ref.read(connectionProvider.notifier).pauseLive(),
      onShow: () => ref.read(connectionProvider.notifier).resumeLive(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _taps?.cancel();
    _pushTaps?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 이벤트·사진 폰 보관, FCM 토큰 등록은 어느 화면에 있든 돈다
    ref.listen(eventSyncProvider, (_, _) {});
    ref.listen(pushRegistrationProvider, (_, _) {});
    return MaterialApp.router(
      title: 'Door Radar',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
