// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'region.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Region {

 double get xmin; double get xmax; double get ymin; double get ymax; double get fovDeg;
/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegionCopyWith<Region> get copyWith => _$RegionCopyWithImpl<Region>(this as Region, _$identity);

  /// Serializes this Region to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Region;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Region&&(identical(other.xmin, _this.xmin) || other.xmin == _this.xmin)&&(identical(other.xmax, _this.xmax) || other.xmax == _this.xmax)&&(identical(other.ymin, _this.ymin) || other.ymin == _this.ymin)&&(identical(other.ymax, _this.ymax) || other.ymax == _this.ymax)&&(identical(other.fovDeg, _this.fovDeg) || other.fovDeg == _this.fovDeg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Region;
  return Object.hash(runtimeType,_this.xmin,_this.xmax,_this.ymin,_this.ymax,_this.fovDeg);
}

@override
String toString() {
  final _this = this as Region;
  return 'Region(xmin: ${_this.xmin}, xmax: ${_this.xmax}, ymin: ${_this.ymin}, ymax: ${_this.ymax}, fovDeg: ${_this.fovDeg})';
}


}

/// @nodoc
abstract mixin class $RegionCopyWith<$Res>  {
  factory $RegionCopyWith(Region value, $Res Function(Region) _then) = _$RegionCopyWithImpl;
@useResult
$Res call({
 double xmin, double xmax, double ymin, double ymax, double fovDeg
});




}
/// @nodoc
class _$RegionCopyWithImpl<$Res>
    implements $RegionCopyWith<$Res> {
  _$RegionCopyWithImpl(this._self, this._then);

  final Region _self;
  final $Res Function(Region) _then;

/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? xmin = null,Object? xmax = null,Object? ymin = null,Object? ymax = null,Object? fovDeg = null,}) {
  return _then(Region(
xmin: null == xmin ? _self.xmin : xmin // ignore: cast_nullable_to_non_nullable
as double,xmax: null == xmax ? _self.xmax : xmax // ignore: cast_nullable_to_non_nullable
as double,ymin: null == ymin ? _self.ymin : ymin // ignore: cast_nullable_to_non_nullable
as double,ymax: null == ymax ? _self.ymax : ymax // ignore: cast_nullable_to_non_nullable
as double,fovDeg: null == fovDeg ? _self.fovDeg : fovDeg // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Region].
extension RegionPatterns on Region {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Region value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Region() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Region value)  $default,){
final _that = this;
switch (_that) {
case _Region():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Region value)?  $default,){
final _that = this;
switch (_that) {
case _Region() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double xmin,  double xmax,  double ymin,  double ymax,  double fovDeg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Region() when $default != null:
return $default(_that.xmin,_that.xmax,_that.ymin,_that.ymax,_that.fovDeg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double xmin,  double xmax,  double ymin,  double ymax,  double fovDeg)  $default,) {final _that = this;
switch (_that) {
case _Region():
return $default(_that.xmin,_that.xmax,_that.ymin,_that.ymax,_that.fovDeg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double xmin,  double xmax,  double ymin,  double ymax,  double fovDeg)?  $default,) {final _that = this;
switch (_that) {
case _Region() when $default != null:
return $default(_that.xmin,_that.xmax,_that.ymin,_that.ymax,_that.fovDeg);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Region implements Region {
  const _Region({required this.xmin, required this.xmax, required this.ymin, required this.ymax, required this.fovDeg});
  factory _Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);

@override final  double xmin;
@override final  double xmax;
@override final  double ymin;
@override final  double ymax;
@override final  double fovDeg;

/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegionCopyWith<_Region> get copyWith => __$RegionCopyWithImpl<_Region>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Region&&(identical(other.xmin, xmin) || other.xmin == xmin)&&(identical(other.xmax, xmax) || other.xmax == xmax)&&(identical(other.ymin, ymin) || other.ymin == ymin)&&(identical(other.ymax, ymax) || other.ymax == ymax)&&(identical(other.fovDeg, fovDeg) || other.fovDeg == fovDeg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,xmin,xmax,ymin,ymax,fovDeg);
}

@override
String toString() {
    return 'Region(xmin: $xmin, xmax: $xmax, ymin: $ymin, ymax: $ymax, fovDeg: $fovDeg)';
}


}

/// @nodoc
abstract mixin class _$RegionCopyWith<$Res> implements $RegionCopyWith<$Res> {
  factory _$RegionCopyWith(_Region value, $Res Function(_Region) _then) = __$RegionCopyWithImpl;
@override @useResult
$Res call({
 double xmin, double xmax, double ymin, double ymax, double fovDeg
});




}
/// @nodoc
class __$RegionCopyWithImpl<$Res>
    implements _$RegionCopyWith<$Res> {
  __$RegionCopyWithImpl(this._self, this._then);

  final _Region _self;
  final $Res Function(_Region) _then;

/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? xmin = null,Object? xmax = null,Object? ymin = null,Object? ymax = null,Object? fovDeg = null,}) {
  return _then(_Region(
xmin: null == xmin ? _self.xmin : xmin // ignore: cast_nullable_to_non_nullable
as double,xmax: null == xmax ? _self.xmax : xmax // ignore: cast_nullable_to_non_nullable
as double,ymin: null == ymin ? _self.ymin : ymin // ignore: cast_nullable_to_non_nullable
as double,ymax: null == ymax ? _self.ymax : ymax // ignore: cast_nullable_to_non_nullable
as double,fovDeg: null == fovDeg ? _self.fovDeg : fovDeg // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
