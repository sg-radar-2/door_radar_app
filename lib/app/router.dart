import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/connect/connect_screen.dart';
import '../features/events/event_detail_screen.dart';
import '../features/events/events_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/device_screen.dart';
import '../features/settings/settings_screen.dart';
import '../state/connection.dart';
import '../widgets/app_shell.dart';

/// 경로
///   /connect               연결 (처음, 연결이 끊겼을 때)
///   /home                  홈 (실시간)          ┐
///   /events, /events/:id   기록, 이벤트 상세    ├ 하단 탭 3개
///   /settings, /settings/device  설정, 기기 상태 ┘
///
/// 저장된 토큰이 있으면 /home 으로 시작, 없으면 /connect.
/// 토큰이 없어지면(연결 해제, 토큰 거절) 어느 화면에 있든 /connect 로 보낸다.
/// 페어링된 채로 /connect 에 가는 건 허용한다(기기 상태 → "다른 기기 연결").
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(connectionProvider.select((c) => c.isPaired), (_, _) => refresh.value++);

  // 이벤트 상세는 하단 탭 없이 전체 화면 (EventDetail.dc.html)
  final rootKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: ref.read(connectionProvider).isPaired ? '/home' : '/connect',
    refreshListenable: refresh,
    redirect: (context, state) {
      final paired = ref.read(connectionProvider).isPaired;
      if (!paired && state.matchedLocation != '/connect') return '/connect';
      return null;
    },
    routes: [
      GoRoute(path: '/connect', builder: (context, state) => const ConnectScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/events',
              builder: (context, state) => const EventsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: rootKey,
                  builder: (context, state) =>
                      EventDetailScreen(eventId: int.parse(state.pathParameters['id']!)),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(path: 'device', parentNavigatorKey: rootKey, builder: (context, state) => const DeviceScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(body: Center(child: Text('없는 화면: ${state.uri}'))),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
