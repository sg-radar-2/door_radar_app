// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PiSettings _$PiSettingsFromJson(Map<String, dynamic> json) => _PiSettings(
  notify:
      (json['notify'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  cameraOn: json['camera_on'] as bool,
  cameraProb: (json['camera_prob'] as num).toDouble(),
  cameraHoldS: (json['camera_hold_s'] as num).toDouble(),
  region: Region.fromJson(json['region'] as Map<String, dynamic>),
  deviceKeepDays: (json['device_keep_days'] as num?)?.toInt() ?? 30,
);

Map<String, dynamic> _$PiSettingsToJson(_PiSettings instance) =>
    <String, dynamic>{
      'notify': instance.notify,
      'camera_on': instance.cameraOn,
      'camera_prob': instance.cameraProb,
      'camera_hold_s': instance.cameraHoldS,
      'region': instance.region.toJson(),
      'device_keep_days': instance.deviceKeepDays,
    };
