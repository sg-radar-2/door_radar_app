// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frame.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveFrame _$LiveFrameFromJson(Map<String, dynamic> json) => _LiveFrame(
  type: json['type'] as String? ?? 'frame',
  t: json['t'] as String,
  people:
      (json['people'] as List<dynamic>?)
          ?.map((e) => LivePerson.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <LivePerson>[],
  radar: json['radar'] as String,
  pi: json['pi'] as String?,
);

Map<String, dynamic> _$LiveFrameToJson(_LiveFrame instance) =>
    <String, dynamic>{
      'type': instance.type,
      't': instance.t,
      'people': instance.people.map((e) => e.toJson()).toList(),
      'radar': instance.radar,
      'pi': ?instance.pi,
    };

_LivePerson _$LivePersonFromJson(Map<String, dynamic> json) => _LivePerson(
  id: json['id'] as String,
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  hidden: json['hidden'] as bool? ?? false,
  situation: json['situation'] as String,
  prob: (json['prob'] as num).toDouble(),
  abnormal: json['abnormal'] as bool,
  stillS: (json['still_s'] as num?)?.toDouble() ?? 0,
  elapsedS: (json['elapsed_s'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$LivePersonToJson(_LivePerson instance) =>
    <String, dynamic>{
      'id': instance.id,
      'x': instance.x,
      'y': instance.y,
      'hidden': instance.hidden,
      'situation': instance.situation,
      'prob': instance.prob,
      'abnormal': instance.abnormal,
      'still_s': instance.stillS,
      'elapsed_s': instance.elapsedS,
    };
