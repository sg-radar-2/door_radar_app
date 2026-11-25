// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceStatus {

 String get radar; String get camera; double get frameRate; double? get latencyS; double? get cpuTempC; int? get uptimeS; StorageInfo get storage; String? get radarHost; String? get radarError; String? get cameraBackend; String? get judgeError; int? get pendingPhotos;
/// Create a copy of DeviceStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceStatusCopyWith<DeviceStatus> get copyWith => _$DeviceStatusCopyWithImpl<DeviceStatus>(this as DeviceStatus, _$identity);

  /// Serializes this DeviceStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DeviceStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceStatus&&(identical(other.radar, _this.radar) || other.radar == _this.radar)&&(identical(other.camera, _this.camera) || other.camera == _this.camera)&&(identical(other.frameRate, _this.frameRate) || other.frameRate == _this.frameRate)&&(identical(other.latencyS, _this.latencyS) || other.latencyS == _this.latencyS)&&(identical(other.cpuTempC, _this.cpuTempC) || other.cpuTempC == _this.cpuTempC)&&(identical(other.uptimeS, _this.uptimeS) || other.uptimeS == _this.uptimeS)&&(identical(other.storage, _this.storage) || other.storage == _this.storage)&&(identical(other.radarHost, _this.radarHost) || other.radarHost == _this.radarHost)&&(identical(other.radarError, _this.radarError) || other.radarError == _this.radarError)&&(identical(other.cameraBackend, _this.cameraBackend) || other.cameraBackend == _this.cameraBackend)&&(identical(other.judgeError, _this.judgeError) || other.judgeError == _this.judgeError)&&(identical(other.pendingPhotos, _this.pendingPhotos) || other.pendingPhotos == _this.pendingPhotos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DeviceStatus;
  return Object.hash(runtimeType,_this.radar,_this.camera,_this.frameRate,_this.latencyS,_this.cpuTempC,_this.uptimeS,_this.storage,_this.radarHost,_this.radarError,_this.cameraBackend,_this.judgeError,_this.pendingPhotos);
}

@override
String toString() {
  final _this = this as DeviceStatus;
  return 'DeviceStatus(radar: ${_this.radar}, camera: ${_this.camera}, frameRate: ${_this.frameRate}, latencyS: ${_this.latencyS}, cpuTempC: ${_this.cpuTempC}, uptimeS: ${_this.uptimeS}, storage: ${_this.storage}, radarHost: ${_this.radarHost}, radarError: ${_this.radarError}, cameraBackend: ${_this.cameraBackend}, judgeError: ${_this.judgeError}, pendingPhotos: ${_this.pendingPhotos})';
}


}

/// @nodoc
abstract mixin class $DeviceStatusCopyWith<$Res>  {
  factory $DeviceStatusCopyWith(DeviceStatus value, $Res Function(DeviceStatus) _then) = _$DeviceStatusCopyWithImpl;
@useResult
$Res call({
 String radar, String camera, double frameRate, double? latencyS, double? cpuTempC, int? uptimeS, StorageInfo storage, String? radarHost, String? radarError, String? cameraBackend, String? judgeError, int? pendingPhotos
});


$StorageInfoCopyWith<$Res> get storage;

}
/// @nodoc
class _$DeviceStatusCopyWithImpl<$Res>
    implements $DeviceStatusCopyWith<$Res> {
  _$DeviceStatusCopyWithImpl(this._self, this._then);

  final DeviceStatus _self;
  final $Res Function(DeviceStatus) _then;

/// Create a copy of DeviceStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? radar = null,Object? camera = null,Object? frameRate = null,Object? latencyS = freezed,Object? cpuTempC = freezed,Object? uptimeS = freezed,Object? storage = null,Object? radarHost = freezed,Object? radarError = freezed,Object? cameraBackend = freezed,Object? judgeError = freezed,Object? pendingPhotos = freezed,}) {
  return _then(DeviceStatus(
radar: null == radar ? _self.radar : radar // ignore: cast_nullable_to_non_nullable
as String,camera: null == camera ? _self.camera : camera // ignore: cast_nullable_to_non_nullable
as String,frameRate: null == frameRate ? _self.frameRate : frameRate // ignore: cast_nullable_to_non_nullable
as double,latencyS: freezed == latencyS ? _self.latencyS : latencyS // ignore: cast_nullable_to_non_nullable
as double?,cpuTempC: freezed == cpuTempC ? _self.cpuTempC : cpuTempC // ignore: cast_nullable_to_non_nullable
as double?,uptimeS: freezed == uptimeS ? _self.uptimeS : uptimeS // ignore: cast_nullable_to_non_nullable
as int?,storage: null == storage ? _self.storage : storage // ignore: cast_nullable_to_non_nullable
as StorageInfo,radarHost: freezed == radarHost ? _self.radarHost : radarHost // ignore: cast_nullable_to_non_nullable
as String?,radarError: freezed == radarError ? _self.radarError : radarError // ignore: cast_nullable_to_non_nullable
as String?,cameraBackend: freezed == cameraBackend ? _self.cameraBackend : cameraBackend // ignore: cast_nullable_to_non_nullable
as String?,judgeError: freezed == judgeError ? _self.judgeError : judgeError // ignore: cast_nullable_to_non_nullable
as String?,pendingPhotos: freezed == pendingPhotos ? _self.pendingPhotos : pendingPhotos // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of DeviceStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StorageInfoCopyWith<$Res> get storage {
  
  return $StorageInfoCopyWith<$Res>(_self.storage, (value) {
    return _then(_self.copyWith(storage: value));
  });
}
}


/// Adds pattern-matching-related methods to [DeviceStatus].
extension DeviceStatusPatterns on DeviceStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceStatus value)  $default,){
final _that = this;
switch (_that) {
case _DeviceStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceStatus value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String radar,  String camera,  double frameRate,  double? latencyS,  double? cpuTempC,  int? uptimeS,  StorageInfo storage,  String? radarHost,  String? radarError,  String? cameraBackend,  String? judgeError,  int? pendingPhotos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceStatus() when $default != null:
return $default(_that.radar,_that.camera,_that.frameRate,_that.latencyS,_that.cpuTempC,_that.uptimeS,_that.storage,_that.radarHost,_that.radarError,_that.cameraBackend,_that.judgeError,_that.pendingPhotos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String radar,  String camera,  double frameRate,  double? latencyS,  double? cpuTempC,  int? uptimeS,  StorageInfo storage,  String? radarHost,  String? radarError,  String? cameraBackend,  String? judgeError,  int? pendingPhotos)  $default,) {final _that = this;
switch (_that) {
case _DeviceStatus():
return $default(_that.radar,_that.camera,_that.frameRate,_that.latencyS,_that.cpuTempC,_that.uptimeS,_that.storage,_that.radarHost,_that.radarError,_that.cameraBackend,_that.judgeError,_that.pendingPhotos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String radar,  String camera,  double frameRate,  double? latencyS,  double? cpuTempC,  int? uptimeS,  StorageInfo storage,  String? radarHost,  String? radarError,  String? cameraBackend,  String? judgeError,  int? pendingPhotos)?  $default,) {final _that = this;
switch (_that) {
case _DeviceStatus() when $default != null:
return $default(_that.radar,_that.camera,_that.frameRate,_that.latencyS,_that.cpuTempC,_that.uptimeS,_that.storage,_that.radarHost,_that.radarError,_that.cameraBackend,_that.judgeError,_that.pendingPhotos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceStatus extends DeviceStatus {
  const _DeviceStatus({required this.radar, required this.camera, required this.frameRate, this.latencyS, this.cpuTempC, this.uptimeS, required this.storage, this.radarHost, this.radarError, this.cameraBackend, this.judgeError, this.pendingPhotos}): super._();
  factory _DeviceStatus.fromJson(Map<String, dynamic> json) => _$DeviceStatusFromJson(json);

@override final  String radar;
@override final  String camera;
@override final  double frameRate;
@override final  double? latencyS;
@override final  double? cpuTempC;
@override final  int? uptimeS;
@override final  StorageInfo storage;
@override final  String? radarHost;
@override final  String? radarError;
@override final  String? cameraBackend;
@override final  String? judgeError;
@override final  int? pendingPhotos;

/// Create a copy of DeviceStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceStatusCopyWith<_DeviceStatus> get copyWith => __$DeviceStatusCopyWithImpl<_DeviceStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceStatusToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceStatus&&(identical(other.radar, radar) || other.radar == radar)&&(identical(other.camera, camera) || other.camera == camera)&&(identical(other.frameRate, frameRate) || other.frameRate == frameRate)&&(identical(other.latencyS, latencyS) || other.latencyS == latencyS)&&(identical(other.cpuTempC, cpuTempC) || other.cpuTempC == cpuTempC)&&(identical(other.uptimeS, uptimeS) || other.uptimeS == uptimeS)&&(identical(other.storage, storage) || other.storage == storage)&&(identical(other.radarHost, radarHost) || other.radarHost == radarHost)&&(identical(other.radarError, radarError) || other.radarError == radarError)&&(identical(other.cameraBackend, cameraBackend) || other.cameraBackend == cameraBackend)&&(identical(other.judgeError, judgeError) || other.judgeError == judgeError)&&(identical(other.pendingPhotos, pendingPhotos) || other.pendingPhotos == pendingPhotos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,radar,camera,frameRate,latencyS,cpuTempC,uptimeS,storage,radarHost,radarError,cameraBackend,judgeError,pendingPhotos);
}

@override
String toString() {
    return 'DeviceStatus(radar: $radar, camera: $camera, frameRate: $frameRate, latencyS: $latencyS, cpuTempC: $cpuTempC, uptimeS: $uptimeS, storage: $storage, radarHost: $radarHost, radarError: $radarError, cameraBackend: $cameraBackend, judgeError: $judgeError, pendingPhotos: $pendingPhotos)';
}


}

/// @nodoc
abstract mixin class _$DeviceStatusCopyWith<$Res> implements $DeviceStatusCopyWith<$Res> {
  factory _$DeviceStatusCopyWith(_DeviceStatus value, $Res Function(_DeviceStatus) _then) = __$DeviceStatusCopyWithImpl;
@override @useResult
$Res call({
 String radar, String camera, double frameRate, double? latencyS, double? cpuTempC, int? uptimeS, StorageInfo storage, String? radarHost, String? radarError, String? cameraBackend, String? judgeError, int? pendingPhotos
});


@override $StorageInfoCopyWith<$Res> get storage;

}
/// @nodoc
class __$DeviceStatusCopyWithImpl<$Res>
    implements _$DeviceStatusCopyWith<$Res> {
  __$DeviceStatusCopyWithImpl(this._self, this._then);

  final _DeviceStatus _self;
  final $Res Function(_DeviceStatus) _then;

/// Create a copy of DeviceStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? radar = null,Object? camera = null,Object? frameRate = null,Object? latencyS = freezed,Object? cpuTempC = freezed,Object? uptimeS = freezed,Object? storage = null,Object? radarHost = freezed,Object? radarError = freezed,Object? cameraBackend = freezed,Object? judgeError = freezed,Object? pendingPhotos = freezed,}) {
  return _then(_DeviceStatus(
radar: null == radar ? _self.radar : radar // ignore: cast_nullable_to_non_nullable
as String,camera: null == camera ? _self.camera : camera // ignore: cast_nullable_to_non_nullable
as String,frameRate: null == frameRate ? _self.frameRate : frameRate // ignore: cast_nullable_to_non_nullable
as double,latencyS: freezed == latencyS ? _self.latencyS : latencyS // ignore: cast_nullable_to_non_nullable
as double?,cpuTempC: freezed == cpuTempC ? _self.cpuTempC : cpuTempC // ignore: cast_nullable_to_non_nullable
as double?,uptimeS: freezed == uptimeS ? _self.uptimeS : uptimeS // ignore: cast_nullable_to_non_nullable
as int?,storage: null == storage ? _self.storage : storage // ignore: cast_nullable_to_non_nullable
as StorageInfo,radarHost: freezed == radarHost ? _self.radarHost : radarHost // ignore: cast_nullable_to_non_nullable
as String?,radarError: freezed == radarError ? _self.radarError : radarError // ignore: cast_nullable_to_non_nullable
as String?,cameraBackend: freezed == cameraBackend ? _self.cameraBackend : cameraBackend // ignore: cast_nullable_to_non_nullable
as String?,judgeError: freezed == judgeError ? _self.judgeError : judgeError // ignore: cast_nullable_to_non_nullable
as String?,pendingPhotos: freezed == pendingPhotos ? _self.pendingPhotos : pendingPhotos // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of DeviceStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StorageInfoCopyWith<$Res> get storage {
  
  return $StorageInfoCopyWith<$Res>(_self.storage, (value) {
    return _then(_self.copyWith(storage: value));
  });
}
}


/// @nodoc
mixin _$StorageInfo {

 double get usedGb; double get totalGb; int get photos;
/// Create a copy of StorageInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorageInfoCopyWith<StorageInfo> get copyWith => _$StorageInfoCopyWithImpl<StorageInfo>(this as StorageInfo, _$identity);

  /// Serializes this StorageInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StorageInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageInfo&&(identical(other.usedGb, _this.usedGb) || other.usedGb == _this.usedGb)&&(identical(other.totalGb, _this.totalGb) || other.totalGb == _this.totalGb)&&(identical(other.photos, _this.photos) || other.photos == _this.photos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StorageInfo;
  return Object.hash(runtimeType,_this.usedGb,_this.totalGb,_this.photos);
}

@override
String toString() {
  final _this = this as StorageInfo;
  return 'StorageInfo(usedGb: ${_this.usedGb}, totalGb: ${_this.totalGb}, photos: ${_this.photos})';
}


}

/// @nodoc
abstract mixin class $StorageInfoCopyWith<$Res>  {
  factory $StorageInfoCopyWith(StorageInfo value, $Res Function(StorageInfo) _then) = _$StorageInfoCopyWithImpl;
@useResult
$Res call({
 double usedGb, double totalGb, int photos
});




}
/// @nodoc
class _$StorageInfoCopyWithImpl<$Res>
    implements $StorageInfoCopyWith<$Res> {
  _$StorageInfoCopyWithImpl(this._self, this._then);

  final StorageInfo _self;
  final $Res Function(StorageInfo) _then;

/// Create a copy of StorageInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? usedGb = null,Object? totalGb = null,Object? photos = null,}) {
  return _then(StorageInfo(
usedGb: null == usedGb ? _self.usedGb : usedGb // ignore: cast_nullable_to_non_nullable
as double,totalGb: null == totalGb ? _self.totalGb : totalGb // ignore: cast_nullable_to_non_nullable
as double,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StorageInfo].
extension StorageInfoPatterns on StorageInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StorageInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StorageInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StorageInfo value)  $default,){
final _that = this;
switch (_that) {
case _StorageInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StorageInfo value)?  $default,){
final _that = this;
switch (_that) {
case _StorageInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double usedGb,  double totalGb,  int photos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StorageInfo() when $default != null:
return $default(_that.usedGb,_that.totalGb,_that.photos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double usedGb,  double totalGb,  int photos)  $default,) {final _that = this;
switch (_that) {
case _StorageInfo():
return $default(_that.usedGb,_that.totalGb,_that.photos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double usedGb,  double totalGb,  int photos)?  $default,) {final _that = this;
switch (_that) {
case _StorageInfo() when $default != null:
return $default(_that.usedGb,_that.totalGb,_that.photos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StorageInfo extends StorageInfo {
  const _StorageInfo({required this.usedGb, required this.totalGb, this.photos = 0}): super._();
  factory _StorageInfo.fromJson(Map<String, dynamic> json) => _$StorageInfoFromJson(json);

@override final  double usedGb;
@override final  double totalGb;
@override@JsonKey() final  int photos;

/// Create a copy of StorageInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StorageInfoCopyWith<_StorageInfo> get copyWith => __$StorageInfoCopyWithImpl<_StorageInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StorageInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StorageInfo&&(identical(other.usedGb, usedGb) || other.usedGb == usedGb)&&(identical(other.totalGb, totalGb) || other.totalGb == totalGb)&&(identical(other.photos, photos) || other.photos == photos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,usedGb,totalGb,photos);
}

@override
String toString() {
    return 'StorageInfo(usedGb: $usedGb, totalGb: $totalGb, photos: $photos)';
}


}

/// @nodoc
abstract mixin class _$StorageInfoCopyWith<$Res> implements $StorageInfoCopyWith<$Res> {
  factory _$StorageInfoCopyWith(_StorageInfo value, $Res Function(_StorageInfo) _then) = __$StorageInfoCopyWithImpl;
@override @useResult
$Res call({
 double usedGb, double totalGb, int photos
});




}
/// @nodoc
class __$StorageInfoCopyWithImpl<$Res>
    implements _$StorageInfoCopyWith<$Res> {
  __$StorageInfoCopyWithImpl(this._self, this._then);

  final _StorageInfo _self;
  final $Res Function(_StorageInfo) _then;

/// Create a copy of StorageInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? usedGb = null,Object? totalGb = null,Object? photos = null,}) {
  return _then(_StorageInfo(
usedGb: null == usedGb ? _self.usedGb : usedGb // ignore: cast_nullable_to_non_nullable
as double,totalGb: null == totalGb ? _self.totalGb : totalGb // ignore: cast_nullable_to_non_nullable
as double,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
