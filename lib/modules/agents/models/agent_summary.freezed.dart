// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AgentSummary {

 String get id; String get type; String get name; String get bio; String get location; List<String> get services; String get rate; String get avatarUrl;
/// Create a copy of AgentSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentSummaryCopyWith<AgentSummary> get copyWith => _$AgentSummaryCopyWithImpl<AgentSummary>(this as AgentSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AgentSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.bio, _this.bio) || other.bio == _this.bio)&&(identical(other.location, _this.location) || other.location == _this.location)&&const DeepCollectionEquality().equals(other.services, _this.services)&&(identical(other.rate, _this.rate) || other.rate == _this.rate)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl));
}


@override
int get hashCode {
  final _this = this as AgentSummary;
  return Object.hash(runtimeType,_this.id,_this.type,_this.name,_this.bio,_this.location,const DeepCollectionEquality().hash(_this.services),_this.rate,_this.avatarUrl);
}

@override
String toString() {
  final _this = this as AgentSummary;
  return 'AgentSummary(id: ${_this.id}, type: ${_this.type}, name: ${_this.name}, bio: ${_this.bio}, location: ${_this.location}, services: ${_this.services}, rate: ${_this.rate}, avatarUrl: ${_this.avatarUrl})';
}


}

/// @nodoc
abstract mixin class $AgentSummaryCopyWith<$Res>  {
  factory $AgentSummaryCopyWith(AgentSummary value, $Res Function(AgentSummary) _then) = _$AgentSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String type, String name, String bio, String location, List<String> services, String rate, String avatarUrl
});




}
/// @nodoc
class _$AgentSummaryCopyWithImpl<$Res>
    implements $AgentSummaryCopyWith<$Res> {
  _$AgentSummaryCopyWithImpl(this._self, this._then);

  final AgentSummary _self;
  final $Res Function(AgentSummary) _then;

/// Create a copy of AgentSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? name = null,Object? bio = null,Object? location = null,Object? services = null,Object? rate = null,Object? avatarUrl = null,}) {
  return _then(AgentSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,services: null == services ? _self.services : services // ignore: cast_nullable_to_non_nullable
as List<String>,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentSummary].
extension AgentSummaryPatterns on AgentSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentSummary value)  $default,){
final _that = this;
switch (_that) {
case _AgentSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentSummary value)?  $default,){
final _that = this;
switch (_that) {
case _AgentSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String name,  String bio,  String location,  List<String> services,  String rate,  String avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentSummary() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.bio,_that.location,_that.services,_that.rate,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String name,  String bio,  String location,  List<String> services,  String rate,  String avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _AgentSummary():
return $default(_that.id,_that.type,_that.name,_that.bio,_that.location,_that.services,_that.rate,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String name,  String bio,  String location,  List<String> services,  String rate,  String avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _AgentSummary() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.bio,_that.location,_that.services,_that.rate,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc


class _AgentSummary extends AgentSummary {
  const _AgentSummary({required this.id, required this.type, required this.name, required this.bio, required this.location, required  List<String> services, required this.rate, required this.avatarUrl}): _services = services,super._();
  

@override final  String id;
@override final  String type;
@override final  String name;
@override final  String bio;
@override final  String location;
 final  List<String> _services;
@override List<String> get services {
  if (_services is EqualUnmodifiableListView) return _services;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_services);
}

@override final  String rate;
@override final  String avatarUrl;

/// Create a copy of AgentSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentSummaryCopyWith<_AgentSummary> get copyWith => __$AgentSummaryCopyWithImpl<_AgentSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other.services, _services)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,type,name,bio,location,const DeepCollectionEquality().hash(_services),rate,avatarUrl);
}

@override
String toString() {
    return 'AgentSummary(id: $id, type: $type, name: $name, bio: $bio, location: $location, services: $services, rate: $rate, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$AgentSummaryCopyWith<$Res> implements $AgentSummaryCopyWith<$Res> {
  factory _$AgentSummaryCopyWith(_AgentSummary value, $Res Function(_AgentSummary) _then) = __$AgentSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String name, String bio, String location, List<String> services, String rate, String avatarUrl
});




}
/// @nodoc
class __$AgentSummaryCopyWithImpl<$Res>
    implements _$AgentSummaryCopyWith<$Res> {
  __$AgentSummaryCopyWithImpl(this._self, this._then);

  final _AgentSummary _self;
  final $Res Function(_AgentSummary) _then;

/// Create a copy of AgentSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? name = null,Object? bio = null,Object? location = null,Object? services = null,Object? rate = null,Object? avatarUrl = null,}) {
  return _then(_AgentSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,services: null == services ? _self._services : services // ignore: cast_nullable_to_non_nullable
as List<String>,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
