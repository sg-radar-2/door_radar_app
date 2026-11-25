import 'package:freezed_annotation/freezed_annotation.dart';

part 'region.freezed.dart';
part 'region.g.dart';

/// 측정 영역 (레이더 기준 m). `/api/info`, `/api/settings` 의 `region`.
@freezed
abstract class Region with _$Region {
  const factory Region({
    required double xmin,
    required double xmax,
    required double ymin,
    required double ymax,
    required double fovDeg,
  }) = _Region;

  factory Region.fromJson(Map<String, Object?> json) => _$RegionFromJson(json);
}
