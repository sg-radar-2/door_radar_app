// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Event {

 int get id; EventKind get kind; String get person; String get t; String get startedAt; String? get endedAt; String get situation; double get prob; bool get abnormal; String? get endSituation;/// final: 최종 판정과 같은 확률로 동점인 다른 이상 행동 (보통 빈 배열). 나온 행동(`behaviors`)에도 들어 있다.
 List<String>? get also; List<Behavior>? get behaviors; String? get reason; String? get path; bool get photo; String? get label;/// `[시작부터 초, x, y]`, 0.2초 간격
 List<List<double>>? get track;
/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventCopyWith<Event> get copyWith => _$EventCopyWithImpl<Event>(this as Event, _$identity);

  /// Serializes this Event to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Event;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Event&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.person, _this.person) || other.person == _this.person)&&(identical(other.t, _this.t) || other.t == _this.t)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&(identical(other.situation, _this.situation) || other.situation == _this.situation)&&(identical(other.prob, _this.prob) || other.prob == _this.prob)&&(identical(other.abnormal, _this.abnormal) || other.abnormal == _this.abnormal)&&(identical(other.endSituation, _this.endSituation) || other.endSituation == _this.endSituation)&&const DeepCollectionEquality().equals(other.also, _this.also)&&const DeepCollectionEquality().equals(other.behaviors, _this.behaviors)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.photo, _this.photo) || other.photo == _this.photo)&&(identical(other.label, _this.label) || other.label == _this.label)&&const DeepCollectionEquality().equals(other.track, _this.track));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Event;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.person,_this.t,_this.startedAt,_this.endedAt,_this.situation,_this.prob,_this.abnormal,_this.endSituation,const DeepCollectionEquality().hash(_this.also),const DeepCollectionEquality().hash(_this.behaviors),_this.reason,_this.path,_this.photo,_this.label,const DeepCollectionEquality().hash(_this.track));
}

@override
String toString() {
  final _this = this as Event;
  return 'Event(id: ${_this.id}, kind: ${_this.kind}, person: ${_this.person}, t: ${_this.t}, startedAt: ${_this.startedAt}, endedAt: ${_this.endedAt}, situation: ${_this.situation}, prob: ${_this.prob}, abnormal: ${_this.abnormal}, endSituation: ${_this.endSituation}, also: ${_this.also}, behaviors: ${_this.behaviors}, reason: ${_this.reason}, path: ${_this.path}, photo: ${_this.photo}, label: ${_this.label}, track: ${_this.track})';
}


}

/// @nodoc
abstract mixin class $EventCopyWith<$Res>  {
  factory $EventCopyWith(Event value, $Res Function(Event) _then) = _$EventCopyWithImpl;
@useResult
$Res call({
 int id, EventKind kind, String person, String t, String startedAt, String? endedAt, String situation, double prob, bool abnormal, String? endSituation, List<String>? also, List<Behavior>? behaviors, String? reason, String? path, bool photo, String? label, List<List<double>>? track
});




}
/// @nodoc
class _$EventCopyWithImpl<$Res>
    implements $EventCopyWith<$Res> {
  _$EventCopyWithImpl(this._self, this._then);

  final Event _self;
  final $Res Function(Event) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? person = null,Object? t = null,Object? startedAt = null,Object? endedAt = freezed,Object? situation = null,Object? prob = null,Object? abnormal = null,Object? endSituation = freezed,Object? also = freezed,Object? behaviors = freezed,Object? reason = freezed,Object? path = freezed,Object? photo = null,Object? label = freezed,Object? track = freezed,}) {
  return _then(Event(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as EventKind,person: null == person ? _self.person : person // ignore: cast_nullable_to_non_nullable
as String,t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as String?,situation: null == situation ? _self.situation : situation // ignore: cast_nullable_to_non_nullable
as String,prob: null == prob ? _self.prob : prob // ignore: cast_nullable_to_non_nullable
as double,abnormal: null == abnormal ? _self.abnormal : abnormal // ignore: cast_nullable_to_non_nullable
as bool,endSituation: freezed == endSituation ? _self.endSituation : endSituation // ignore: cast_nullable_to_non_nullable
as String?,also: freezed == also ? _self.also : also // ignore: cast_nullable_to_non_nullable
as List<String>?,behaviors: freezed == behaviors ? _self.behaviors : behaviors // ignore: cast_nullable_to_non_nullable
as List<Behavior>?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as bool,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,track: freezed == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as List<List<double>>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Event].
extension EventPatterns on Event {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Event value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Event() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Event value)  $default,){
final _that = this;
switch (_that) {
case _Event():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Event value)?  $default,){
final _that = this;
switch (_that) {
case _Event() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  EventKind kind,  String person,  String t,  String startedAt,  String? endedAt,  String situation,  double prob,  bool abnormal,  String? endSituation,  List<String>? also,  List<Behavior>? behaviors,  String? reason,  String? path,  bool photo,  String? label,  List<List<double>>? track)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Event() when $default != null:
return $default(_that.id,_that.kind,_that.person,_that.t,_that.startedAt,_that.endedAt,_that.situation,_that.prob,_that.abnormal,_that.endSituation,_that.also,_that.behaviors,_that.reason,_that.path,_that.photo,_that.label,_that.track);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  EventKind kind,  String person,  String t,  String startedAt,  String? endedAt,  String situation,  double prob,  bool abnormal,  String? endSituation,  List<String>? also,  List<Behavior>? behaviors,  String? reason,  String? path,  bool photo,  String? label,  List<List<double>>? track)  $default,) {final _that = this;
switch (_that) {
case _Event():
return $default(_that.id,_that.kind,_that.person,_that.t,_that.startedAt,_that.endedAt,_that.situation,_that.prob,_that.abnormal,_that.endSituation,_that.also,_that.behaviors,_that.reason,_that.path,_that.photo,_that.label,_that.track);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  EventKind kind,  String person,  String t,  String startedAt,  String? endedAt,  String situation,  double prob,  bool abnormal,  String? endSituation,  List<String>? also,  List<Behavior>? behaviors,  String? reason,  String? path,  bool photo,  String? label,  List<List<double>>? track)?  $default,) {final _that = this;
switch (_that) {
case _Event() when $default != null:
return $default(_that.id,_that.kind,_that.person,_that.t,_that.startedAt,_that.endedAt,_that.situation,_that.prob,_that.abnormal,_that.endSituation,_that.also,_that.behaviors,_that.reason,_that.path,_that.photo,_that.label,_that.track);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Event extends Event {
  const _Event({required this.id, required this.kind, required this.person, required this.t, required this.startedAt, this.endedAt, required this.situation, required this.prob, required this.abnormal, this.endSituation,  List<String>? also,  List<Behavior>? behaviors, this.reason, this.path, this.photo = false, this.label,  List<List<double>>? track}): _also = also,_behaviors = behaviors,_track = track,super._();
  factory _Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

@override final  int id;
@override final  EventKind kind;
@override final  String person;
@override final  String t;
@override final  String startedAt;
@override final  String? endedAt;
@override final  String situation;
@override final  double prob;
@override final  bool abnormal;
@override final  String? endSituation;
/// final: 최종 판정과 같은 확률로 동점인 다른 이상 행동 (보통 빈 배열). 나온 행동(`behaviors`)에도 들어 있다.
 final  List<String>? _also;
/// final: 최종 판정과 같은 확률로 동점인 다른 이상 행동 (보통 빈 배열). 나온 행동(`behaviors`)에도 들어 있다.
@override List<String>? get also {
  final value = _also;
  if (value == null) return null;
  if (_also is EqualUnmodifiableListView) return _also;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<Behavior>? _behaviors;
@override List<Behavior>? get behaviors {
  final value = _behaviors;
  if (value == null) return null;
  if (_behaviors is EqualUnmodifiableListView) return _behaviors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? reason;
@override final  String? path;
@override@JsonKey() final  bool photo;
@override final  String? label;
/// `[시작부터 초, x, y]`, 0.2초 간격
 final  List<List<double>>? _track;
/// `[시작부터 초, x, y]`, 0.2초 간격
@override List<List<double>>? get track {
  final value = _track;
  if (value == null) return null;
  if (_track is EqualUnmodifiableListView) return _track;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventCopyWith<_Event> get copyWith => __$EventCopyWithImpl<_Event>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Event&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.person, person) || other.person == person)&&(identical(other.t, t) || other.t == t)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.situation, situation) || other.situation == situation)&&(identical(other.prob, prob) || other.prob == prob)&&(identical(other.abnormal, abnormal) || other.abnormal == abnormal)&&(identical(other.endSituation, endSituation) || other.endSituation == endSituation)&&const DeepCollectionEquality().equals(other.also, _also)&&const DeepCollectionEquality().equals(other.behaviors, _behaviors)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.path, path) || other.path == path)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other.track, _track));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,person,t,startedAt,endedAt,situation,prob,abnormal,endSituation,const DeepCollectionEquality().hash(_also),const DeepCollectionEquality().hash(_behaviors),reason,path,photo,label,const DeepCollectionEquality().hash(_track));
}

@override
String toString() {
    return 'Event(id: $id, kind: $kind, person: $person, t: $t, startedAt: $startedAt, endedAt: $endedAt, situation: $situation, prob: $prob, abnormal: $abnormal, endSituation: $endSituation, also: $also, behaviors: $behaviors, reason: $reason, path: $path, photo: $photo, label: $label, track: $track)';
}


}

/// @nodoc
abstract mixin class _$EventCopyWith<$Res> implements $EventCopyWith<$Res> {
  factory _$EventCopyWith(_Event value, $Res Function(_Event) _then) = __$EventCopyWithImpl;
@override @useResult
$Res call({
 int id, EventKind kind, String person, String t, String startedAt, String? endedAt, String situation, double prob, bool abnormal, String? endSituation, List<String>? also, List<Behavior>? behaviors, String? reason, String? path, bool photo, String? label, List<List<double>>? track
});




}
/// @nodoc
class __$EventCopyWithImpl<$Res>
    implements _$EventCopyWith<$Res> {
  __$EventCopyWithImpl(this._self, this._then);

  final _Event _self;
  final $Res Function(_Event) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? person = null,Object? t = null,Object? startedAt = null,Object? endedAt = freezed,Object? situation = null,Object? prob = null,Object? abnormal = null,Object? endSituation = freezed,Object? also = freezed,Object? behaviors = freezed,Object? reason = freezed,Object? path = freezed,Object? photo = null,Object? label = freezed,Object? track = freezed,}) {
  return _then(_Event(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as EventKind,person: null == person ? _self.person : person // ignore: cast_nullable_to_non_nullable
as String,t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as String?,situation: null == situation ? _self.situation : situation // ignore: cast_nullable_to_non_nullable
as String,prob: null == prob ? _self.prob : prob // ignore: cast_nullable_to_non_nullable
as double,abnormal: null == abnormal ? _self.abnormal : abnormal // ignore: cast_nullable_to_non_nullable
as bool,endSituation: freezed == endSituation ? _self.endSituation : endSituation // ignore: cast_nullable_to_non_nullable
as String?,also: freezed == also ? _self._also : also // ignore: cast_nullable_to_non_nullable
as List<String>?,behaviors: freezed == behaviors ? _self._behaviors : behaviors // ignore: cast_nullable_to_non_nullable
as List<Behavior>?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as bool,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,track: freezed == track ? _self._track : track // ignore: cast_nullable_to_non_nullable
as List<List<double>>?,
  ));
}


}


/// @nodoc
mixin _$Behavior {

 String get situation; double get prob; String get source;
/// Create a copy of Behavior
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BehaviorCopyWith<Behavior> get copyWith => _$BehaviorCopyWithImpl<Behavior>(this as Behavior, _$identity);

  /// Serializes this Behavior to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Behavior;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Behavior&&(identical(other.situation, _this.situation) || other.situation == _this.situation)&&(identical(other.prob, _this.prob) || other.prob == _this.prob)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Behavior;
  return Object.hash(runtimeType,_this.situation,_this.prob,_this.source);
}

@override
String toString() {
  final _this = this as Behavior;
  return 'Behavior(situation: ${_this.situation}, prob: ${_this.prob}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $BehaviorCopyWith<$Res>  {
  factory $BehaviorCopyWith(Behavior value, $Res Function(Behavior) _then) = _$BehaviorCopyWithImpl;
@useResult
$Res call({
 String situation, double prob, String source
});




}
/// @nodoc
class _$BehaviorCopyWithImpl<$Res>
    implements $BehaviorCopyWith<$Res> {
  _$BehaviorCopyWithImpl(this._self, this._then);

  final Behavior _self;
  final $Res Function(Behavior) _then;

/// Create a copy of Behavior
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? situation = null,Object? prob = null,Object? source = null,}) {
  return _then(Behavior(
situation: null == situation ? _self.situation : situation // ignore: cast_nullable_to_non_nullable
as String,prob: null == prob ? _self.prob : prob // ignore: cast_nullable_to_non_nullable
as double,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Behavior].
extension BehaviorPatterns on Behavior {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Behavior value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Behavior() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Behavior value)  $default,){
final _that = this;
switch (_that) {
case _Behavior():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Behavior value)?  $default,){
final _that = this;
switch (_that) {
case _Behavior() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String situation,  double prob,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Behavior() when $default != null:
return $default(_that.situation,_that.prob,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String situation,  double prob,  String source)  $default,) {final _that = this;
switch (_that) {
case _Behavior():
return $default(_that.situation,_that.prob,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String situation,  double prob,  String source)?  $default,) {final _that = this;
switch (_that) {
case _Behavior() when $default != null:
return $default(_that.situation,_that.prob,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Behavior implements Behavior {
  const _Behavior({required this.situation, required this.prob, required this.source});
  factory _Behavior.fromJson(Map<String, dynamic> json) => _$BehaviorFromJson(json);

@override final  String situation;
@override final  double prob;
@override final  String source;

/// Create a copy of Behavior
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BehaviorCopyWith<_Behavior> get copyWith => __$BehaviorCopyWithImpl<_Behavior>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BehaviorToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Behavior&&(identical(other.situation, situation) || other.situation == situation)&&(identical(other.prob, prob) || other.prob == prob)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,situation,prob,source);
}

@override
String toString() {
    return 'Behavior(situation: $situation, prob: $prob, source: $source)';
}


}

/// @nodoc
abstract mixin class _$BehaviorCopyWith<$Res> implements $BehaviorCopyWith<$Res> {
  factory _$BehaviorCopyWith(_Behavior value, $Res Function(_Behavior) _then) = __$BehaviorCopyWithImpl;
@override @useResult
$Res call({
 String situation, double prob, String source
});




}
/// @nodoc
class __$BehaviorCopyWithImpl<$Res>
    implements _$BehaviorCopyWith<$Res> {
  __$BehaviorCopyWithImpl(this._self, this._then);

  final _Behavior _self;
  final $Res Function(_Behavior) _then;

/// Create a copy of Behavior
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? situation = null,Object? prob = null,Object? source = null,}) {
  return _then(_Behavior(
situation: null == situation ? _self.situation : situation // ignore: cast_nullable_to_non_nullable
as String,prob: null == prob ? _self.prob : prob // ignore: cast_nullable_to_non_nullable
as double,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
