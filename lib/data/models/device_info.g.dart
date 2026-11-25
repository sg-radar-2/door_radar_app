// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => _DeviceInfo(
  name: json['name'] as String,
  host: json['host'] as String?,
  version: json['version'] as String,
  model: json['model'] as String,
  modelVersion: json['model_version'] as String?,
  region: Region.fromJson(json['region'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DeviceInfoToJson(_DeviceInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'host': instance.host,
      'version': instance.version,
      'model': instance.model,
      'model_version': instance.modelVersion,
      'region': instance.region.toJson(),
    };
