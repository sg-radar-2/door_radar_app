import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/notifications.dart';
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

  @override
  void initState() {
    super.initState();
    // 이상 상황 알림을 누르면 그 이벤트 상세로
    _taps = ref.read(alertNotificationsProvider).taps.listen((id) => ref.read(routerProvider).go('/events/$id'));
  }

  @override
  void dispose() {
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
