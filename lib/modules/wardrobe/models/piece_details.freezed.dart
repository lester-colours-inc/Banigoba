// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'piece_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PieceDetails implements DiagnosticableTreeMixin {

 String get shoulderMeasurement; String get heightMeasurement; String get linenType; String get madeWhere;/// Free-form details added one at a time with "Add Detail".
 List<String> get otherDetails;
/// Create a copy of PieceDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PieceDetailsCopyWith<PieceDetails> get copyWith => _$PieceDetailsCopyWithImpl<PieceDetails>(this as PieceDetails, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as PieceDetails;
  properties
    ..add(DiagnosticsProperty('type', 'PieceDetails'))
    ..add(DiagnosticsProperty('shoulderMeasurement', _this.shoulderMeasurement))..add(DiagnosticsProperty('heightMeasurement', _this.heightMeasurement))..add(DiagnosticsProperty('linenType', _this.linenType))..add(DiagnosticsProperty('madeWhere', _this.madeWhere))..add(DiagnosticsProperty('otherDetails', _this.otherDetails));
}

@override
bool operator ==(Object other) {
  final _this = this as PieceDetails;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PieceDetails&&(identical(other.shoulderMeasurement, _this.shoulderMeasurement) || other.shoulderMeasurement == _this.shoulderMeasurement)&&(identical(other.heightMeasurement, _this.heightMeasurement) || other.heightMeasurement == _this.heightMeasurement)&&(identical(other.linenType, _this.linenType) || other.linenType == _this.linenType)&&(identical(other.madeWhere, _this.madeWhere) || other.madeWhere == _this.madeWhere)&&const DeepCollectionEquality().equals(other.otherDetails, _this.otherDetails));
}


@override
int get hashCode {
  final _this = this as PieceDetails;
  return Object.hash(runtimeType,_this.shoulderMeasurement,_this.heightMeasurement,_this.linenType,_this.madeWhere,const DeepCollectionEquality().hash(_this.otherDetails));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as PieceDetails;
  return 'PieceDetails(shoulderMeasurement: ${_this.shoulderMeasurement}, heightMeasurement: ${_this.heightMeasurement}, linenType: ${_this.linenType}, madeWhere: ${_this.madeWhere}, otherDetails: ${_this.otherDetails})';
}


}

/// @nodoc
abstract mixin class $PieceDetailsCopyWith<$Res>  {
  factory $PieceDetailsCopyWith(PieceDetails value, $Res Function(PieceDetails) _then) = _$PieceDetailsCopyWithImpl;
@useResult
$Res call({
 String shoulderMeasurement, String heightMeasurement, String linenType, String madeWhere, List<String> otherDetails
});




}
/// @nodoc
class _$PieceDetailsCopyWithImpl<$Res>
    implements $PieceDetailsCopyWith<$Res> {
  _$PieceDetailsCopyWithImpl(this._self, this._then);

  final PieceDetails _self;
  final $Res Function(PieceDetails) _then;

/// Create a copy of PieceDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shoulderMeasurement = null,Object? heightMeasurement = null,Object? linenType = null,Object? madeWhere = null,Object? otherDetails = null,}) {
  return _then(PieceDetails(
shoulderMeasurement: null == shoulderMeasurement ? _self.shoulderMeasurement : shoulderMeasurement // ignore: cast_nullable_to_non_nullable
as String,heightMeasurement: null == heightMeasurement ? _self.heightMeasurement : heightMeasurement // ignore: cast_nullable_to_non_nullable
as String,linenType: null == linenType ? _self.linenType : linenType // ignore: cast_nullable_to_non_nullable
as String,madeWhere: null == madeWhere ? _self.madeWhere : madeWhere // ignore: cast_nullable_to_non_nullable
as String,otherDetails: null == otherDetails ? _self.otherDetails : otherDetails // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PieceDetails].
extension PieceDetailsPatterns on PieceDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PieceDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PieceDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PieceDetails value)  $default,){
final _that = this;
switch (_that) {
case _PieceDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PieceDetails value)?  $default,){
final _that = this;
switch (_that) {
case _PieceDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String shoulderMeasurement,  String heightMeasurement,  String linenType,  String madeWhere,  List<String> otherDetails)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PieceDetails() when $default != null:
return $default(_that.shoulderMeasurement,_that.heightMeasurement,_that.linenType,_that.madeWhere,_that.otherDetails);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String shoulderMeasurement,  String heightMeasurement,  String linenType,  String madeWhere,  List<String> otherDetails)  $default,) {final _that = this;
switch (_that) {
case _PieceDetails():
return $default(_that.shoulderMeasurement,_that.heightMeasurement,_that.linenType,_that.madeWhere,_that.otherDetails);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String shoulderMeasurement,  String heightMeasurement,  String linenType,  String madeWhere,  List<String> otherDetails)?  $default,) {final _that = this;
switch (_that) {
case _PieceDetails() when $default != null:
return $default(_that.shoulderMeasurement,_that.heightMeasurement,_that.linenType,_that.madeWhere,_that.otherDetails);case _:
  return null;

}
}

}

/// @nodoc


class _PieceDetails extends PieceDetails with DiagnosticableTreeMixin {
  const _PieceDetails({this.shoulderMeasurement = '', this.heightMeasurement = '', this.linenType = '', this.madeWhere = '',  List<String> otherDetails = const []}): _otherDetails = otherDetails,super._();
  

@override@JsonKey() final  String shoulderMeasurement;
@override@JsonKey() final  String heightMeasurement;
@override@JsonKey() final  String linenType;
@override@JsonKey() final  String madeWhere;
/// Free-form details added one at a time with "Add Detail".
 final  List<String> _otherDetails;
/// Free-form details added one at a time with "Add Detail".
@override@JsonKey() List<String> get otherDetails {
  if (_otherDetails is EqualUnmodifiableListView) return _otherDetails;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_otherDetails);
}


/// Create a copy of PieceDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PieceDetailsCopyWith<_PieceDetails> get copyWith => __$PieceDetailsCopyWithImpl<_PieceDetails>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'PieceDetails'))
    ..add(DiagnosticsProperty('shoulderMeasurement', shoulderMeasurement))..add(DiagnosticsProperty('heightMeasurement', heightMeasurement))..add(DiagnosticsProperty('linenType', linenType))..add(DiagnosticsProperty('madeWhere', madeWhere))..add(DiagnosticsProperty('otherDetails', otherDetails));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PieceDetails&&(identical(other.shoulderMeasurement, shoulderMeasurement) || other.shoulderMeasurement == shoulderMeasurement)&&(identical(other.heightMeasurement, heightMeasurement) || other.heightMeasurement == heightMeasurement)&&(identical(other.linenType, linenType) || other.linenType == linenType)&&(identical(other.madeWhere, madeWhere) || other.madeWhere == madeWhere)&&const DeepCollectionEquality().equals(other.otherDetails, _otherDetails));
}


@override
int get hashCode {
    return Object.hash(runtimeType,shoulderMeasurement,heightMeasurement,linenType,madeWhere,const DeepCollectionEquality().hash(_otherDetails));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'PieceDetails(shoulderMeasurement: $shoulderMeasurement, heightMeasurement: $heightMeasurement, linenType: $linenType, madeWhere: $madeWhere, otherDetails: $otherDetails)';
}


}

/// @nodoc
abstract mixin class _$PieceDetailsCopyWith<$Res> implements $PieceDetailsCopyWith<$Res> {
  factory _$PieceDetailsCopyWith(_PieceDetails value, $Res Function(_PieceDetails) _then) = __$PieceDetailsCopyWithImpl;
@override @useResult
$Res call({
 String shoulderMeasurement, String heightMeasurement, String linenType, String madeWhere, List<String> otherDetails
});




}
/// @nodoc
class __$PieceDetailsCopyWithImpl<$Res>
    implements _$PieceDetailsCopyWith<$Res> {
  __$PieceDetailsCopyWithImpl(this._self, this._then);

  final _PieceDetails _self;
  final $Res Function(_PieceDetails) _then;

/// Create a copy of PieceDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shoulderMeasurement = null,Object? heightMeasurement = null,Object? linenType = null,Object? madeWhere = null,Object? otherDetails = null,}) {
  return _then(_PieceDetails(
shoulderMeasurement: null == shoulderMeasurement ? _self.shoulderMeasurement : shoulderMeasurement // ignore: cast_nullable_to_non_nullable
as String,heightMeasurement: null == heightMeasurement ? _self.heightMeasurement : heightMeasurement // ignore: cast_nullable_to_non_nullable
as String,linenType: null == linenType ? _self.linenType : linenType // ignore: cast_nullable_to_non_nullable
as String,madeWhere: null == madeWhere ? _self.madeWhere : madeWhere // ignore: cast_nullable_to_non_nullable
as String,otherDetails: null == otherDetails ? _self._otherDetails : otherDetails // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
