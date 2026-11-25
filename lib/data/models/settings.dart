import 'package:freezed_annotation/freezed_annotation.dart';

import 'region.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

/// 파이 설정 (`/api/settings`). `region`, `device_keep_days` 는 읽기 전용.
/// 휴대폰 보관 기간은 여기 없다 — 앱에만 저장한다(SPEC 6장).
@freezed
abstract class PiSettings with _$PiSettings {
  const factory PiSettings({
    @Default(<String>[]) List<String> notify,
    required bool cameraOn,
    required double cameraProb,
    required double cameraHoldS,
    required Region region,
    @Default(30) int deviceKeepDays,
  }) = _PiSettings;

  factory PiSettings.fromJson(Map<String, Object?> json) => _$PiSettingsFromJson(json);
}
