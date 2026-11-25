import 'package:door_radar_app/data/models/models.dart';
import 'package:door_radar_app/state/events.dart';
import 'package:door_radar_app/state/live.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

LiveFrame frame(String t, List<Map<String, Object?>> people) => LiveFrame.fromJson(frameJson(t, people));

String at(double s) {
  final base = DateTime.utc(2026, 11, 19, 6, 2, 31);
  return base.add(Duration(milliseconds: (s * 1000).round())).toIso8601String();
}

void main() {
  group('applyFrame: 사람별 최근 5초 궤적', () {
    test('궤적이 쌓이고 5초보다 오래된 점은 버린다', () {
      var s = const LiveState();
      for (var i = 0; i <= 35; i++) {
        s = applyFrame(s, frame(at(i * 0.2), [personJson('T1', i * 0.01, 1)]));
      }
      final p = s.people.single;
      // 7.0초 시점, 2.0초 이후 점만 = 26개
      expect(p.trail.first.t, DateTime.parse(at(2.0)));
      expect(p.trail.length, 26);
      expect(p.trail.last.x, closeTo(0.35, 1e-9));
      expect(p.firstX, 0); // 처음 보인 위치는 남는다
      expect(s.frameCount, 36);
    });

    test('프레임에서 빠진 사람은 지운다, 새 사람은 궤적 1점', () {
      var s = applyFrame(const LiveState(), frame(at(0), [personJson('T1', 0, 1)]));
      s = applyFrame(s, frame(at(0.2), [personJson('T2', 1, 2)]));
      expect(s.people.map((p) => p.id), ['T2']);
      expect(s.people.single.trail.length, 1);
    });

    test('가려진(hidden) 사람은 궤적을 늘리지 않는다', () {
      var s = applyFrame(const LiveState(), frame(at(0), [personJson('T1', 0, 1)]));
      s = applyFrame(s, frame(at(0.2), [
        {...personJson('T1', 0.5, 1.5), 'hidden': true},
      ]));
      expect(s.people.single.trail.length, 1);
      expect(s.people.single.person.hidden, isTrue);
    });

    test('radar, t 를 기억한다', () {
      final s = applyFrame(const LiveState(), LiveFrame.fromJson(frameJson(at(0), [], radar: 'stale')));
      expect(s.radar, 'stale');
      expect(s.radarOk, isFalse);
      expect(s.frameT, at(0));
    });
  });

  test('카드 순서: 이상 먼저, 그다음 가까운 사람', () {
    var s = applyFrame(const LiveState(), frame(at(0), [
      personJson('far', 0, 2.5),
      personJson('near', 0.3, 0.4),
      personJson('bad-far', 1.5, 2.5, situation: '배회', abnormal: true),
      personJson('bad-near', 0.5, 1.0, situation: '장시간 체류', abnormal: true),
    ]));
    expect(cardOrder(s.people).map((p) => p.id), ['bad-near', 'bad-far', 'near', 'far']);
  });

  test('같은 사람: id 조각이 겹치면 (T3 → T3+7)', () {
    expect(samePerson('T3', 'T3+7'), isTrue);
    expect(samePerson('T3+7', 'T7'), isTrue);
    expect(samePerson('T3', 'T30'), isFalse);
  });

  test('나타난 곳', () {
    expect(appearedFrom(0.2, 0.5), '문 쪽');
    expect(appearedFrom(1.8, 2.6), '외곽');
  });

  test('시간·라벨 문구', () {
    expect(formatSeconds(6.5), '6.5초');
    expect(formatSeconds(6.0), '6초');
    expect(formatSeconds(36.4), '36초');
    expect(formatSeconds(72), '1분 12초');
    expect(formatSeconds(120), '2분');

    LivePerson p(Map<String, Object?> j) => LivePerson.fromJson(j);
    expect(personLabel(p(personJson('T1', 0, 1, situation: '방문', prob: 0.82))), '방문 82%');
    expect(personLabel(p(personJson('T1', 0, 1, situation: '판단 중', prob: 0))), '판단 중');
    expect(personLabel(p(personJson('T1', 0, 1, situation: '장시간 체류', prob: 1, abnormal: true, still: 36.2))),
        '장시간 체류 · 36초');
    expect(personLabel(p(personJson('T1', 0, 1, situation: '배회', prob: 1, abnormal: true, elapsed: 50))),
        '배회 · 50초');
  });

  group('이벤트', () {
    Event ev(int id, String t, {String kind = 'final', String situation = '방문', bool abnormal = false}) =>
        Event.fromJson({
          'id': id, 'kind': kind, 'person': 'T1', 't': t, 'started_at': t, 'situation': situation,
          'prob': 1.0, 'abnormal': abnormal,
        });

    test('upsertEvent: 같은 id 는 덮어쓰고 최신순으로 limit 개', () {
      var list = [ev(1, at(0)), ev(2, at(10))];
      list = upsertEvent(list, ev(3, at(20)), limit: 2);
      expect(list.map((e) => e.id), [3, 2]);
      list = upsertEvent(list, ev(2, at(30), situation: '배달'), limit: 2);
      expect(list.map((e) => e.id), [2, 3]);
      expect(list.first.situation, '배달');
    });

    test('shouldAlert: notify 목록의 이상 camera 이벤트만', () {
      const notify = ['장시간 체류', '반복 접근'];
      expect(shouldAlert(ev(1, at(0), kind: 'camera', situation: '장시간 체류', abnormal: true), notify), isTrue);
      expect(shouldAlert(ev(1, at(0), kind: 'camera', situation: '배회', abnormal: true), notify), isFalse);
      expect(shouldAlert(ev(1, at(0), kind: 'final', situation: '장시간 체류', abnormal: true), notify), isFalse);
      expect(shouldAlert(ev(1, at(0), kind: 'camera', situation: '방문'), ['방문']), isFalse);
    });
  });
}
