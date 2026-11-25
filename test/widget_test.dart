import 'package:door_radar_app/app/app.dart';
import 'package:door_radar_app/data/models/models.dart';
import 'package:door_radar_app/data/api/live_socket.dart';
import 'package:door_radar_app/features/settings/device_screen.dart';
import 'package:door_radar_app/features/settings/settings_screen.dart';
import 'package:door_radar_app/data/local_store.dart';
import 'package:door_radar_app/data/notifications.dart';
import 'package:door_radar_app/data/push.dart';
import 'package:door_radar_app/data/storage.dart';
import 'package:door_radar_app/features/events/event_detail_screen.dart';
import 'package:door_radar_app/features/events/events_screen.dart';
import 'package:door_radar_app/features/home/home_screen.dart';
import 'package:door_radar_app/features/connect/connect_screen.dart';
import 'package:door_radar_app/state/connection.dart';
import 'package:door_radar_app/state/events.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, Semantics, Size;
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Riverpod 3 은 위젯 갱신을 다음 프레임에 묶어 보내서 두 번 그린다
Future<void> flush(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<void> tapConnect(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(ConnectScreen.submitKey));
  await tester.tap(find.byKey(ConnectScreen.submitKey));
}

void main() {
  late MemoryKv kv;
  late FakeAdapter adapter;
  late List<FakeLiveSocket> sockets;
  late FakeNotifications notes;
  late MemoryLocalStore store;
  late FakePush push;
  late Map<int, Map<String, Object?>> piEvents; // 파이에 있는 이벤트 상세 (id → JSON)
  late Map<String, Object?> piSettings; // 파이 설정 (PUT 하면 바뀐다)
  late bool failSettings; // PUT /api/settings 실패시키기

  (int, Object?) labelEvent(int id, String? situation) {
    final e = piEvents[id];
    if (e == null) return (404, {'error': 'not_found', 'message': ''});
    e['label'] = situation;
    return (200, <String, Object?>{...e}..remove('track')..remove('behaviors'));
  }

  setUp(() {
    kv = MemoryKv();
    sockets = [];
    notes = FakeNotifications();
    store = MemoryLocalStore();
    push = FakePush();
    piEvents = {};
    piSettings = {...settingsBody};
    failSettings = false;
    adapter = FakeAdapter((o) => switch (o.path) {
          '/api/info' when o.headers['Authorization'] == 'Bearer tok' => (200, infoBody),
          '/api/info' => (200, {'name': 'rad2-cloud', 'version': '0.1.0'}), // 토큰 없으면 클라우드 정보만
          '/api/pair' when (o.data as Map)['code'] == '482913' => (200, {'token': 'tok'}),
          '/api/pair' => (401, {'error': 'bad_code', 'message': '페어링 코드가 틀렸습니다.'}),
          '/api/status' => (200, statusBody),
          '/api/settings' when o.method == 'PUT' && failSettings => (503, {'error': 'busy', 'message': '잠시 뒤에'}),
          '/api/settings' when o.method == 'PUT' => (200, piSettings = {...piSettings, ...(o.data as Map<String, Object?>)}),
          '/api/settings' => (200, piSettings),
          '/api/radar/reconnect' => (200, {'radar': 'connecting'}),
          '/api/events' => (200, recentBody),
          '/api/photos/pending' => (200, {'ids': <int>[]}),
          '/api/push_token' => (200, {'ok': true}),
          final p when p.endsWith('/label') => labelEvent(int.parse(p.split('/')[3]), (o.data as Map)['situation'] as String?),
          final p when p.startsWith('/api/events/') && piEvents.containsKey(int.parse(p.split('/')[3])) =>
            (200, piEvents[int.parse(p.split('/')[3])]),
          _ => (404, {'error': 'not_found', 'message': ''}),
        });
  });

  Future<void> pumpApp(WidgetTester tester, {SavedSession saved = const SavedSession()}) async {
    // 와이어프레임 크기 390×844
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appStorageProvider.overrideWithValue(AppStorage(kv)),
        savedSessionProvider.overrideWithValue(saved),
        alertNotificationsProvider.overrideWithValue(notes),
        localStoreProvider.overrideWithValue(store),
        pushMessagingProvider.overrideWithValue(push),
        piApiFactoryProvider.overrideWithValue((device, token) => fakeApi(device, token, adapter)),
        liveSocketFactoryProvider.overrideWithValue((device, token, onReconnected) {
          final s = FakeLiveSocket();
          sockets.add(s);
          return s;
        }),
      ],
      child: const DoorRadarApp(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('저장된 토큰이 없으면 연결 화면 → 코드로 클라우드에 페어링하고 홈으로', (tester) async {
    await pumpApp(tester);
    expect(find.text('현관 기기\n연결하기'), findsOneWidget);
    expect(find.text('IP 직접 입력'), findsNothing); // 클라우드만 (SPEC 9장)

    await tester.enterText(find.byKey(ConnectScreen.codeFieldKey), '482913');
    await tester.pump();
    expect(find.text('9'), findsOneWidget); // 코드 칸에 숫자가 그려진다

    await tapConnect(tester);
    await tester.pumpAndSettle();

    expect(find.text('현관'), findsOneWidget); // 홈
    expect(find.text('기록'), findsWidgets); // 하단 탭
    // 코드 → 토큰 → 그 토큰으로 기기 정보 (SPEC 9.1)
    expect(adapter.requests.map((r) => r.path).take(2), ['/api/pair', '/api/info']);
    expect(adapter.requests[1].headers['Authorization'], 'Bearer tok');
    expect(kv.values['pi_token'], 'tok');
    expect(kv.values['pi_address'], '10.0.2.2');
    expect(sockets.single.started, isTrue);
  });

  testWidgets('페어링 코드가 틀리면 안내하고 연결 화면에 남는다', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byKey(ConnectScreen.codeFieldKey), '000000');
    await tapConnect(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('페어링 코드가 맞지 않아요'), findsOneWidget);
    expect(find.text('현관 기기\n연결하기'), findsOneWidget);
    expect(kv.values.containsKey('pi_token'), isFalse);
  });

  testWidgets('코드가 6자리가 아니면 요청하지 않는다', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byKey(ConnectScreen.codeFieldKey), '4829');
    await tapConnect(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('6자리'), findsWidgets);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('저장된 토큰이 있으면 바로 홈, 실시간 연결 시작', (tester) async {
    await pumpApp(tester, saved: const SavedSession(device: PiDevice(host: '10.0.2.2'), token: 'tok'));
    expect(find.text('현관'), findsOneWidget);
    expect(find.text('현관 기기\n연결하기'), findsNothing);
    expect(sockets.single.started, isTrue);
  });

  testWidgets('앱이 화면에서 사라지면 실시간 연결을 끊고, 다시 보이면 새로 붙는다', (tester) async {
    await pumpApp(tester, saved: const SavedSession(device: PiDevice(host: '10.0.2.2'), token: 'tok'));
    expect(sockets, hasLength(1));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(sockets.single.closed, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(sockets, hasLength(2));
    expect(sockets.last.started, isTrue);
    expect(find.text('현관'), findsOneWidget); // 페어링은 그대로
  });

  testWidgets('토큰이 없어지면 연결 화면으로 (안내 문구)', (tester) async {
    await pumpApp(tester, saved: const SavedSession(device: PiDevice(host: '10.0.2.2'), token: 'tok'));
    final container = ProviderScope.containerOf(tester.element(find.text('현관')));
    await container.read(connectionProvider.notifier).forget(message: '다시 페어링해 주세요.');
    await tester.pumpAndSettle();

    expect(find.text('현관 기기\n연결하기'), findsOneWidget);
    expect(find.text('다시 페어링해 주세요.'), findsOneWidget);
    expect(sockets.single.closed, isTrue);
  });

  group('홈', () {
    const saved = SavedSession(device: PiDevice(host: '10.0.2.2'), token: 'tok');
    final t0 = DateTime.now().toUtc();
    String at(double s) => t0.add(Duration(milliseconds: (s * 1000).round())).toIso8601String();

    testWidgets('칩·최근 기록·알림 권한 요청', (tester) async {
      await pumpApp(tester, saved: saved);
      expect(find.text('레이더 연결'), findsOneWidget);
      expect(find.text('카메라 정상'), findsOneWidget);
      expect(find.text('장시간 체류'), findsOneWidget); // 최근 기록
      expect(find.text('배달'), findsOneWidget);
      expect(find.text('문 앞에 아무도 없어요'), findsOneWidget);
      expect(notes.permissionRequests, 1);
      // 최근 기록은 limit=2 (폰 보관용 따라잡기는 limit=200 으로 따로)
      expect(adapter.requests.where((r) => r.path == '/api/events' && r.queryParameters['limit'] == 2), isNotEmpty);
    });

    testWidgets('프레임이 오면 진행 중 판정 카드, 이상인 사람이 먼저', (tester) async {
      await pumpApp(tester, saved: saved);
      sockets.single.push(frameJson(at(0), [
        personJson('T1', 0.4, 1.3, situation: '방문', prob: 0.82, still: 6.5, elapsed: 14.2),
        personJson('T2', 1.5, 2.5, situation: '배회', prob: 1, abnormal: true, elapsed: 40),
      ]));
      await flush(tester);
      expect(find.text('T1 · 14초 전부터'), findsOneWidget);
      expect(find.text('방문'), findsOneWidget);
      expect(find.text('6.5초'), findsOneWidget);
      expect(find.text('1.4m'), findsOneWidget);
      expect(find.text('2명'), findsOneWidget);
      final y1 = tester.getTopLeft(find.text('T1 · 14초 전부터')).dy;
      final y2 = tester.getTopLeft(find.text('T2 · 40초 전부터')).dy;
      expect(y2, lessThan(y1)); // 이상(배회)이 위
    });

    testWidgets('notify 의 camera 이벤트 → 빨간 배너 + 알림, 확인 → 접기', (tester) async {
      await pumpApp(tester, saved: saved);
      final s = sockets.single;
      s.push(frameJson(at(0), [personJson('T3', 0.9, 1.15, situation: '장시간 체류', prob: 1, abnormal: true, still: 16)]));
      s.push(cameraEventJson(128, 'T3', at(0.1)));
      await flush(tester);

      expect(find.byKey(HomeScreen.alertBannerKey), findsOneWidget);
      expect(find.text('장시간 체류 감지'), findsOneWidget);
      expect(find.textContaining('문 앞 1.5m에서 16초째 머무는 중'), findsOneWidget);
      expect(find.text('레이더 연결'), findsNothing); // 배너가 뜨면 칩은 숨김 (HomeAlert)
      expect(notes.shown.map((e) => e.id), [128]);

      // 같은 이벤트가 또 와도 알림은 한 번
      s.push(cameraEventJson(128, 'T3', at(0.1)));
      await flush(tester);
      expect(notes.shown, hasLength(1));

      await tester.tap(find.byKey(HomeScreen.alertOkKey));
      await flush(tester);
      expect(find.byKey(HomeScreen.alertBannerKey), findsNothing);
      await tester.pumpAndSettle(); // 사진 동기화 요청 끝내기
    });

    testWidgets('배너: 사람이 2초 넘게 안 보이면 접는다 / 사진 보기 → 이벤트 상세', (tester) async {
      await pumpApp(tester, saved: saved);
      final s = sockets.single;
      s.push(frameJson(at(0), [personJson('T3+7', 0.9, 1.15, situation: '장시간 체류', prob: 1, abnormal: true)]));
      s.push(cameraEventJson(128, 'T3', at(0.1))); // id 가 묶여도 같은 사람
      s.push(frameJson(at(0.2), []));
      s.push(frameJson(at(1.8), []));
      await flush(tester);
      expect(find.byKey(HomeScreen.alertBannerKey), findsOneWidget);
      s.push(frameJson(at(2.4), []));
      await flush(tester);
      expect(find.byKey(HomeScreen.alertBannerKey), findsNothing);

      s.push(frameJson(at(3), [personJson('T9', 0.9, 1.15, situation: '반복 접근', prob: 1, abnormal: true)]));
      s.push(cameraEventJson(130, 'T9', at(3.1), situation: '반복 접근', photo: false));
      await flush(tester);
      await tester.tap(find.byKey(HomeScreen.alertPhotoKey));
      await tester.pumpAndSettle();
      expect(find.text('반복 접근'), findsOneWidget); // 상세 화면 (폰 저장본)
      expect(find.text('판정이 맞나요?'), findsOneWidget);
    });

    testWidgets('notify 에 없는 상황·정상 상황은 배너도 알림도 없음', (tester) async {
      await pumpApp(tester, saved: saved);
      final s = sockets.single;
      s.push(cameraEventJson(140, 'T1', at(0), situation: '배회')); // settingsBody.notify 에 배회 없음
      s.push({
        'type': 'event',
        'event': {
          'id': 141, 'kind': 'final', 'person': 'T1', 'situation': '방문', 'prob': 0.9, 'abnormal': false,
          'photo': false, 't': at(1), 'started_at': at(0),
        },
      });
      await flush(tester);
      expect(find.byKey(HomeScreen.alertBannerKey), findsNothing);
      expect(notes.shown, isEmpty);
      expect(find.text('방문'), findsOneWidget); // 최근 기록에는 들어간다
      await tester.pumpAndSettle(); // 사진 동기화 요청 끝내기
    });

    testWidgets('끊기면 칩이 바뀌고 지도 위에 "다시 연결하는 중"', (tester) async {
      await pumpApp(tester, saved: saved);
      sockets.single.emit(const LiveSocketState(LiveSocketStatus.retrying, retryIn: Duration(seconds: 2), attempt: 1));
      await flush(tester);
      expect(find.text('다시 연결하는 중'), findsNWidgets(2)); // 칩 + 지도
      expect(find.text('2초 뒤 다시 시도'), findsOneWidget);
      expect(find.text('레이더 연결'), findsNothing);

      sockets.single.emit(const LiveSocketState(LiveSocketStatus.connected));
      await flush(tester);
      expect(find.text('다시 연결하는 중'), findsNothing);
      expect(find.text('레이더 연결'), findsOneWidget);
      await tester.pumpAndSettle(); // 다시 붙으며 보낸 status·settings·events 요청 끝내기
    });

    testWidgets('알림을 누르면 이벤트 상세로', (tester) async {
      await pumpApp(tester, saved: saved);
      notes.tap(128);
      await tester.pumpAndSettle();
      expect(find.text('이 기록은 기기에서 지워졌어요'), findsOneWidget); // 상세 화면 (파이에 없는 id)
    });
  });

  group('기록·상세', () {
    const saved = SavedSession(device: PiDevice(host: '10.0.2.2'), token: 'tok');
    final today = DateTime.now();
    String at(int h, int m, [int s = 0]) => isoLocal(DateTime(today.year, today.month, today.day, h, m, s));

    Map<String, Object?> finalJson(int id, String situation,
            {required String started, required String ended, bool photo = false, String? path}) =>
        {
          'id': id, 'kind': 'final', 'person': 'T$id', 't': ended, 'started_at': started, 'ended_at': ended,
          'situation': situation, 'prob': situation == '배달' ? 0.93 : 1.0,
          'abnormal': ['장시간 체류', '배회', '반복 접근'].contains(situation), 'end_situation': situation,
          'photo': photo, 'path': path, 'label': null,
        };

    Future<void> seed() async {
      // 오늘: 장시간 체류(촬영 + 최종) / 배달.  폰 저장소에만 있다 (파이 목록에는 없음)
      await store.upsertAll([
        Event.fromJson({
          'id': 301, 'kind': 'camera', 'person': 'T301', 't': at(0, 3, 10), 'started_at': at(0, 2, 17),
          'situation': '장시간 체류', 'prob': 1.0, 'abnormal': true, 'photo': false,
        }),
        Event.fromJson(finalJson(302, '장시간 체류', started: at(0, 2, 17), ended: at(0, 3, 40))),
        Event.fromJson(finalJson(303, '배달',
            started: at(0, 1), ended: at(0, 1, 25), path: '외곽에서 들어옴 → 외곽으로 사라짐(2.6m)')),
      ]);
    }

    Future<void> openEvents(WidgetTester tester) async {
      await tester.tap(find.text('기록').last);
      await tester.pumpAndSettle();
    }

    testWidgets('폰에 저장된 오늘 기록: 촬영 이벤트는 최종 판정에 합치고, 이상만 필터', (tester) async {
      await seed();
      await pumpApp(tester, saved: saved);
      await openEvents(tester);

      expect(find.text('오늘 전체'), findsOneWidget);
      expect(find.text('장시간 체류'), findsOneWidget); // 301(촬영)은 302 에 합쳐짐
      expect(find.text('배달'), findsOneWidget);
      expect(find.textContaining('1분 23초'), findsOneWidget);
      expect(find.textContaining('외곽으로 사라짐'), findsOneWidget);

      await tester.tap(find.byKey(EventsScreen.abnormalTabKey));
      await tester.pumpAndSettle();
      expect(find.text('장시간 체류'), findsOneWidget);
      expect(find.text('배달'), findsNothing);
    });

    testWidgets('파이에 연결이 안 돼도 폰 저장본은 보인다', (tester) async {
      await seed();
      await pumpApp(tester, saved: saved);
      sockets.single.emit(const LiveSocketState(LiveSocketStatus.retrying, retryIn: Duration(seconds: 4)));
      await flush(tester);
      await openEvents(tester);
      expect(find.text('장시간 체류'), findsOneWidget);
      expect(find.text('배달'), findsOneWidget);
    });

    testWidgets('상세: 맞아요 → 정답 저장 → 되돌리기, 다른 상황이에요 → 고르기', (tester) async {
      await seed();
      piEvents[302] = {
        ...finalJson(302, '장시간 체류',
            started: at(0, 2, 17), ended: at(0, 3, 40), path: '외곽에서 들어옴(2.4m) → 문으로 사라짐(0.5m)'),
        'end_situation': '방문',
        'behaviors': [
          {'situation': '방문', 'prob': 0.94, 'source': 'end'},
          {'situation': '장시간 체류', 'prob': 1.0, 'source': 'progress'},
        ],
        'reason': '이상 행동 우선: 진행 중 장시간 체류 100% → 끝날 때 판정 방문 94% 대신',
        'track': [
          [0.0, 1.7, 1.66],
          [0.2, 1.6, 1.6],
          [0.4, 1.5, 1.5],
        ],
      };
      await pumpApp(tester, saved: saved);
      await openEvents(tester);
      await tester.tap(find.text('장시간 체류'));
      await tester.pumpAndSettle();

      // 상세는 하단 탭 없이
      expect(find.text('홈'), findsNothing);
      expect(find.text('외곽에서 들어옴 (2.4m) → 문으로 사라짐 (0.5m)'), findsOneWidget);
      expect(find.text('장시간 체류 100%'), findsOneWidget);
      expect(find.text('방문 94% · 끝날 때'), findsOneWidget);
      expect(find.text('지나간 길'), findsOneWidget);
      expect(find.text('촬영 사진 없음'), findsOneWidget);

      // 지나간 길: 처음엔 전체, 재생하면 실제 속도(0.4초 궤적), 배속을 바꾸면 그만큼 빨리
      await tester.scrollUntilVisible(find.byKey(TrackMapKeys.play), 200);
      await tester.ensureVisible(find.byKey(TrackMapKeys.play));
      await tester.pumpAndSettle();
      expect(find.text('0.4초 / 0.4초'), findsOneWidget);
      await tester.tap(find.byKey(TrackMapKeys.play));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('0.2초 / 0.4초'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('0.4초 / 0.4초'), findsOneWidget);
      await tester.tap(find.byKey(TrackMapKeys.speed(2)));
      await tester.tap(find.byKey(TrackMapKeys.map)); // 지도를 눌러도 재생
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('0.2초 / 0.4초'), findsOneWidget);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.byKey(EventDetailScreen.yesKey), 200);
      await tester.ensureVisible(find.byKey(EventDetailScreen.yesKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(EventDetailScreen.yesKey));
      await tester.pumpAndSettle();
      expect(find.text('정답으로 저장했어요'), findsOneWidget);
      expect(piEvents[302]!['label'], '장시간 체류');
      expect((await store.get(302))!.event.label, '장시간 체류');

      await tester.tap(find.byKey(EventDetailScreen.undoKey));
      await tester.pumpAndSettle();
      expect(find.text('판정이 맞나요?'), findsOneWidget);
      expect(piEvents[302]!['label'], isNull);

      await tester.tap(find.byKey(EventDetailScreen.otherKey));
      await tester.pumpAndSettle();
      expect(find.text('어떤 상황이었나요?'), findsOneWidget);
      await tester.tap(find.text('방문').last);
      await tester.pumpAndSettle();
      expect(find.text('정답: 방문 · labels.csv로 내보낼 수 있어요'), findsOneWidget);
      expect(piEvents[302]!['label'], '방문');

      // 뒤로 → 기록
      await tester.scrollUntilVisible(find.byTooltip('뒤로'), -300);
      await tester.tap(find.byTooltip('뒤로'));
      await tester.pumpAndSettle();
      expect(find.text('오늘 전체'), findsOneWidget);
    });
  });

  group('클라우드', () {
    const saved = SavedSession(device: PiDevice(host: '10.0.2.2'), token: 'tok');

    List<Object?> pushPuts() =>
        [for (final r in adapter.requests) if (r.path == '/api/push_token') (r.data as Map)['token']];

    testWidgets('연결되면 FCM 토큰을 클라우드에 등록, 토큰이 바뀌면 다시', (tester) async {
      await pumpApp(tester, saved: saved);
      expect(pushPuts(), ['fcm1']);

      push.refresh('fcm2');
      await tester.pumpAndSettle();
      expect(pushPuts(), ['fcm1', 'fcm2']);
    });

    test('푸시 data 의 event_id (문자열) → 이벤트 id', () {
      expect(eventIdOf({'event_id': '128'}), 128);
      expect(eventIdOf({'event_id': 'x'}), isNull);
      expect(eventIdOf({}), isNull);
    });

    testWidgets('파이가 클라우드에 안 붙어 있으면 홈에 "기기 꺼짐"', (tester) async {
      await pumpApp(tester, saved: saved);
      sockets.single.push({'type': 'frame', 't': DateTime.now().toIso8601String(), 'radar': 'disconnected', 'pi': 'offline', 'people': []});
      await flush(tester);
      expect(find.text('기기 꺼짐'), findsWidgets); // 칩 + 지도 위 안내
      expect(find.text('기기가 꺼져 있거나 인터넷에 연결되지 않았어요'), findsOneWidget);
    });
  });

  group('설정·기기 상태', () {
    const saved = SavedSession(device: PiDevice(host: '10.0.2.2'), token: 'tok');

    Future<void> openSettings(WidgetTester tester) async {
      await pumpApp(tester, saved: saved);
      await tester.tap(find.text('설정').last);
      await tester.pumpAndSettle();
    }

    testWidgets('알림 스위치 → PUT notify, 실패하면 되돌리고 안내', (tester) async {
      await openSettings(tester);
      expect(find.text('60% 이상 · 1초 유지'), findsOneWidget);

      // settingsBody.notify = [장시간 체류, 반복 접근] → 배회 켜기
      await tester.tap(find.byKey(SettingsScreen.notifyKey('배회')));
      await tester.pumpAndSettle();
      final put = adapter.requests.lastWhere((r) => r.method == 'PUT');
      expect(put.data, {'notify': ['장시간 체류', '배회', '반복 접근']});
      expect(piSettings['notify'], ['장시간 체류', '배회', '반복 접근']);

      failSettings = true;
      await tester.tap(find.byKey(SettingsScreen.cameraKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('바꾸지 못했어요'), findsOneWidget);
      final cam = tester.widget<Semantics>(
          find.descendant(of: find.byKey(SettingsScreen.cameraKey), matching: find.byType(Semantics)).first);
      expect(cam.properties.toggled, isTrue); // 되돌아감
    });

    testWidgets('휴대폰 보관 기간: 범위 밖이면 빨간 안내, 포커스가 빠지면 끝값으로 저장', (tester) async {
      await openSettings(tester);
      expect(find.text('이 폰에 7~730일 · 기기에는 30일만 임시 보관'), findsOneWidget);

      await tester.enterText(find.byKey(SettingsScreen.keepDaysKey), '999');
      await tester.pump();
      expect(find.text('7부터 730 사이의 정수로 입력해 주세요'), findsOneWidget);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('730'), findsOneWidget);
      expect(kv.values['phone_keep_days'], '730');

      await tester.enterText(find.byKey(SettingsScreen.keepDaysKey), '3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(kv.values['phone_keep_days'], '7');
    });

    testWidgets('연결 해제: 확인 → 토큰·기기 주소 지우고 연결 화면 (사진은 남김)', (tester) async {
      kv.values.addAll({'pi_token': 'tok', 'pi_address': '10.0.2.2'});
      await openSettings(tester);
      await tester.tap(find.byKey(SettingsScreen.disconnectKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('폰에 보관한 사진과 기록은 지우지 않아요'), findsOneWidget);

      await tester.tap(find.text('연결 해제').last);
      await tester.pumpAndSettle();
      expect(find.text('현관 기기\n연결하기'), findsOneWidget);
      expect(kv.values.containsKey('pi_token'), isFalse);
      expect(kv.values.containsKey('pi_address'), isFalse);
      expect(find.text('10.0.2.2'), findsNothing); // 입력칸도 비어 있다
    });

    testWidgets('기기 상태: 상태·모델·저장 공간, 레이더 다시 연결', (tester) async {
      await openSettings(tester);
      await tester.tap(find.text('기기 상태'));
      await tester.pumpAndSettle();

      expect(find.text('정상 작동 중'), findsOneWidget);
      expect(find.text('doorradar.local'), findsOneWidget);
      expect(find.text('10 fps'), findsOneWidget);
      expect(find.text('52°C'), findsOneWidget);
      expect(find.text('연결됨'), findsOneWidget);
      expect(find.text('model v5'), findsOneWidget);
      expect(find.text('30일 임시 보관\n폰 전송 대기 0장'), findsOneWidget);
      expect(find.text('홈'), findsNothing); // 하단 탭 없이

      await tester.scrollUntilVisible(find.byKey(DeviceScreen.reconnectKey), 200);
      await tester.tap(find.byKey(DeviceScreen.reconnectKey));
      await tester.pump();
      expect(find.text('다시 연결하는 중…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(adapter.requests.where((r) => r.path == '/api/radar/reconnect'), hasLength(1));
      expect(find.text('레이더가 연결돼 있어요'), findsOneWidget);
    });
  });
}

const statusBody = {
  'radar': 'ok', 'camera': 'ok', 'frame_rate': 10.0, 'latency_s': 0.4, 'cpu_temp_c': 52.0, 'uptime_s': 10,
  'storage': {'used_gb': 1.0, 'total_gb': 29.0, 'photos': 2},
};

const settingsBody = {
  'notify': ['장시간 체류', '반복 접근'],
  'camera_on': true, 'camera_prob': 0.6, 'camera_hold_s': 1.0,
  'region': {'xmin': -2, 'xmax': 2, 'ymin': 0, 'ymax': 3, 'fov_deg': 135},
  'device_keep_days': 30,
};

final recentBody = [
  {
    'id': 106, 'kind': 'final', 'person': 'T5', 't': '2026-11-19T15:03:40+09:00',
    'started_at': '2026-11-19T15:02:17+09:00', 'ended_at': '2026-11-19T15:03:40+09:00',
    'situation': '장시간 체류', 'prob': 1.0, 'abnormal': true, 'end_situation': '방문', 'photo': true, 'label': null,
  },
  {
    'id': 104, 'kind': 'final', 'person': 'T4', 't': '2026-11-19T14:41:25+09:00',
    'started_at': '2026-11-19T14:41:00+09:00', 'ended_at': '2026-11-19T14:41:25+09:00',
    'situation': '배달', 'prob': 0.93, 'abnormal': false, 'end_situation': '배달', 'photo': false, 'label': null,
  },
];
