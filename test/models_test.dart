import 'dart:convert';

import 'package:door_radar_app/data/api/live_socket.dart';
import 'package:door_radar_app/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// toJson → 문자열 → 다시 Map (중첩 객체까지 순수 JSON 으로)
Map<String, dynamic> roundTrip(Map<String, dynamic> json) => jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

// ---- docs/SPEC.md 5장 예시 그대로 ----

const frameJson = '''
{
  "type": "frame",
  "t": "2026-11-19T15:02:31.400+09:00",
  "people": [
    {"id": "T3+7", "x": 0.42, "y": 1.35, "hidden": false,
     "situation": "방문", "prob": 0.82, "abnormal": false,
     "still_s": 6.5, "elapsed_s": 14.2}
  ],
  "radar": "ok"
}
''';

const eventMessageJson = '''
{"type": "event", "event": {"id": 128, "kind": "camera", "person": "T3+7", "situation": "장시간 체류", "prob": 1.0, "abnormal": true, "photo": true, "t": "2026-11-19T15:03:10+09:00", "started_at": "...", "ended_at": null, "label": null}}
''';

const eventDetailJson = '''
{
  "id": 128,
  "kind": "final",
  "person": "T3+7",
  "t": "2026-11-19T15:03:40+09:00",
  "started_at": "2026-11-19T15:02:17+09:00",
  "ended_at": "2026-11-19T15:03:40+09:00",
  "situation": "장시간 체류",
  "prob": 1.0,
  "abnormal": true,
  "also": [],
  "end_situation": "방문",
  "behaviors": [
    {"situation": "장시간 체류", "prob": 1.0, "source": "progress"},
    {"situation": "방문", "prob": 0.94, "source": "end"}
  ],
  "reason": "이상 행동 우선: 진행 중 장시간 체류 100% → 끝날 때 판정 방문 94% 대신",
  "path": "외곽에서 들어옴(2.4m) → 문으로 사라짐(0.5m)",
  "photo": true,
  "label": null,
  "track": [[0.0, 1.71, 1.66], [0.2, 1.65, 1.61]]
}
''';

const settingsJson = '''
{
  "notify": ["장시간 체류", "배회", "반복 접근"],
  "camera_on": true,
  "camera_prob": 0.6,
  "camera_hold_s": 1.0,
  "region": {"xmin": -2, "xmax": 2, "ymin": 0, "ymax": 3, "fov_deg": 135},
  "device_keep_days": 30
}
''';

// ---- 파이 서버 API 문서(2026-11-19)의 예시 ----

const infoJson = '''
{"name": "doorradar", "host": "rad2pi.local", "version": "0.1.0",
 "model": "situation_trees_real", "model_version": "v5",
 "region": {"xmin": -2.0, "xmax": 2.0, "ymin": 0.0, "ymax": 3.0, "fov_deg": 135.0}}
''';

const statusJson = '''
{"radar": "ok", "radar_host": "192.168.0.20", "radar_error": null, "frame_rate": 10.0,
 "camera": "ok", "camera_backend": "helper",
 "latency_s": 0.12, "judge_error": null, "cpu_temp_c": 52.3, "uptime_s": 3600,
 "storage": {"used_gb": 6.1, "total_gb": 29.0, "photos": 38},
 "pending_photos": 0}
''';

void main() {
  group('SPEC 예시 JSON 왕복', () {
    test('실시간 프레임', () {
      final src = jsonDecode(frameJson) as Map<String, dynamic>;
      final frame = LiveFrame.fromJson(src);
      expect(frame.people.single.id, 'T3+7');
      expect(frame.people.single.stillS, 6.5);
      expect(frame.radarOk, isTrue);
      expect(roundTrip(frame.toJson()), src);
    });

    test('사람이 없으면 people: []', () {
      final frame = LiveFrame.fromJson({'type': 'frame', 't': '2026-11-19T15:02:31.600+09:00', 'people': [], 'radar': 'ok'});
      expect(frame.people, isEmpty);
    });

    test('이벤트 상세 (final)', () {
      final src = jsonDecode(eventDetailJson) as Map<String, dynamic>;
      final ev = Event.fromJson(src);
      expect(ev.kind, EventKind.finalResult);
      expect(ev.behaviors, hasLength(2));
      expect(ev.track!.first, [0.0, 1.71, 1.66]);
      expect(ev.hasDetail, isTrue);
      expect(ev.time, DateTime.parse('2026-11-19T06:03:40Z'));
      expect(roundTrip(ev.toJson()), src);
    });

    test('새 이벤트 알림 (camera, 끝난 뒤 필드 없음)', () {
      final msg = LiveMessage.tryParse(eventMessageJson);
      expect(msg, isA<LiveEventMessage>());
      final ev = (msg! as LiveEventMessage).event;
      expect(ev.kind, EventKind.camera);
      expect(ev.endedAt, isNull);
      expect(ev.endSituation, isNull);
      expect(ev.track, isNull);
      expect(ev.hasDetail, isFalse);
      expect(Event.fromJson(roundTrip(ev.toJson())), ev);

      // 원본에 있던 키는 값까지 그대로 나온다 (없던 키는 null 로 더해짐)
      final src = (jsonDecode(eventMessageJson) as Map<String, dynamic>)['event'] as Map<String, dynamic>;
      final out = roundTrip(ev.toJson());
      for (final key in src.keys) {
        expect(out[key], src[key], reason: key);
      }
    });

    test('목록 형식 (track·behaviors 없음)', () {
      final src = jsonDecode(eventDetailJson) as Map<String, dynamic>
        ..remove('track')
        ..remove('behaviors');
      final ev = Event.fromJson(src);
      expect(ev.track, isNull);
      expect(ev.behaviors, isNull);
      expect(ev.endSituation, '방문');
    });

    test('설정', () {
      final src = jsonDecode(settingsJson) as Map<String, dynamic>;
      final s = PiSettings.fromJson(src);
      expect(s.notify, ['장시간 체류', '배회', '반복 접근']);
      expect(s.region.fovDeg, 135);
      expect(s.deviceKeepDays, 30);
      expect(roundTrip(s.toJson()), src);
    });

    test('기기 정보 /api/info', () {
      final src = jsonDecode(infoJson) as Map<String, dynamic>;
      final info = DeviceInfo.fromJson(src);
      expect(info.name, 'doorradar');
      expect(roundTrip(info.toJson()), src);
    });

    test('기기 상태 /api/status', () {
      final src = jsonDecode(statusJson) as Map<String, dynamic>;
      final st = DeviceStatus.fromJson(src);
      expect(st.radarOk, isTrue);
      expect(st.storage.freeGb, closeTo(22.9, 1e-9));
      expect(st.cameraBackend, 'helper');
      expect(st.pendingPhotos, 0);
      expect(roundTrip(st.toJson()), src);
    });
  });

  group('LiveMessage.tryParse', () {
    test('frame', () {
      expect(LiveMessage.tryParse(frameJson), isA<LiveFrameMessage>());
    });

    test('모르는 type 이나 깨진 JSON 은 null', () {
      expect(LiveMessage.tryParse('{"type": "ping"}'), isNull);
      expect(LiveMessage.tryParse('not json'), isNull);
      expect(LiveMessage.tryParse('{"type": "frame"}'), isNull);
    });
  });
}
