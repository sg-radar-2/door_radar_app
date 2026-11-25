import 'package:dio/dio.dart';
import 'package:door_radar_app/data/api/pi_api.dart';
import 'package:door_radar_app/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  const device = PiDevice(host: '10.0.2.2');

  test('인증이 필요한 요청에만 Bearer 토큰', () async {
    final adapter = FakeAdapter((o) => switch (o.path) {
          '/api/info' => (200, infoBody),
          '/api/photos/pending' => (200, {'ids': [101, 103]}),
          _ => (404, {'error': 'not_found', 'message': ''}),
        });
    final api = fakeApi(device, 'tok', adapter);

    await api.info();
    expect(await api.pendingPhotos(), [101, 103]);

    expect(adapter.requests[0].uri.toString(), 'http://10.0.2.2:8080/api/info');
    expect(adapter.requests[0].headers['Authorization'], isNull);
    expect(adapter.requests[1].headers['Authorization'], 'Bearer tok');
  });

  test('pair 로 받은 토큰을 바로 쓴다', () async {
    final adapter = FakeAdapter((o) => switch (o.path) {
          '/api/pair' => (200, {'token': 'new'}),
          _ => (200, <Object?>[]),
        });
    final api = fakeApi(device, null, adapter);
    expect(await api.pair('482913'), 'new');
    expect(adapter.requests.single.data, {'code': '482913'});

    await api.events(since: '2026-11-19T15:03:40+09:00', limit: 2);
    final req = adapter.requests.last;
    expect(req.headers['Authorization'], 'Bearer new');
    expect(req.queryParameters, {'since': '2026-11-19T15:03:40+09:00', 'limit': 2});
    expect(req.uri.query, contains('since=2026-11-19T15%3A03%3A40%2B09%3A00')); // + 가 공백으로 바뀌지 않게
  });

  test('{"error","message"} 는 PiApiException', () async {
    final adapter = FakeAdapter((o) => (401, {'error': 'bad_code', 'message': '페어링 코드가 틀렸습니다.'}));
    final api = fakeApi(device, null, adapter);
    await expectLater(
      api.pair('000000'),
      throwsA(isA<PiApiException>()
          .having((e) => e.statusCode, 'statusCode', 401)
          .having((e) => e.code, 'code', 'bad_code')
          .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
    );
  });

  test('네트워크 오류는 code: network', () {
    final e = PiApiException.fromDio(DioException.connectionError(
      requestOptions: RequestOptions(path: '/api/info'),
      reason: 'refused',
    ));
    expect(e.code, 'network');
    expect(e.isNetwork, isTrue);
  });

  test('설정은 바꿀 키만 보낸다', () async {
    final adapter = FakeAdapter((o) => (200, {
          'notify': ['배회'],
          'camera_on': false,
          'camera_prob': 0.6,
          'camera_hold_s': 1.0,
          'region': {'xmin': -2, 'xmax': 2, 'ymin': 0, 'ymax': 3, 'fov_deg': 135},
          'device_keep_days': 30,
        }));
    final api = fakeApi(device, 'tok', adapter);
    final s = await api.updateSettings(cameraOn: false);
    expect(adapter.requests.single.method, 'PUT');
    expect(adapter.requests.single.data, {'camera_on': false});
    expect(s.cameraOn, isFalse);
  });

  test('사진 URL', () {
    final api = PiApi(device: device, token: 'tok');
    expect(api.photoUrl(128, thumb: true), 'http://10.0.2.2:8080/api/events/128/photo?thumb=1');
    expect(api.authHeaders, {'Authorization': 'Bearer tok'});
  });
}
