// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'frame.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveFrame {

 String get type; String get t; List<LivePerson> get people; String get radar;/// 클라우드에서만 (SPEC 9.1): "online" | "offline". 파이가 클라우드에 안 붙어 있으면 offline.
@JsonKey(includeIfNull: false) String? get pi;
/// Create a copy of LiveFrame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveFrameCopyWith<LiveFrame> get copyWith => _$LiveFrameCopyWithImpl<LiveFrame>(this as LiveFrame, _$identity);

  /// Serializes this LiveFrame to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LiveFrame;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveFrame&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.t, _this.t) || other.t == _this.t)&&const DeepCollectionEquality().equals(other.people, _this.people)&&(identical(other.radar, _this.radar) || other.radar == _this.radar)&&(identical(other.pi, _this.pi) || other.pi == _this.pi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LiveFrame;
  return Object.hash(runtimeType,_this.type,_this.t,const DeepCollectionEquality().hash(_this.people),_this.radar,_this.pi);
}

@override
String toString() {
  final _this = this as LiveFrame;
  return 'LiveFrame(type: ${_this.type}, t: ${_this.t}, people: ${_this.people}, radar: ${_this.radar}, pi: ${_this.pi})';
}


}

/// @nodoc
abstract mixin class $LiveFrameCopyWith<$Res>  {
  factory $LiveFrameCopyWith(LiveFrame value, $Res Function(LiveFrame) _then) = _$LiveFrameCopyWithImpl;
@useResult
$Res call({
 String type, String t, List<LivePerson> people, String radar,@JsonKey(includeIfNull: false) String? pi
});




}
/// @nodoc
class _$LiveFrameCopyWithImpl<$Res>
    implements $LiveFrameCopyWith<$Res> {
  _$LiveFrameCopyWithImpl(this._self, this._then);

  final LiveFrame _self;
  final $Res Function(LiveFrame) _then;

/// Create a copy of LiveFrame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? t = null,Object? people = null,Object? radar = null,Object? pi = freezed,}) {
  return _then(LiveFrame(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as String,people: null == people ? _self.people : people // ignore: cast_nullable_to_non_nullable
as List<LivePerson>,radar: null == radar ? _self.radar : radar // ignore: cast_nullable_to_non_nullable
as String,pi: freezed == pi ? _self.pi : pi // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveFrame].
extension LiveFramePatterns on LiveFrame {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveFrame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveFrame() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveFrame value)  $default,){
final _that = this;
switch (_that) {
case _LiveFrame():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveFrame value)?  $default,){
final _that = this;
switch (_that) {
case _LiveFrame() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String t,  List<LivePerson> people,  String radar, @JsonKey(includeIfNull: false)  String? pi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveFrame() when $default != null:
return $default(_that.type,_that.t,_that.people,_that.radar,_that.pi);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String t,  List<LivePerson> people,  String radar, @JsonKey(includeIfNull: false)  String? pi)  $default,) {final _that = this;
switch (_that) {
case _LiveFrame():
return $default(_that.type,_that.t,_that.people,_that.radar,_that.pi);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String t,  List<LivePerson> people,  String radar, @JsonKey(includeIfNull: false)  String? pi)?  $default,) {final _that = this;
switch (_that) {
case _LiveFrame() when $default != null:
return $default(_that.type,_that.t,_that.people,_that.radar,_that.pi);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveFrame extends LiveFrame {
  const _LiveFrame({this.type = 'frame', required this.t,  List<LivePerson> people = const <LivePerson>[], required this.radar, @JsonKey(includeIfNull: false) this.pi}): _people = people,super._();
  factory _LiveFrame.fromJson(Map<String, dynamic> json) => _$LiveFrameFromJson(json);

@override@JsonKey() final  String type;
@override final  String t;
 final  List<LivePerson> _people;
@override@JsonKey() List<LivePerson> get people {
  if (_people is EqualUnmodifiableListView) return _people;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_people);
}

@override final  String radar;
/// 클라우드에서만 (SPEC 9.1): "online" | "offline". 파이가 클라우드에 안 붙어 있으면 offline.
@override@JsonKey(includeIfNull: false) final  String? pi;

/// Create a copy of LiveFrame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveFrameCopyWith<_LiveFrame> get copyWith => __$LiveFrameCopyWithImpl<_LiveFrame>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveFrameToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveFrame&&(identical(other.type, type) || other.type == type)&&(identical(other.t, t) || other.t == t)&&const DeepCollectionEquality().equals(other.people, _people)&&(identical(other.radar, radar) || other.radar == radar)&&(identical(other.pi, pi) || other.pi == pi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,t,const DeepCollectionEquality().hash(_people),radar,pi);
}

@override
String toString() {
    return 'LiveFrame(type: $type, t: $t, people: $people, radar: $radar, pi: $pi)';
}


}

/// @nodoc
abstract mixin class _$LiveFrameCopyWith<$Res> implements $LiveFrameCopyWith<$Res> {
  factory _$LiveFrameCopyWith(_LiveFrame value, $Res Function(_LiveFrame) _then) = __$LiveFrameCopyWithImpl;
@override @useResult
$Res call({
 String type, String t, List<LivePerson> people, String radar,@JsonKey(includeIfNull: false) String? pi
});




}
/// @nodoc
class __$LiveFrameCopyWithImpl<$Res>
    implements _$LiveFrameCopyWith<$Res> {
  __$LiveFrameCopyWithImpl(this._self, this._then);

  final _LiveFrame _self;
  final $Res Function(_LiveFrame) _then;

/// Create a copy of LiveFrame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? t = null,Object? people = null,Object? radar = null,Object? pi = freezed,}) {
  return _then(_LiveFrame(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as String,people: null == people ? _self._people : people // ignore: cast_nullable_to_non_nullable
as List<LivePerson>,radar: null == radar ? _self.radar : radar // ignore: cast_nullable_to_non_nullable
as String,pi: freezed == pi ? _self.pi : pi // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$LivePerson {

 String get id; double get x; double get y; bool get hidden; String get situation; double get prob; bool get abnormal; double get stillS; double get elapsedS;
/// Create a copy of LivePerson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LivePersonCopyWith<LivePerson> get copyWith => _$LivePersonCopyWithImpl<LivePerson>(this as LivePerson, _$identity);

  /// Serializes this LivePerson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LivePerson;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LivePerson&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.x, _this.x) || other.x == _this.x)&&(identical(other.y, _this.y) || other.y == _this.y)&&(identical(other.hidden, _this.hidden) || other.hidden == _this.hidden)&&(identical(other.situation, _this.situation) || other.situation == _this.situation)&&(identical(other.prob, _this.prob) || other.prob == _this.prob)&&(identical(other.abnormal, _this.abnormal) || other.abnormal == _this.abnormal)&&(identical(other.stillS, _this.stillS) || other.stillS == _this.stillS)&&(identical(other.elapsedS, _this.elapsedS) || other.elapsedS == _this.elapsedS));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LivePerson;
  return Object.hash(runtimeType,_this.id,_this.x,_this.y,_this.hidden,_this.situation,_this.prob,_this.abnormal,_this.stillS,_this.elapsedS);
}

@override
String toString() {
  final _this = this as LivePerson;
  return 'LivePerson(id: ${_this.id}, x: ${_this.x}, y: ${_this.y}, hidden: ${_this.hidden}, situation: ${_this.situation}, prob: ${_this.prob}, abnormal: ${_this.abnormal}, stillS: ${_this.stillS}, elapsedS: ${_this.elapsedS})';
}


}

/// @nodoc
abstract mixin class $LivePersonCopyWith<$Res>  {
  factory $LivePersonCopyWith(LivePerson value, $Res Function(LivePerson) _then) = _$LivePersonCopyWithImpl;
@useResult
$Res call({
 String id, double x, double y, bool hidden, String situation, double prob, bool abnormal, double stillS, double elapsedS
});




}
/// @nodoc
class _$LivePersonCopyWithImpl<$Res>
    implements $LivePersonCopyWith<$Res> {
  _$LivePersonCopyWithImpl(this._self, this._then);

  final LivePerson _self;
  final $Res Function(LivePerson) _then;

/// Create a copy of LivePerson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? x = null,Object? y = null,Object? hidden = null,Object? situation = null,Object? prob = null,Object? abnormal = null,Object? stillS = null,Object? elapsedS = null,}) {
  return _then(LivePerson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,situation: null == situation ? _self.situation : situation // ignore: cast_nullable_to_non_nullable
as String,prob: null == prob ? _self.prob : prob // ignore: cast_nullable_to_non_nullable
as double,abnormal: null == abnormal ? _self.abnormal : abnormal // ignore: cast_nullable_to_non_nullable
as bool,stillS: null == stillS ? _self.stillS : stillS // ignore: cast_nullable_to_non_nullable
as double,elapsedS: null == elapsedS ? _self.elapsedS : elapsedS // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [LivePerson].
extension LivePersonPatterns on LivePerson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LivePerson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LivePerson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LivePerson value)  $default,){
final _that = this;
switch (_that) {
case _LivePerson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LivePerson value)?  $default,){
final _that = this;
switch (_that) {
case _LivePerson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  double x,  double y,  bool hidden,  String situation,  double prob,  bool abnormal,  double stillS,  double elapsedS)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LivePerson() when $default != null:
return $default(_that.id,_that.x,_that.y,_that.hidden,_that.situation,_that.prob,_that.abnormal,_that.stillS,_that.elapsedS);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  double x,  double y,  bool hidden,  String situation,  double prob,  bool abnormal,  double stillS,  double elapsedS)  $default,) {final _that = this;
switch (_that) {
case _LivePerson():
return $default(_that.id,_that.x,_that.y,_that.hidden,_that.situation,_that.prob,_that.abnormal,_that.stillS,_that.elapsedS);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  double x,  double y,  bool hidden,  String situation,  double prob,  bool abnormal,  double stillS,  double elapsedS)?  $default,) {final _that = this;
switch (_that) {
case _LivePerson() when $default != null:
return $default(_that.id,_that.x,_that.y,_that.hidden,_that.situation,_that.prob,_that.abnormal,_that.stillS,_that.elapsedS);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LivePerson implements LivePerson {
  const _LivePerson({required this.id, required this.x, required this.y, this.hidden = false, required this.situation, required this.prob, required this.abnormal, this.stillS = 0, this.elapsedS = 0});
  factory _LivePerson.fromJson(Map<String, dynamic> json) => _$LivePersonFromJson(json);

@override final  String id;
@override final  double x;
@override final  double y;
@override@JsonKey() final  bool hidden;
@override final  String situation;
@override final  double prob;
@override final  bool abnormal;
@override@JsonKey() final  double stillS;
@override@JsonKey() final  double elapsedS;

/// Create a copy of LivePerson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LivePersonCopyWith<_LivePerson> get copyWith => __$LivePersonCopyWithImpl<_LivePerson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LivePersonToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LivePerson&&(identical(other.id, id) || other.id == id)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.situation, situation) || other.situation == situation)&&(identical(other.prob, prob) || other.prob == prob)&&(identical(other.abnormal, abnormal) || other.abnormal == abnormal)&&(identical(other.stillS, stillS) || other.stillS == stillS)&&(identical(other.elapsedS, elapsedS) || other.elapsedS == elapsedS));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,x,y,hidden,situation,prob,abnormal,stillS,elapsedS);
}

@override
String toString() {
    return 'LivePerson(id: $id, x: $x, y: $y, hidden: $hidden, situation: $situation, prob: $prob, abnormal: $abnormal, stillS: $stillS, elapsedS: $elapsedS)';
}


}

/// @nodoc
abstract mixin class _$LivePersonCopyWith<$Res> implements $LivePersonCopyWith<$Res> {
  factory _$LivePersonCopyWith(_LivePerson value, $Res Function(_LivePerson) _then) = __$LivePersonCopyWithImpl;
@override @useResult
$Res call({
 String id, double x, double y, bool hidden, String situation, double prob, bool abnormal, double stillS, double elapsedS
});




}
/// @nodoc
class __$LivePersonCopyWithImpl<$Res>
    implements _$LivePersonCopyWith<$Res> {
  __$LivePersonCopyWithImpl(this._self, this._then);

  final _LivePerson _self;
  final $Res Function(_LivePerson) _then;

/// Create a copy of LivePerson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? x = null,Object? y = null,Object? hidden = null,Object? situation = null,Object? prob = null,Object? abnormal = null,Object? stillS = null,Object? elapsedS = null,}) {
  return _then(_LivePerson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,situation: null == situation ? _self.situation : situation // ignore: cast_nullable_to_non_nullable
as String,prob: null == prob ? _self.prob : prob // ignore: cast_nullable_to_non_nullable
as double,abnormal: null == abnormal ? _self.abnormal : abnormal // ignore: cast_nullable_to_non_nullable
as bool,stillS: null == stillS ? _self.stillS : stillS // ignore: cast_nullable_to_non_nullable
as double,elapsedS: null == elapsedS ? _self.elapsedS : elapsedS // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
