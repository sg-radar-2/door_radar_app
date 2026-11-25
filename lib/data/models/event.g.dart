// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Event _$EventFromJson(Map<String, dynamic> json) => _Event(
  id: (json['id'] as num).toInt(),
  kind: $enumDecode(_$EventKindEnumMap, json['kind']),
  person: json['person'] as String,
  t: json['t'] as String,
  startedAt: json['started_at'] as String,
  endedAt: json['ended_at'] as String?,
  situation: json['situation'] as String,
  prob: (json['prob'] as num).toDouble(),
  abnormal: json['abnormal'] as bool,
  endSituation: json['end_situation'] as String?,
  also: (json['also'] as List<dynamic>?)?.map((e) => e as String).toList(),
  behaviors: (json['behaviors'] as List<dynamic>?)
      ?.map((e) => Behavior.fromJson(e as Map<String, dynamic>))
      .toList(),
  reason: json['reason'] as String?,
  path: json['path'] as String?,
  photo: json['photo'] as bool? ?? false,
  label: json['label'] as String?,
  track: (json['track'] as List<dynamic>?)
      ?.map(
        (e) => (e as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      )
      .toList(),
);

Map<String, dynamic> _$EventToJson(_Event instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$EventKindEnumMap[instance.kind]!,
  'person': instance.person,
  't': instance.t,
  'started_at': instance.startedAt,
  'ended_at': instance.endedAt,
  'situation': instance.situation,
  'prob': instance.prob,
  'abnormal': instance.abnormal,
  'end_situation': instance.endSituation,
  'also': instance.also,
  'behaviors': instance.behaviors?.map((e) => e.toJson()).toList(),
  'reason': instance.reason,
  'path': instance.path,
  'photo': instance.photo,
  'label': instance.label,
  'track': instance.track,
};

const _$EventKindEnumMap = {
  EventKind.camera: 'camera',
  EventKind.finalResult: 'final',
};

_Behavior _$BehaviorFromJson(Map<String, dynamic> json) => _Behavior(
  situation: json['situation'] as String,
  prob: (json['prob'] as num).toDouble(),
  source: json['source'] as String,
);

Map<String, dynamic> _$BehaviorToJson(_Behavior instance) => <String, dynamic>{
  'situation': instance.situation,
  'prob': instance.prob,
  'source': instance.source,
};
