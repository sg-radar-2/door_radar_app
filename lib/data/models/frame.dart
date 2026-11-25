import 'package:freezed_annotation/freezed_annotation.dart';

part 'frame.freezed.dart';
part 'frame.g.dart';

/// `/ws/live` 실시간 프레임 (초당 5번). 사람이 없으면 `people: []`.
@freezed
abstract class LiveFrame with _$LiveFrame {
  const LiveFrame._();

  const factory LiveFrame({
    @Default('frame') String type,
    required String t,
    @Default(<LivePerson>[]) List<LivePerson> people,
    required String radar, // "ok" 이면 레이더 정상

    /// 클라우드에서만 (SPEC 9.1): "online" | "offline". 파이가 클라우드에 안 붙어 있으면 offline.
    @JsonKey(includeIfNull: false) String? pi,
  }) = _LiveFrame;

  factory LiveFrame.fromJson(Map<String, Object?> json) => _$LiveFrameFromJson(json);

  bool get radarOk => radar == 'ok';
}

/// 프레임 속 한 사람. `id` 는 문자열 (레이더 타깃 여러 개를 묶으면 "T3+7").
@freezed
abstract class LivePerson with _$LivePerson {
  const factory LivePerson({
    required String id,
    required double x,
    required double y,
    @Default(false) bool hidden,
    required String situation,
    required double prob,
    required bool abnormal,
    @Default(0) double stillS,
    @Default(0) double elapsedS,
  }) = _LivePerson;

  factory LivePerson.fromJson(Map<String, Object?> json) => _$LivePersonFromJson(json);
}
