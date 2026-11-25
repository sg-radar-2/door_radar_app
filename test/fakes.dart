import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:door_radar_app/data/api/live_socket.dart';
import 'package:door_radar_app/data/api/pi_api.dart';
import 'package:door_radar_app/data/models/models.dart';
import 'package:door_radar_app/data/notifications.dart';

/// 요청을 기록하고 미리 정한 응답을 돌려주는 dio 어댑터
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  /// (method, path, body) → (status, json)
  final (int, Object?) Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final (status, body) = handler(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

PiApi fakeApi(PiDevice device, String? token, FakeAdapter adapter) =>
    PiApi(device: device, token: token, dio: Dio()..httpClientAdapter = adapter);

const infoBody = {
  'name': 'doorradar',
  'host': 'doorradar.local',
  'version': '0.1.0-mock',
  'model': 'situation_trees_1111',
  'model_version': 'v5',
  'region': {'xmin': -2, 'xmax': 2, 'ymin': 0, 'ymax': 3, 'fov_deg': 135},
};

/// 네트워크 없이 상태만 흉내 내는 소켓
class FakeLiveSocket implements LiveSocket {
  final _states = StreamController<LiveSocketState>.broadcast();
  final _messages = StreamController<LiveMessage>.broadcast();
  bool started = false;
  bool closed = false;

  void emit(LiveSocketState s) => _states.add(s);

  /// 서버가 보낸 것처럼 메시지 넣기 (JSON 문자열 그대로)
  void push(Map<String, Object?> json) => _messages.add(LiveMessage.tryParse(jsonEncode(json))!);

  @override
  void start() {
    started = true;
    scheduleMicrotask(() => _states.add(const LiveSocketState(LiveSocketStatus.connected)));
  }

  @override
  Future<void> close() async {
    closed = true;
    await _states.close();
    await _messages.close();
  }

  @override
  Stream<LiveSocketState> get states => _states.stream;

  @override
  Stream<LiveMessage> get messages => _messages.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 알림을 띄우지 않고 기록만
class FakeNotifications implements AlertNotifications {
  final shown = <Event>[];
  int permissionRequests = 0;
  final _taps = StreamController<int>.broadcast();

  void tap(int id) => _taps.add(id);

  @override
  Future<void> requestPermission() async => permissionRequests++;

  @override
  Future<void> show(Event event) async => shown.add(event);

  @override
  Future<void> cancel(int eventId) async {}

  @override
  Stream<int> get taps => _taps.stream;
}

/// 실시간 프레임 JSON (SPEC 5장 형식)
Map<String, Object?> frameJson(String t, List<Map<String, Object?>> people, {String radar = 'ok'}) =>
    {'type': 'frame', 't': t, 'people': people, 'radar': radar};

Map<String, Object?> personJson(String id, double x, double y,
        {String situation = '방문', double prob = 0.82, bool abnormal = false, double still = 0, double elapsed = 0}) =>
    {
      'id': id, 'x': x, 'y': y, 'hidden': false, 'situation': situation, 'prob': prob,
      'abnormal': abnormal, 'still_s': still, 'elapsed_s': elapsed,
    };

Map<String, Object?> cameraEventJson(int id, String person, String t, {String situation = '장시간 체류', bool photo = true}) => {
      'type': 'event',
      'event': {
        'id': id, 'kind': 'camera', 'person': person, 'situation': situation, 'prob': 1.0, 'abnormal': true,
        'photo': photo, 't': t, 'started_at': t, 'ended_at': null, 'label': null,
      },
    };
