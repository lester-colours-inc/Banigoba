// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'first_run_guide.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GuideProgress implements DiagnosticableTreeMixin {

 bool get photoDone; bool get styleDone; int get wardrobeCount; bool get makeoverTried;
/// Create a copy of GuideProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuideProgressCopyWith<GuideProgress> get copyWith => _$GuideProgressCopyWithImpl<GuideProgress>(this as GuideProgress, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as GuideProgress;
  properties
    ..add(DiagnosticsProperty('type', 'GuideProgress'))
    ..add(DiagnosticsProperty('photoDone', _this.photoDone))..add(DiagnosticsProperty('styleDone', _this.styleDone))..add(DiagnosticsProperty('wardrobeCount', _this.wardrobeCount))..add(DiagnosticsProperty('makeoverTried', _this.makeoverTried));
}

@override
bool operator ==(Object other) {
  final _this = this as GuideProgress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuideProgress&&(identical(other.photoDone, _this.photoDone) || other.photoDone == _this.photoDone)&&(identical(other.styleDone, _this.styleDone) || other.styleDone == _this.styleDone)&&(identical(other.wardrobeCount, _this.wardrobeCount) || other.wardrobeCount == _this.wardrobeCount)&&(identical(other.makeoverTried, _this.makeoverTried) || other.makeoverTried == _this.makeoverTried));
}


@override
int get hashCode {
  final _this = this as GuideProgress;
  return Object.hash(runtimeType,_this.photoDone,_this.styleDone,_this.wardrobeCount,_this.makeoverTried);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as GuideProgress;
  return 'GuideProgress(photoDone: ${_this.photoDone}, styleDone: ${_this.styleDone}, wardrobeCount: ${_this.wardrobeCount}, makeoverTried: ${_this.makeoverTried})';
}


}

/// @nodoc
abstract mixin class $GuideProgressCopyWith<$Res>  {
  factory $GuideProgressCopyWith(GuideProgress value, $Res Function(GuideProgress) _then) = _$GuideProgressCopyWithImpl;
@useResult
$Res call({
 bool photoDone, bool styleDone, int wardrobeCount, bool makeoverTried
});




}
/// @nodoc
class _$GuideProgressCopyWithImpl<$Res>
    implements $GuideProgressCopyWith<$Res> {
  _$GuideProgressCopyWithImpl(this._self, this._then);

  final GuideProgress _self;
  final $Res Function(GuideProgress) _then;

/// Create a copy of GuideProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? photoDone = null,Object? styleDone = null,Object? wardrobeCount = null,Object? makeoverTried = null,}) {
  return _then(GuideProgress(
photoDone: null == photoDone ? _self.photoDone : photoDone // ignore: cast_nullable_to_non_nullable
as bool,styleDone: null == styleDone ? _self.styleDone : styleDone // ignore: cast_nullable_to_non_nullable
as bool,wardrobeCount: null == wardrobeCount ? _self.wardrobeCount : wardrobeCount // ignore: cast_nullable_to_non_nullable
as int,makeoverTried: null == makeoverTried ? _self.makeoverTried : makeoverTried // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GuideProgress].
extension GuideProgressPatterns on GuideProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuideProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuideProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuideProgress value)  $default,){
final _that = this;
switch (_that) {
case _GuideProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuideProgress value)?  $default,){
final _that = this;
switch (_that) {
case _GuideProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool photoDone,  bool styleDone,  int wardrobeCount,  bool makeoverTried)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuideProgress() when $default != null:
return $default(_that.photoDone,_that.styleDone,_that.wardrobeCount,_that.makeoverTried);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool photoDone,  bool styleDone,  int wardrobeCount,  bool makeoverTried)  $default,) {final _that = this;
switch (_that) {
case _GuideProgress():
return $default(_that.photoDone,_that.styleDone,_that.wardrobeCount,_that.makeoverTried);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool photoDone,  bool styleDone,  int wardrobeCount,  bool makeoverTried)?  $default,) {final _that = this;
switch (_that) {
case _GuideProgress() when $default != null:
return $default(_that.photoDone,_that.styleDone,_that.wardrobeCount,_that.makeoverTried);case _:
  return null;

}
}

}

/// @nodoc


class _GuideProgress extends GuideProgress with DiagnosticableTreeMixin {
  const _GuideProgress({this.photoDone = false, this.styleDone = false, this.wardrobeCount = 0, this.makeoverTried = false}): super._();
  

@override@JsonKey() final  bool photoDone;
@override@JsonKey() final  bool styleDone;
@override@JsonKey() final  int wardrobeCount;
@override@JsonKey() final  bool makeoverTried;

/// Create a copy of GuideProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuideProgressCopyWith<_GuideProgress> get copyWith => __$GuideProgressCopyWithImpl<_GuideProgress>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'GuideProgress'))
    ..add(DiagnosticsProperty('photoDone', photoDone))..add(DiagnosticsProperty('styleDone', styleDone))..add(DiagnosticsProperty('wardrobeCount', wardrobeCount))..add(DiagnosticsProperty('makeoverTried', makeoverTried));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuideProgress&&(identical(other.photoDone, photoDone) || other.photoDone == photoDone)&&(identical(other.styleDone, styleDone) || other.styleDone == styleDone)&&(identical(other.wardrobeCount, wardrobeCount) || other.wardrobeCount == wardrobeCount)&&(identical(other.makeoverTried, makeoverTried) || other.makeoverTried == makeoverTried));
}


@override
int get hashCode {
    return Object.hash(runtimeType,photoDone,styleDone,wardrobeCount,makeoverTried);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'GuideProgress(photoDone: $photoDone, styleDone: $styleDone, wardrobeCount: $wardrobeCount, makeoverTried: $makeoverTried)';
}


}

/// @nodoc
abstract mixin class _$GuideProgressCopyWith<$Res> implements $GuideProgressCopyWith<$Res> {
  factory _$GuideProgressCopyWith(_GuideProgress value, $Res Function(_GuideProgress) _then) = __$GuideProgressCopyWithImpl;
@override @useResult
$Res call({
 bool photoDone, bool styleDone, int wardrobeCount, bool makeoverTried
});




}
/// @nodoc
class __$GuideProgressCopyWithImpl<$Res>
    implements _$GuideProgressCopyWith<$Res> {
  __$GuideProgressCopyWithImpl(this._self, this._then);

  final _GuideProgress _self;
  final $Res Function(_GuideProgress) _then;

/// Create a copy of GuideProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? photoDone = null,Object? styleDone = null,Object? wardrobeCount = null,Object? makeoverTried = null,}) {
  return _then(_GuideProgress(
photoDone: null == photoDone ? _self.photoDone : photoDone // ignore: cast_nullable_to_non_nullable
as bool,styleDone: null == styleDone ? _self.styleDone : styleDone // ignore: cast_nullable_to_non_nullable
as bool,wardrobeCount: null == wardrobeCount ? _self.wardrobeCount : wardrobeCount // ignore: cast_nullable_to_non_nullable
as int,makeoverTried: null == makeoverTried ? _self.makeoverTried : makeoverTried // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
