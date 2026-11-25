// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceStatus _$DeviceStatusFromJson(Map<String, dynamic> json) =>
    _DeviceStatus(
      radar: json['radar'] as String,
      camera: json['camera'] as String,
      frameRate: (json['frame_rate'] as num).toDouble(),
      latencyS: (json['latency_s'] as num?)?.toDouble(),
      cpuTempC: (json['cpu_temp_c'] as num?)?.toDouble(),
      uptimeS: (json['uptime_s'] as num?)?.toInt(),
      storage: StorageInfo.fromJson(json['storage'] as Map<String, dynamic>),
      radarHost: json['radar_host'] as String?,
      radarError: json['radar_error'] as String?,
      cameraBackend: json['camera_backend'] as String?,
      judgeError: json['judge_error'] as String?,
      pendingPhotos: (json['pending_photos'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DeviceStatusToJson(_DeviceStatus instance) =>
    <String, dynamic>{
      'radar': instance.radar,
      'camera': instance.camera,
      'frame_rate': instance.frameRate,
      'latency_s': instance.latencyS,
      'cpu_temp_c': instance.cpuTempC,
      'uptime_s': instance.uptimeS,
      'storage': instance.storage.toJson(),
      'radar_host': instance.radarHost,
      'radar_error': instance.radarError,
      'camera_backend': instance.cameraBackend,
      'judge_error': instance.judgeError,
      'pending_photos': instance.pendingPhotos,
    };

_StorageInfo _$StorageInfoFromJson(Map<String, dynamic> json) => _StorageInfo(
  usedGb: (json['used_gb'] as num).toDouble(),
  totalGb: (json['total_gb'] as num).toDouble(),
  photos: (json['photos'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$StorageInfoToJson(_StorageInfo instance) =>
    <String, dynamic>{
      'used_gb': instance.usedGb,
      'total_gb': instance.totalGb,
      'photos': instance.photos,
    };
