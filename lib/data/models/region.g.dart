// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'region.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Region _$RegionFromJson(Map<String, dynamic> json) => _Region(
  xmin: (json['xmin'] as num).toDouble(),
  xmax: (json['xmax'] as num).toDouble(),
  ymin: (json['ymin'] as num).toDouble(),
  ymax: (json['ymax'] as num).toDouble(),
  fovDeg: (json['fov_deg'] as num).toDouble(),
);

Map<String, dynamic> _$RegionToJson(_Region instance) => <String, dynamic>{
  'xmin': instance.xmin,
  'xmax': instance.xmax,
  'ymin': instance.ymin,
  'ymax': instance.ymax,
  'fov_deg': instance.fovDeg,
};
