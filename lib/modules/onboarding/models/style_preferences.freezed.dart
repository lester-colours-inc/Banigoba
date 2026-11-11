// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'style_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StylePreferences implements DiagnosticableTreeMixin {

 List<String> get styles; MakeoverFocus? get focus;
/// Create a copy of StylePreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StylePreferencesCopyWith<StylePreferences> get copyWith => _$StylePreferencesCopyWithImpl<StylePreferences>(this as StylePreferences, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as StylePreferences;
  properties
    ..add(DiagnosticsProperty('type', 'StylePreferences'))
    ..add(DiagnosticsProperty('styles', _this.styles))..add(DiagnosticsProperty('focus', _this.focus));
}

@override
bool operator ==(Object other) {
  final _this = this as StylePreferences;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StylePreferences&&const DeepCollectionEquality().equals(other.styles, _this.styles)&&(identical(other.focus, _this.focus) || other.focus == _this.focus));
}


@override
int get hashCode {
  final _this = this as StylePreferences;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.styles),_this.focus);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as StylePreferences;
  return 'StylePreferences(styles: ${_this.styles}, focus: ${_this.focus})';
}


}

/// @nodoc
abstract mixin class $StylePreferencesCopyWith<$Res>  {
  factory $StylePreferencesCopyWith(StylePreferences value, $Res Function(StylePreferences) _then) = _$StylePreferencesCopyWithImpl;
@useResult
$Res call({
 List<String> styles, MakeoverFocus? focus
});




}
/// @nodoc
class _$StylePreferencesCopyWithImpl<$Res>
    implements $StylePreferencesCopyWith<$Res> {
  _$StylePreferencesCopyWithImpl(this._self, this._then);

  final StylePreferences _self;
  final $Res Function(StylePreferences) _then;

/// Create a copy of StylePreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? styles = null,Object? focus = freezed,}) {
  return _then(StylePreferences(
styles: null == styles ? _self.styles : styles // ignore: cast_nullable_to_non_nullable
as List<String>,focus: freezed == focus ? _self.focus : focus // ignore: cast_nullable_to_non_nullable
as MakeoverFocus?,
  ));
}

}


/// Adds pattern-matching-related methods to [StylePreferences].
extension StylePreferencesPatterns on StylePreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StylePreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StylePreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StylePreferences value)  $default,){
final _that = this;
switch (_that) {
case _StylePreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StylePreferences value)?  $default,){
final _that = this;
switch (_that) {
case _StylePreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> styles,  MakeoverFocus? focus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StylePreferences() when $default != null:
return $default(_that.styles,_that.focus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> styles,  MakeoverFocus? focus)  $default,) {final _that = this;
switch (_that) {
case _StylePreferences():
return $default(_that.styles,_that.focus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> styles,  MakeoverFocus? focus)?  $default,) {final _that = this;
switch (_that) {
case _StylePreferences() when $default != null:
return $default(_that.styles,_that.focus);case _:
  return null;

}
}

}

/// @nodoc


class _StylePreferences extends StylePreferences with DiagnosticableTreeMixin {
  const _StylePreferences({ List<String> styles = const [], this.focus}): _styles = styles,super._();
  

 final  List<String> _styles;
@override@JsonKey() List<String> get styles {
  if (_styles is EqualUnmodifiableListView) return _styles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_styles);
}

@override final  MakeoverFocus? focus;

/// Create a copy of StylePreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StylePreferencesCopyWith<_StylePreferences> get copyWith => __$StylePreferencesCopyWithImpl<_StylePreferences>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'StylePreferences'))
    ..add(DiagnosticsProperty('styles', styles))..add(DiagnosticsProperty('focus', focus));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StylePreferences&&const DeepCollectionEquality().equals(other.styles, _styles)&&(identical(other.focus, focus) || other.focus == focus));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_styles),focus);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'StylePreferences(styles: $styles, focus: $focus)';
}


}

/// @nodoc
abstract mixin class _$StylePreferencesCopyWith<$Res> implements $StylePreferencesCopyWith<$Res> {
  factory _$StylePreferencesCopyWith(_StylePreferences value, $Res Function(_StylePreferences) _then) = __$StylePreferencesCopyWithImpl;
@override @useResult
$Res call({
 List<String> styles, MakeoverFocus? focus
});




}
/// @nodoc
class __$StylePreferencesCopyWithImpl<$Res>
    implements _$StylePreferencesCopyWith<$Res> {
  __$StylePreferencesCopyWithImpl(this._self, this._then);

  final _StylePreferences _self;
  final $Res Function(_StylePreferences) _then;

/// Create a copy of StylePreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? styles = null,Object? focus = freezed,}) {
  return _then(_StylePreferences(
styles: null == styles ? _self._styles : styles // ignore: cast_nullable_to_non_nullable
as List<String>,focus: freezed == focus ? _self.focus : focus // ignore: cast_nullable_to_non_nullable
as MakeoverFocus?,
  ));
}


}

// dart format on
