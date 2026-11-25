import 'dart:convert';
import 'dart:io';

import 'package:door_radar_app/data/api/live_socket.dart';
import 'package:door_radar_app/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('다시 연결 간격 1·2·4·8초, 이후 8초 반복', () {
    final delays = [1, 2, 4, 8].map((s) => Duration(seconds: s)).toList();
    final seq = [for (var i = 1; i <= 6; i++) LiveSocket.delayFor(i, delays).inSeconds];
    expect(seq, [1, 2, 4, 8, 8, 8]);
  });

  test('토큰은 ?token= 으로', () {
    final s = LiveSocket(device: const PiDevice(host: '10.0.2.2'), token: 'a+b');
    expect(s.uri.toString(), 'ws://10.0.2.2:8080/ws/live?token=a%2Bb');
  });

  // 실제 로컬 WebSocket 서버로: 메시지 받기 → 서버가 끊음 → 재시도 → 다시 붙으면 onReconnected
  test('끊기면 다시 붙고 onReconnected 를 부른다', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final sockets = <WebSocket>[];
    server.listen((req) async {
      if (req.uri.path != '/ws/live' || req.uri.queryParameters['token'] != 'tok') {
        req.response.statusCode = 403;
        await req.response.close();
        return;
      }
      final ws = await WebSocketTransformer.upgrade(req);
      sockets.add(ws);
      ws.add(jsonEncode({'type': 'frame', 't': '2026-11-19T15:02:31.400+09:00', 'people': [], 'radar': 'ok'}));
    });

    var reconnects = 0;
    final socket = LiveSocket(
      device: PiDevice(host: '127.0.0.1', port: server.port),
      token: 'tok',
      delaysSec: const [1],
      onReconnected: () => reconnects++,
    );
    final states = <LiveSocketStatus>[];
    socket.states.listen((s) => states.add(s.status));
    final frames = <LiveFrame>[];
    socket.frames.listen(frames.add);

    socket.start();
    await _until(() => frames.length == 1);
    expect(socket.state.status, LiveSocketStatus.connected);
    expect(reconnects, 0);

    await sockets.first.close(); // 서버 쪽에서 끊기
    await _until(() => states.contains(LiveSocketStatus.retrying));
    await _until(() => reconnects == 1 && frames.length == 2, timeout: const Duration(seconds: 5));
    expect(socket.state.status, LiveSocketStatus.connected);

    await socket.close();
    await server.close(force: true);
  });

  // 소켓은 열려 있는데 프레임이 끊기면(Wi-Fi 가 조용히 끊김) frameTimeout 뒤에 끊긴 것으로 보고 다시 붙는다
  test('프레임이 frameTimeout 넘게 안 오면 다시 붙는다', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var upgrades = 0;
    server.listen((req) async {
      final ws = await WebSocketTransformer.upgrade(req);
      upgrades++;
      ws.add(jsonEncode({'type': 'frame', 't': '2026-11-19T15:02:31.400+09:00', 'people': [], 'radar': 'ok'}));
      // 이후 아무것도 보내지 않는다
    });
    var reconnects = 0;
    final socket = LiveSocket(
      device: PiDevice(host: '127.0.0.1', port: server.port),
      token: 'tok',
      delaysSec: const [1],
      frameTimeout: const Duration(milliseconds: 300),
      onReconnected: () => reconnects++,
    );
    final states = <LiveSocketStatus>[];
    socket.states.listen((s) => states.add(s.status));
    socket.start();
    await _until(() => states.contains(LiveSocketStatus.retrying));
    expect(upgrades, 1);
    await _until(() => reconnects == 1, timeout: const Duration(seconds: 4));
    expect(upgrades, 2);
    await socket.close();
    await server.close(force: true);
  });

  test('토큰이 틀리면 핸드셰이크 거절 → 재시도 상태', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      req.response.statusCode = 403;
      await req.response.close();
    });
    final socket = LiveSocket(device: PiDevice(host: '127.0.0.1', port: server.port), token: 'wrong', delaysSec: const [1]);
    socket.start();
    await _until(() => socket.state.status == LiveSocketStatus.retrying);
    expect(socket.state.retryIn, const Duration(seconds: 1));
    await socket.close();
    await server.close(force: true);
  });
}

Future<void> _until(bool Function() ok, {Duration timeout = const Duration(seconds: 3)}) async {
  final end = DateTime.now().add(timeout);
  while (!ok()) {
    if (DateTime.now().isAfter(end)) fail('시간 안에 조건을 만족하지 못함');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
