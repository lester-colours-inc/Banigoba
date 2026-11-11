// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_author.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PostAuthor {

 String get displayName; String get fullBodyImageUrl; String get stylePreference; String get profileImageUrl;
/// Create a copy of PostAuthor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostAuthorCopyWith<PostAuthor> get copyWith => _$PostAuthorCopyWithImpl<PostAuthor>(this as PostAuthor, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PostAuthor;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostAuthor&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.fullBodyImageUrl, _this.fullBodyImageUrl) || other.fullBodyImageUrl == _this.fullBodyImageUrl)&&(identical(other.stylePreference, _this.stylePreference) || other.stylePreference == _this.stylePreference)&&(identical(other.profileImageUrl, _this.profileImageUrl) || other.profileImageUrl == _this.profileImageUrl));
}


@override
int get hashCode {
  final _this = this as PostAuthor;
  return Object.hash(runtimeType,_this.displayName,_this.fullBodyImageUrl,_this.stylePreference,_this.profileImageUrl);
}

@override
String toString() {
  final _this = this as PostAuthor;
  return 'PostAuthor(displayName: ${_this.displayName}, fullBodyImageUrl: ${_this.fullBodyImageUrl}, stylePreference: ${_this.stylePreference}, profileImageUrl: ${_this.profileImageUrl})';
}


}

/// @nodoc
abstract mixin class $PostAuthorCopyWith<$Res>  {
  factory $PostAuthorCopyWith(PostAuthor value, $Res Function(PostAuthor) _then) = _$PostAuthorCopyWithImpl;
@useResult
$Res call({
 String displayName, String fullBodyImageUrl, String stylePreference, String profileImageUrl
});




}
/// @nodoc
class _$PostAuthorCopyWithImpl<$Res>
    implements $PostAuthorCopyWith<$Res> {
  _$PostAuthorCopyWithImpl(this._self, this._then);

  final PostAuthor _self;
  final $Res Function(PostAuthor) _then;

/// Create a copy of PostAuthor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = null,Object? fullBodyImageUrl = null,Object? stylePreference = null,Object? profileImageUrl = null,}) {
  return _then(PostAuthor(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,fullBodyImageUrl: null == fullBodyImageUrl ? _self.fullBodyImageUrl : fullBodyImageUrl // ignore: cast_nullable_to_non_nullable
as String,stylePreference: null == stylePreference ? _self.stylePreference : stylePreference // ignore: cast_nullable_to_non_nullable
as String,profileImageUrl: null == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PostAuthor].
extension PostAuthorPatterns on PostAuthor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostAuthor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostAuthor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostAuthor value)  $default,){
final _that = this;
switch (_that) {
case _PostAuthor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostAuthor value)?  $default,){
final _that = this;
switch (_that) {
case _PostAuthor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String displayName,  String fullBodyImageUrl,  String stylePreference,  String profileImageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostAuthor() when $default != null:
return $default(_that.displayName,_that.fullBodyImageUrl,_that.stylePreference,_that.profileImageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String displayName,  String fullBodyImageUrl,  String stylePreference,  String profileImageUrl)  $default,) {final _that = this;
switch (_that) {
case _PostAuthor():
return $default(_that.displayName,_that.fullBodyImageUrl,_that.stylePreference,_that.profileImageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String displayName,  String fullBodyImageUrl,  String stylePreference,  String profileImageUrl)?  $default,) {final _that = this;
switch (_that) {
case _PostAuthor() when $default != null:
return $default(_that.displayName,_that.fullBodyImageUrl,_that.stylePreference,_that.profileImageUrl);case _:
  return null;

}
}

}

/// @nodoc


class _PostAuthor extends PostAuthor {
  const _PostAuthor({required this.displayName, required this.fullBodyImageUrl, required this.stylePreference, this.profileImageUrl = ''}): super._();
  

@override final  String displayName;
@override final  String fullBodyImageUrl;
@override final  String stylePreference;
@override@JsonKey() final  String profileImageUrl;

/// Create a copy of PostAuthor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostAuthorCopyWith<_PostAuthor> get copyWith => __$PostAuthorCopyWithImpl<_PostAuthor>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostAuthor&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.fullBodyImageUrl, fullBodyImageUrl) || other.fullBodyImageUrl == fullBodyImageUrl)&&(identical(other.stylePreference, stylePreference) || other.stylePreference == stylePreference)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,displayName,fullBodyImageUrl,stylePreference,profileImageUrl);
}

@override
String toString() {
    return 'PostAuthor(displayName: $displayName, fullBodyImageUrl: $fullBodyImageUrl, stylePreference: $stylePreference, profileImageUrl: $profileImageUrl)';
}


}

/// @nodoc
abstract mixin class _$PostAuthorCopyWith<$Res> implements $PostAuthorCopyWith<$Res> {
  factory _$PostAuthorCopyWith(_PostAuthor value, $Res Function(_PostAuthor) _then) = __$PostAuthorCopyWithImpl;
@override @useResult
$Res call({
 String displayName, String fullBodyImageUrl, String stylePreference, String profileImageUrl
});




}
/// @nodoc
class __$PostAuthorCopyWithImpl<$Res>
    implements _$PostAuthorCopyWith<$Res> {
  __$PostAuthorCopyWithImpl(this._self, this._then);

  final _PostAuthor _self;
  final $Res Function(_PostAuthor) _then;

/// Create a copy of PostAuthor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = null,Object? fullBodyImageUrl = null,Object? stylePreference = null,Object? profileImageUrl = null,}) {
  return _then(_PostAuthor(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,fullBodyImageUrl: null == fullBodyImageUrl ? _self.fullBodyImageUrl : fullBodyImageUrl // ignore: cast_nullable_to_non_nullable
as String,stylePreference: null == stylePreference ? _self.stylePreference : stylePreference // ignore: cast_nullable_to_non_nullable
as String,profileImageUrl: null == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
