// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PiSettings {

 List<String> get notify; bool get cameraOn; double get cameraProb; double get cameraHoldS; Region get region; int get deviceKeepDays;
/// Create a copy of PiSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PiSettingsCopyWith<PiSettings> get copyWith => _$PiSettingsCopyWithImpl<PiSettings>(this as PiSettings, _$identity);

  /// Serializes this PiSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PiSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PiSettings&&const DeepCollectionEquality().equals(other.notify, _this.notify)&&(identical(other.cameraOn, _this.cameraOn) || other.cameraOn == _this.cameraOn)&&(identical(other.cameraProb, _this.cameraProb) || other.cameraProb == _this.cameraProb)&&(identical(other.cameraHoldS, _this.cameraHoldS) || other.cameraHoldS == _this.cameraHoldS)&&(identical(other.region, _this.region) || other.region == _this.region)&&(identical(other.deviceKeepDays, _this.deviceKeepDays) || other.deviceKeepDays == _this.deviceKeepDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PiSettings;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.notify),_this.cameraOn,_this.cameraProb,_this.cameraHoldS,_this.region,_this.deviceKeepDays);
}

@override
String toString() {
  final _this = this as PiSettings;
  return 'PiSettings(notify: ${_this.notify}, cameraOn: ${_this.cameraOn}, cameraProb: ${_this.cameraProb}, cameraHoldS: ${_this.cameraHoldS}, region: ${_this.region}, deviceKeepDays: ${_this.deviceKeepDays})';
}


}

/// @nodoc
abstract mixin class $PiSettingsCopyWith<$Res>  {
  factory $PiSettingsCopyWith(PiSettings value, $Res Function(PiSettings) _then) = _$PiSettingsCopyWithImpl;
@useResult
$Res call({
 List<String> notify, bool cameraOn, double cameraProb, double cameraHoldS, Region region, int deviceKeepDays
});


$RegionCopyWith<$Res> get region;

}
/// @nodoc
class _$PiSettingsCopyWithImpl<$Res>
    implements $PiSettingsCopyWith<$Res> {
  _$PiSettingsCopyWithImpl(this._self, this._then);

  final PiSettings _self;
  final $Res Function(PiSettings) _then;

/// Create a copy of PiSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notify = null,Object? cameraOn = null,Object? cameraProb = null,Object? cameraHoldS = null,Object? region = null,Object? deviceKeepDays = null,}) {
  return _then(PiSettings(
notify: null == notify ? _self.notify : notify // ignore: cast_nullable_to_non_nullable
as List<String>,cameraOn: null == cameraOn ? _self.cameraOn : cameraOn // ignore: cast_nullable_to_non_nullable
as bool,cameraProb: null == cameraProb ? _self.cameraProb : cameraProb // ignore: cast_nullable_to_non_nullable
as double,cameraHoldS: null == cameraHoldS ? _self.cameraHoldS : cameraHoldS // ignore: cast_nullable_to_non_nullable
as double,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as Region,deviceKeepDays: null == deviceKeepDays ? _self.deviceKeepDays : deviceKeepDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of PiSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RegionCopyWith<$Res> get region {
  
  return $RegionCopyWith<$Res>(_self.region, (value) {
    return _then(_self.copyWith(region: value));
  });
}
}


/// Adds pattern-matching-related methods to [PiSettings].
extension PiSettingsPatterns on PiSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PiSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PiSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PiSettings value)  $default,){
final _that = this;
switch (_that) {
case _PiSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PiSettings value)?  $default,){
final _that = this;
switch (_that) {
case _PiSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> notify,  bool cameraOn,  double cameraProb,  double cameraHoldS,  Region region,  int deviceKeepDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PiSettings() when $default != null:
return $default(_that.notify,_that.cameraOn,_that.cameraProb,_that.cameraHoldS,_that.region,_that.deviceKeepDays);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> notify,  bool cameraOn,  double cameraProb,  double cameraHoldS,  Region region,  int deviceKeepDays)  $default,) {final _that = this;
switch (_that) {
case _PiSettings():
return $default(_that.notify,_that.cameraOn,_that.cameraProb,_that.cameraHoldS,_that.region,_that.deviceKeepDays);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> notify,  bool cameraOn,  double cameraProb,  double cameraHoldS,  Region region,  int deviceKeepDays)?  $default,) {final _that = this;
switch (_that) {
case _PiSettings() when $default != null:
return $default(_that.notify,_that.cameraOn,_that.cameraProb,_that.cameraHoldS,_that.region,_that.deviceKeepDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PiSettings implements PiSettings {
  const _PiSettings({ List<String> notify = const <String>[], required this.cameraOn, required this.cameraProb, required this.cameraHoldS, required this.region, this.deviceKeepDays = 30}): _notify = notify;
  factory _PiSettings.fromJson(Map<String, dynamic> json) => _$PiSettingsFromJson(json);

 final  List<String> _notify;
@override@JsonKey() List<String> get notify {
  if (_notify is EqualUnmodifiableListView) return _notify;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notify);
}

@override final  bool cameraOn;
@override final  double cameraProb;
@override final  double cameraHoldS;
@override final  Region region;
@override@JsonKey() final  int deviceKeepDays;

/// Create a copy of PiSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PiSettingsCopyWith<_PiSettings> get copyWith => __$PiSettingsCopyWithImpl<_PiSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PiSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PiSettings&&const DeepCollectionEquality().equals(other.notify, _notify)&&(identical(other.cameraOn, cameraOn) || other.cameraOn == cameraOn)&&(identical(other.cameraProb, cameraProb) || other.cameraProb == cameraProb)&&(identical(other.cameraHoldS, cameraHoldS) || other.cameraHoldS == cameraHoldS)&&(identical(other.region, region) || other.region == region)&&(identical(other.deviceKeepDays, deviceKeepDays) || other.deviceKeepDays == deviceKeepDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_notify),cameraOn,cameraProb,cameraHoldS,region,deviceKeepDays);
}

@override
String toString() {
    return 'PiSettings(notify: $notify, cameraOn: $cameraOn, cameraProb: $cameraProb, cameraHoldS: $cameraHoldS, region: $region, deviceKeepDays: $deviceKeepDays)';
}


}

/// @nodoc
abstract mixin class _$PiSettingsCopyWith<$Res> implements $PiSettingsCopyWith<$Res> {
  factory _$PiSettingsCopyWith(_PiSettings value, $Res Function(_PiSettings) _then) = __$PiSettingsCopyWithImpl;
@override @useResult
$Res call({
 List<String> notify, bool cameraOn, double cameraProb, double cameraHoldS, Region region, int deviceKeepDays
});


@override $RegionCopyWith<$Res> get region;

}
/// @nodoc
class __$PiSettingsCopyWithImpl<$Res>
    implements _$PiSettingsCopyWith<$Res> {
  __$PiSettingsCopyWithImpl(this._self, this._then);

  final _PiSettings _self;
  final $Res Function(_PiSettings) _then;

/// Create a copy of PiSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notify = null,Object? cameraOn = null,Object? cameraProb = null,Object? cameraHoldS = null,Object? region = null,Object? deviceKeepDays = null,}) {
  return _then(_PiSettings(
notify: null == notify ? _self._notify : notify // ignore: cast_nullable_to_non_nullable
as List<String>,cameraOn: null == cameraOn ? _self.cameraOn : cameraOn // ignore: cast_nullable_to_non_nullable
as bool,cameraProb: null == cameraProb ? _self.cameraProb : cameraProb // ignore: cast_nullable_to_non_nullable
as double,cameraHoldS: null == cameraHoldS ? _self.cameraHoldS : cameraHoldS // ignore: cast_nullable_to_non_nullable
as double,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as Region,deviceKeepDays: null == deviceKeepDays ? _self.deviceKeepDays : deviceKeepDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of PiSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RegionCopyWith<$Res> get region {
  
  return $RegionCopyWith<$Res>(_self.region, (value) {
    return _then(_self.copyWith(region: value));
  });
}
}

// dart format on
