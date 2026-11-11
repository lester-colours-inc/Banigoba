// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wear_tracking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WearStatus implements DiagnosticableTreeMixin {

 String get label;/// True when it has gone unworn long enough to point out.
 bool get isNudge;
/// Create a copy of WearStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WearStatusCopyWith<WearStatus> get copyWith => _$WearStatusCopyWithImpl<WearStatus>(this as WearStatus, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as WearStatus;
  properties
    ..add(DiagnosticsProperty('type', 'WearStatus'))
    ..add(DiagnosticsProperty('label', _this.label))..add(DiagnosticsProperty('isNudge', _this.isNudge));
}

@override
bool operator ==(Object other) {
  final _this = this as WearStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WearStatus&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.isNudge, _this.isNudge) || other.isNudge == _this.isNudge));
}


@override
int get hashCode {
  final _this = this as WearStatus;
  return Object.hash(runtimeType,_this.label,_this.isNudge);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as WearStatus;
  return 'WearStatus(label: ${_this.label}, isNudge: ${_this.isNudge})';
}


}

/// @nodoc
abstract mixin class $WearStatusCopyWith<$Res>  {
  factory $WearStatusCopyWith(WearStatus value, $Res Function(WearStatus) _then) = _$WearStatusCopyWithImpl;
@useResult
$Res call({
 String label, bool isNudge
});




}
/// @nodoc
class _$WearStatusCopyWithImpl<$Res>
    implements $WearStatusCopyWith<$Res> {
  _$WearStatusCopyWithImpl(this._self, this._then);

  final WearStatus _self;
  final $Res Function(WearStatus) _then;

/// Create a copy of WearStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? isNudge = null,}) {
  return _then(WearStatus(
null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,isNudge: null == isNudge ? _self.isNudge : isNudge // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WearStatus].
extension WearStatusPatterns on WearStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WearStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WearStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WearStatus value)  $default,){
final _that = this;
switch (_that) {
case _WearStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WearStatus value)?  $default,){
final _that = this;
switch (_that) {
case _WearStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  bool isNudge)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WearStatus() when $default != null:
return $default(_that.label,_that.isNudge);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  bool isNudge)  $default,) {final _that = this;
switch (_that) {
case _WearStatus():
return $default(_that.label,_that.isNudge);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  bool isNudge)?  $default,) {final _that = this;
switch (_that) {
case _WearStatus() when $default != null:
return $default(_that.label,_that.isNudge);case _:
  return null;

}
}

}

/// @nodoc


class _WearStatus extends WearStatus with DiagnosticableTreeMixin {
  const _WearStatus(this.label, {this.isNudge = false}): super._();
  

@override final  String label;
/// True when it has gone unworn long enough to point out.
@override@JsonKey() final  bool isNudge;

/// Create a copy of WearStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WearStatusCopyWith<_WearStatus> get copyWith => __$WearStatusCopyWithImpl<_WearStatus>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'WearStatus'))
    ..add(DiagnosticsProperty('label', label))..add(DiagnosticsProperty('isNudge', isNudge));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WearStatus&&(identical(other.label, label) || other.label == label)&&(identical(other.isNudge, isNudge) || other.isNudge == isNudge));
}


@override
int get hashCode {
    return Object.hash(runtimeType,label,isNudge);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'WearStatus(label: $label, isNudge: $isNudge)';
}


}

/// @nodoc
abstract mixin class _$WearStatusCopyWith<$Res> implements $WearStatusCopyWith<$Res> {
  factory _$WearStatusCopyWith(_WearStatus value, $Res Function(_WearStatus) _then) = __$WearStatusCopyWithImpl;
@override @useResult
$Res call({
 String label, bool isNudge
});




}
/// @nodoc
class __$WearStatusCopyWithImpl<$Res>
    implements _$WearStatusCopyWith<$Res> {
  __$WearStatusCopyWithImpl(this._self, this._then);

  final _WearStatus _self;
  final $Res Function(_WearStatus) _then;

/// Create a copy of WearStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? isNudge = null,}) {
  return _then(_WearStatus(
null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,isNudge: null == isNudge ? _self.isNudge : isNudge // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
