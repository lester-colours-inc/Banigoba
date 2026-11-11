// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wardrobe_insights.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Insight implements DiagnosticableTreeMixin {

 InsightKind get kind;/// One plain sentence, e.g. "4 blue shirts".
 String get summary;/// The pieces it is about, so the screen can show them.
 List<String> get pieceIds;
/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsightCopyWith<Insight> get copyWith => _$InsightCopyWithImpl<Insight>(this as Insight, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as Insight;
  properties
    ..add(DiagnosticsProperty('type', 'Insight'))
    ..add(DiagnosticsProperty('kind', _this.kind))..add(DiagnosticsProperty('summary', _this.summary))..add(DiagnosticsProperty('pieceIds', _this.pieceIds));
}

@override
bool operator ==(Object other) {
  final _this = this as Insight;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Insight&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&const DeepCollectionEquality().equals(other.pieceIds, _this.pieceIds));
}


@override
int get hashCode {
  final _this = this as Insight;
  return Object.hash(runtimeType,_this.kind,_this.summary,const DeepCollectionEquality().hash(_this.pieceIds));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as Insight;
  return 'Insight(kind: ${_this.kind}, summary: ${_this.summary}, pieceIds: ${_this.pieceIds})';
}


}

/// @nodoc
abstract mixin class $InsightCopyWith<$Res>  {
  factory $InsightCopyWith(Insight value, $Res Function(Insight) _then) = _$InsightCopyWithImpl;
@useResult
$Res call({
 InsightKind kind, String summary, List<String> pieceIds
});




}
/// @nodoc
class _$InsightCopyWithImpl<$Res>
    implements $InsightCopyWith<$Res> {
  _$InsightCopyWithImpl(this._self, this._then);

  final Insight _self;
  final $Res Function(Insight) _then;

/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? summary = null,Object? pieceIds = null,}) {
  return _then(Insight(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as InsightKind,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,pieceIds: null == pieceIds ? _self.pieceIds : pieceIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Insight].
extension InsightPatterns on Insight {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Insight value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Insight() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Insight value)  $default,){
final _that = this;
switch (_that) {
case _Insight():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Insight value)?  $default,){
final _that = this;
switch (_that) {
case _Insight() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InsightKind kind,  String summary,  List<String> pieceIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Insight() when $default != null:
return $default(_that.kind,_that.summary,_that.pieceIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InsightKind kind,  String summary,  List<String> pieceIds)  $default,) {final _that = this;
switch (_that) {
case _Insight():
return $default(_that.kind,_that.summary,_that.pieceIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InsightKind kind,  String summary,  List<String> pieceIds)?  $default,) {final _that = this;
switch (_that) {
case _Insight() when $default != null:
return $default(_that.kind,_that.summary,_that.pieceIds);case _:
  return null;

}
}

}

/// @nodoc


class _Insight extends Insight with DiagnosticableTreeMixin {
  const _Insight({required this.kind, required this.summary,  List<String> pieceIds = const []}): _pieceIds = pieceIds,super._();
  

@override final  InsightKind kind;
/// One plain sentence, e.g. "4 blue shirts".
@override final  String summary;
/// The pieces it is about, so the screen can show them.
 final  List<String> _pieceIds;
/// The pieces it is about, so the screen can show them.
@override@JsonKey() List<String> get pieceIds {
  if (_pieceIds is EqualUnmodifiableListView) return _pieceIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pieceIds);
}


/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InsightCopyWith<_Insight> get copyWith => __$InsightCopyWithImpl<_Insight>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'Insight'))
    ..add(DiagnosticsProperty('kind', kind))..add(DiagnosticsProperty('summary', summary))..add(DiagnosticsProperty('pieceIds', pieceIds));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Insight&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.pieceIds, _pieceIds));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,summary,const DeepCollectionEquality().hash(_pieceIds));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'Insight(kind: $kind, summary: $summary, pieceIds: $pieceIds)';
}


}

/// @nodoc
abstract mixin class _$InsightCopyWith<$Res> implements $InsightCopyWith<$Res> {
  factory _$InsightCopyWith(_Insight value, $Res Function(_Insight) _then) = __$InsightCopyWithImpl;
@override @useResult
$Res call({
 InsightKind kind, String summary, List<String> pieceIds
});




}
/// @nodoc
class __$InsightCopyWithImpl<$Res>
    implements _$InsightCopyWith<$Res> {
  __$InsightCopyWithImpl(this._self, this._then);

  final _Insight _self;
  final $Res Function(_Insight) _then;

/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? summary = null,Object? pieceIds = null,}) {
  return _then(_Insight(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as InsightKind,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,pieceIds: null == pieceIds ? _self._pieceIds : pieceIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
