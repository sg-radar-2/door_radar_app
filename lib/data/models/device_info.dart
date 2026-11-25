import 'package:freezed_annotation/freezed_annotation.dart';

import 'region.dart';

part 'device_info.freezed.dart';
part 'device_info.g.dart';

/// `/api/info` (인증 없음). 연결 확인용: 기기 이름, 버전, 측정 영역, 모델 이름.
/// SPEC 에 예시 JSON 이 없어 mock_server 형식을 따른다. `host`, `model_version` 은 없을 수도 있다.
@freezed
abstract class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    required String name,
    String? host,
    required String version,
    required String model,
    String? modelVersion,
    required Region region,
  }) = _DeviceInfo;

  factory DeviceInfo.fromJson(Map<String, Object?> json) => _$DeviceInfoFromJson(json);
}
