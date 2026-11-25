import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/notifications.dart';
import '../state/connection.dart';
import '../state/events.dart';
import 'router.dart';
import 'theme.dart';

class DoorRadarApp extends ConsumerStatefulWidget {
  const DoorRadarApp({super.key});

  @override
  ConsumerState<DoorRadarApp> createState() => _DoorRadarAppState();
}

class _DoorRadarAppState extends ConsumerState<DoorRadarApp> {
  StreamSubscription<int>? _taps;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // 이상 상황 알림을 누르면 그 이벤트 상세로
    _taps = ref.read(alertNotificationsProvider).taps.listen((id) => ref.read(routerProvider).go('/events/$id'));
    // 화면에서 사라지면 실시간 연결을 끊고(배터리), 다시 보이면 붙어서 빈 기간을 채운다.
    // 백그라운드 알림은 docs/TRAINING_PIPELINE.md 의 5. 백그라운드 알림 참고.
    _lifecycle = AppLifecycleListener(
      onHide: () => ref.read(connectionProvider.notifier).pauseLive(),
      onShow: () => ref.read(connectionProvider.notifier).resumeLive(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _taps?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 이벤트·사진 폰 보관은 어느 화면에 있든 돈다
    ref.listen(eventSyncProvider, (_, _) {});
    return MaterialApp.router(
      title: 'Door Radar',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
