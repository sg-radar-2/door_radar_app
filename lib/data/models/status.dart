import 'package:freezed_annotation/freezed_annotation.dart';

part 'status.freezed.dart';
part 'status.g.dart';

/// `/api/status`: 레이더·카메라 연결, 프레임 수신율, 저장 공간.
/// SPEC 에 예시 JSON 이 없어 mock_server 형식 + SPEC 8장 추가 필드. 상태 문자열은 "ok" 이면 정상.
/// `radar`: ok | connecting | disconnected | stale(2초 넘게 프레임 없음)
@freezed
abstract class DeviceStatus with _$DeviceStatus {
  const DeviceStatus._();

  const factory DeviceStatus({
    required String radar,
    required String camera,
    required double frameRate,
    double? latencyS,
    double? cpuTempC,
    int? uptimeS,
    required StorageInfo storage,

    // SPEC 8장 (실제 파이 서버). mock 에는 없을 수 있다.
    String? radarHost,
    String? radarError,
    String? cameraBackend,
    String? judgeError,
    int? pendingPhotos,

    // 클라우드에서만 (SPEC 9.1): "online" | "offline"
    @JsonKey(includeIfNull: false) String? pi,
  }) = _DeviceStatus;

  factory DeviceStatus.fromJson(Map<String, Object?> json) => _$DeviceStatusFromJson(json);

  bool get radarOk => radar == 'ok';
  bool get cameraOk => camera == 'ok';
  bool get piOffline => pi == 'offline';
}

@freezed
abstract class StorageInfo with _$StorageInfo {
  const StorageInfo._();

  const factory StorageInfo({
    required double usedGb,
    required double totalGb,
    @Default(0) int photos,
  }) = _StorageInfo;

  factory StorageInfo.fromJson(Map<String, Object?> json) => _$StorageInfoFromJson(json);

  double get freeGb => totalGb - usedGb;
}
