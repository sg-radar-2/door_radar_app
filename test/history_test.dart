import 'package:door_radar_app/data/local_store.dart';
import 'package:door_radar_app/data/models/models.dart';
import 'package:door_radar_app/features/events/event_detail_screen.dart';
import 'package:door_radar_app/features/events/events_screen.dart';
import 'package:door_radar_app/state/events.dart';
import 'package:flutter_test/flutter_test.dart';

Event ev(int id,
        {String kind = 'final',
        String situation = '방문',
        bool abnormal = false,
        bool photo = false,
        String started = '2026-11-19T15:02:17+09:00',
        String? ended = '2026-11-19T15:03:40+09:00',
        String? path}) =>
    Event.fromJson({
      'id': id, 'kind': kind, 'person': 'T1', 't': ended ?? '2026-11-19T15:03:10+09:00', 'started_at': started,
      'ended_at': ended, 'situation': situation, 'prob': 0.94, 'abnormal': abnormal, 'photo': photo, 'path': path,
    });

void main() {
  test('기록 목록: 최종 판정이 나온 사람의 촬영 이벤트는 숨기고, 진행 중인 건 남긴다', () {
    final rows = historyRows([
      StoredEvent(ev(2, situation: '장시간 체류', abnormal: true, photo: true)),
      StoredEvent(ev(1, kind: 'camera', situation: '장시간 체류', abnormal: true, photo: true, ended: null)),
      StoredEvent(ev(3, kind: 'camera', abnormal: true, photo: true, started: '2026-11-19T16:00:00+09:00', ended: null)),
      StoredEvent(ev(4, started: '2026-11-19T14:41:00+09:00', ended: '2026-11-19T14:41:25+09:00')),
    ]);
    expect(rows.map((s) => s.event.id), [2, 3, 4]);

    final s = summarize(rows);
    expect((s.total, s.abnormal, s.photos), (3, 2, 2));
  });

  test('목록 메타 문구 (와이어프레임: "1분 23초 · 촬영", "외곽으로 나감" 류)', () {
    expect(eventMeta(ev(1, situation: '장시간 체류', abnormal: true, photo: true)), '1분 23초 · 촬영');
    expect(eventMeta(ev(2, path: '외곽에서 들어옴(2.7m) → 문으로 사라짐(0.4m)')), '문으로 사라짐');
    expect(eventMeta(ev(3, kind: 'camera', abnormal: true, photo: true, ended: null)), '진행 중 · 촬영');
    expect(pathEnd('왼쪽 외곽 → 오른쪽 외곽'), '오른쪽 외곽');
  });

  test('나온 행동: 이상 먼저, 끝날 때 판정 표시', () {
    final list = sortBehaviors(const [
      Behavior(situation: '방문', prob: 0.94, source: 'end'),
      Behavior(situation: '장시간 체류', prob: 1.0, source: 'progress'),
    ]);
    expect(list.map(behaviorLabel), ['장시간 체류 100%', '방문 94% · 끝날 때']);
  });

  test('isLocal: 폰 시간대 오프셋을 붙인 ISO (since= 용)', () {
    final t = DateTime(2026, 11, 19);
    final s = isoLocal(t);
    expect(s, startsWith('2026-11-19T00:00:00.000'));
    expect(RegExp(r'[+-]\d\d:\d\d$').hasMatch(s), isTrue);
    expect(DateTime.parse(s).isAtSameMomentAs(t), isTrue);
  });
}
