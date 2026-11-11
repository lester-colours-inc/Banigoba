// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portfolio_piece.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortfolioPiece implements DiagnosticableTreeMixin {

 String get imageUrl; String get size; PieceDetails get details;
/// Create a copy of PortfolioPiece
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortfolioPieceCopyWith<PortfolioPiece> get copyWith => _$PortfolioPieceCopyWithImpl<PortfolioPiece>(this as PortfolioPiece, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as PortfolioPiece;
  properties
    ..add(DiagnosticsProperty('type', 'PortfolioPiece'))
    ..add(DiagnosticsProperty('imageUrl', _this.imageUrl))..add(DiagnosticsProperty('size', _this.size))..add(DiagnosticsProperty('details', _this.details));
}

@override
bool operator ==(Object other) {
  final _this = this as PortfolioPiece;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortfolioPiece&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.details, _this.details) || other.details == _this.details));
}


@override
int get hashCode {
  final _this = this as PortfolioPiece;
  return Object.hash(runtimeType,_this.imageUrl,_this.size,_this.details);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as PortfolioPiece;
  return 'PortfolioPiece(imageUrl: ${_this.imageUrl}, size: ${_this.size}, details: ${_this.details})';
}


}

/// @nodoc
abstract mixin class $PortfolioPieceCopyWith<$Res>  {
  factory $PortfolioPieceCopyWith(PortfolioPiece value, $Res Function(PortfolioPiece) _then) = _$PortfolioPieceCopyWithImpl;
@useResult
$Res call({
 String imageUrl, String size, PieceDetails details
});




}
/// @nodoc
class _$PortfolioPieceCopyWithImpl<$Res>
    implements $PortfolioPieceCopyWith<$Res> {
  _$PortfolioPieceCopyWithImpl(this._self, this._then);

  final PortfolioPiece _self;
  final $Res Function(PortfolioPiece) _then;

/// Create a copy of PortfolioPiece
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? imageUrl = null,Object? size = null,Object? details = null,}) {
  return _then(PortfolioPiece(
imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as PieceDetails,
  ));
}

}


/// Adds pattern-matching-related methods to [PortfolioPiece].
extension PortfolioPiecePatterns on PortfolioPiece {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortfolioPiece value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortfolioPiece() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortfolioPiece value)  $default,){
final _that = this;
switch (_that) {
case _PortfolioPiece():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortfolioPiece value)?  $default,){
final _that = this;
switch (_that) {
case _PortfolioPiece() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String imageUrl,  String size,  PieceDetails details)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortfolioPiece() when $default != null:
return $default(_that.imageUrl,_that.size,_that.details);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String imageUrl,  String size,  PieceDetails details)  $default,) {final _that = this;
switch (_that) {
case _PortfolioPiece():
return $default(_that.imageUrl,_that.size,_that.details);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String imageUrl,  String size,  PieceDetails details)?  $default,) {final _that = this;
switch (_that) {
case _PortfolioPiece() when $default != null:
return $default(_that.imageUrl,_that.size,_that.details);case _:
  return null;

}
}

}

/// @nodoc


class _PortfolioPiece extends PortfolioPiece with DiagnosticableTreeMixin {
  const _PortfolioPiece({required this.imageUrl, this.size = '', this.details = const PieceDetails()}): super._();
  

@override final  String imageUrl;
@override@JsonKey() final  String size;
@override@JsonKey() final  PieceDetails details;

/// Create a copy of PortfolioPiece
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortfolioPieceCopyWith<_PortfolioPiece> get copyWith => __$PortfolioPieceCopyWithImpl<_PortfolioPiece>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'PortfolioPiece'))
    ..add(DiagnosticsProperty('imageUrl', imageUrl))..add(DiagnosticsProperty('size', size))..add(DiagnosticsProperty('details', details));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortfolioPiece&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.size, size) || other.size == size)&&(identical(other.details, details) || other.details == details));
}


@override
int get hashCode {
    return Object.hash(runtimeType,imageUrl,size,details);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'PortfolioPiece(imageUrl: $imageUrl, size: $size, details: $details)';
}


}

/// @nodoc
abstract mixin class _$PortfolioPieceCopyWith<$Res> implements $PortfolioPieceCopyWith<$Res> {
  factory _$PortfolioPieceCopyWith(_PortfolioPiece value, $Res Function(_PortfolioPiece) _then) = __$PortfolioPieceCopyWithImpl;
@override @useResult
$Res call({
 String imageUrl, String size, PieceDetails details
});




}
/// @nodoc
class __$PortfolioPieceCopyWithImpl<$Res>
    implements _$PortfolioPieceCopyWith<$Res> {
  __$PortfolioPieceCopyWithImpl(this._self, this._then);

  final _PortfolioPiece _self;
  final $Res Function(_PortfolioPiece) _then;

/// Create a copy of PortfolioPiece
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? imageUrl = null,Object? size = null,Object? details = null,}) {
  return _then(_PortfolioPiece(
imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as PieceDetails,
  ));
}


}

// dart format on
