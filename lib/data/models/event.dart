import 'package:freezed_annotation/freezed_annotation.dart';

part 'event.freezed.dart';
part 'event.g.dart';

enum EventKind {
  /// 진행 중 이상 상황으로 촬영 (`ended_at`·`end_situation`·`reason`·`path`·`track` 없음)
  @JsonValue('camera')
  camera,

  /// 사람이 사라져서 나온 최종 판정
  @JsonValue('final')
  finalResult,
}

/// 이벤트. 목록(`/api/events`)과 상세(`/api/events/{id}`) 겸용.
/// 목록에는 `track`·`behaviors` 가 없고, camera 이벤트에는 끝난 뒤에 생기는 필드가 없어서 nullable.
/// 시각은 서버가 준 ISO 문자열 그대로 둔다(`+09:00` 을 잃지 않고 `since=` 에 그대로 쓰기 위해). DateTime 은 getter 로.
@freezed
abstract class Event with _$Event {
  const Event._();

  const factory Event({
    required int id,
    required EventKind kind,
    required String person,
    required String t,
    required String startedAt,
    String? endedAt,
    required String situation,
    required double prob,
    required bool abnormal,
    String? endSituation,

    /// final: 최종 판정과 같은 확률로 동점인 다른 이상 행동 (보통 빈 배열). 나온 행동(`behaviors`)에도 들어 있다.
    List<String>? also,
    List<Behavior>? behaviors,
    String? reason,
    String? path,
    @Default(false) bool photo,
    String? label,

    /// `[시작부터 초, x, y]`, 0.2초 간격
    List<List<double>>? track,
  }) = _Event;

  factory Event.fromJson(Map<String, Object?> json) => _$EventFromJson(json);

  DateTime get time => DateTime.parse(t);
  DateTime get startedTime => DateTime.parse(startedAt);
  DateTime? get endedTime => endedAt == null ? null : DateTime.parse(endedAt!);

  /// 상세(`/api/events/{id}`)로 받은 것인지
  bool get hasDetail => track != null || behaviors != null;
}

/// 이벤트 동안 나온 행동. `source`: "progress"(진행 중) / "end"(끝날 때 판정)
@freezed
abstract class Behavior with _$Behavior {
  const factory Behavior({
    required String situation,
    required double prob,
    required String source,
  }) = _Behavior;

  factory Behavior.fromJson(Map<String, Object?> json) => _$BehaviorFromJson(json);
}
