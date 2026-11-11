// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'look_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LookSession implements DiagnosticableTreeMixin {

/// The image the first step builds on.
 String get originalUrl;/// The steps, in order.
 List<LookPart> get parts;/// One entry per decided step: the image after it, or '' when skipped.
 List<String> get results;/// The image made for the current step, waiting to be kept or redone.
 String get pendingUrl;
/// Create a copy of LookSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LookSessionCopyWith<LookSession> get copyWith => _$LookSessionCopyWithImpl<LookSession>(this as LookSession, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as LookSession;
  properties
    ..add(DiagnosticsProperty('type', 'LookSession'))
    ..add(DiagnosticsProperty('originalUrl', _this.originalUrl))..add(DiagnosticsProperty('parts', _this.parts))..add(DiagnosticsProperty('results', _this.results))..add(DiagnosticsProperty('pendingUrl', _this.pendingUrl));
}

@override
bool operator ==(Object other) {
  final _this = this as LookSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LookSession&&(identical(other.originalUrl, _this.originalUrl) || other.originalUrl == _this.originalUrl)&&const DeepCollectionEquality().equals(other.parts, _this.parts)&&const DeepCollectionEquality().equals(other.results, _this.results)&&(identical(other.pendingUrl, _this.pendingUrl) || other.pendingUrl == _this.pendingUrl));
}


@override
int get hashCode {
  final _this = this as LookSession;
  return Object.hash(runtimeType,_this.originalUrl,const DeepCollectionEquality().hash(_this.parts),const DeepCollectionEquality().hash(_this.results),_this.pendingUrl);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as LookSession;
  return 'LookSession(originalUrl: ${_this.originalUrl}, parts: ${_this.parts}, results: ${_this.results}, pendingUrl: ${_this.pendingUrl})';
}


}

/// @nodoc
abstract mixin class $LookSessionCopyWith<$Res>  {
  factory $LookSessionCopyWith(LookSession value, $Res Function(LookSession) _then) = _$LookSessionCopyWithImpl;
@useResult
$Res call({
 String originalUrl, List<LookPart> parts, List<String> results, String pendingUrl
});




}
/// @nodoc
class _$LookSessionCopyWithImpl<$Res>
    implements $LookSessionCopyWith<$Res> {
  _$LookSessionCopyWithImpl(this._self, this._then);

  final LookSession _self;
  final $Res Function(LookSession) _then;

/// Create a copy of LookSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? originalUrl = null,Object? parts = null,Object? results = null,Object? pendingUrl = null,}) {
  return _then(LookSession(
originalUrl: null == originalUrl ? _self.originalUrl : originalUrl // ignore: cast_nullable_to_non_nullable
as String,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as List<LookPart>,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<String>,pendingUrl: null == pendingUrl ? _self.pendingUrl : pendingUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LookSession].
extension LookSessionPatterns on LookSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LookSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LookSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LookSession value)  $default,){
final _that = this;
switch (_that) {
case _LookSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LookSession value)?  $default,){
final _that = this;
switch (_that) {
case _LookSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String originalUrl,  List<LookPart> parts,  List<String> results,  String pendingUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LookSession() when $default != null:
return $default(_that.originalUrl,_that.parts,_that.results,_that.pendingUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String originalUrl,  List<LookPart> parts,  List<String> results,  String pendingUrl)  $default,) {final _that = this;
switch (_that) {
case _LookSession():
return $default(_that.originalUrl,_that.parts,_that.results,_that.pendingUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String originalUrl,  List<LookPart> parts,  List<String> results,  String pendingUrl)?  $default,) {final _that = this;
switch (_that) {
case _LookSession() when $default != null:
return $default(_that.originalUrl,_that.parts,_that.results,_that.pendingUrl);case _:
  return null;

}
}

}

/// @nodoc


class _LookSession extends LookSession with DiagnosticableTreeMixin {
  const _LookSession({required this.originalUrl, required  List<LookPart> parts,  List<String> results = const [], this.pendingUrl = ''}): _parts = parts,_results = results,super._();
  

/// The image the first step builds on.
@override final  String originalUrl;
/// The steps, in order.
 final  List<LookPart> _parts;
/// The steps, in order.
@override List<LookPart> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}

/// One entry per decided step: the image after it, or '' when skipped.
 final  List<String> _results;
/// One entry per decided step: the image after it, or '' when skipped.
@override@JsonKey() List<String> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

/// The image made for the current step, waiting to be kept or redone.
@override@JsonKey() final  String pendingUrl;

/// Create a copy of LookSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LookSessionCopyWith<_LookSession> get copyWith => __$LookSessionCopyWithImpl<_LookSession>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'LookSession'))
    ..add(DiagnosticsProperty('originalUrl', originalUrl))..add(DiagnosticsProperty('parts', parts))..add(DiagnosticsProperty('results', results))..add(DiagnosticsProperty('pendingUrl', pendingUrl));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LookSession&&(identical(other.originalUrl, originalUrl) || other.originalUrl == originalUrl)&&const DeepCollectionEquality().equals(other.parts, _parts)&&const DeepCollectionEquality().equals(other.results, _results)&&(identical(other.pendingUrl, pendingUrl) || other.pendingUrl == pendingUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,originalUrl,const DeepCollectionEquality().hash(_parts),const DeepCollectionEquality().hash(_results),pendingUrl);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'LookSession(originalUrl: $originalUrl, parts: $parts, results: $results, pendingUrl: $pendingUrl)';
}


}

/// @nodoc
abstract mixin class _$LookSessionCopyWith<$Res> implements $LookSessionCopyWith<$Res> {
  factory _$LookSessionCopyWith(_LookSession value, $Res Function(_LookSession) _then) = __$LookSessionCopyWithImpl;
@override @useResult
$Res call({
 String originalUrl, List<LookPart> parts, List<String> results, String pendingUrl
});




}
/// @nodoc
class __$LookSessionCopyWithImpl<$Res>
    implements _$LookSessionCopyWith<$Res> {
  __$LookSessionCopyWithImpl(this._self, this._then);

  final _LookSession _self;
  final $Res Function(_LookSession) _then;

/// Create a copy of LookSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? originalUrl = null,Object? parts = null,Object? results = null,Object? pendingUrl = null,}) {
  return _then(_LookSession(
originalUrl: null == originalUrl ? _self.originalUrl : originalUrl // ignore: cast_nullable_to_non_nullable
as String,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<LookPart>,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<String>,pendingUrl: null == pendingUrl ? _self.pendingUrl : pendingUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
