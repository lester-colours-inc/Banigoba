// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'geo_cell.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GeoCell {

 int get x; int get y;
/// Create a copy of GeoCell
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeoCellCopyWith<GeoCell> get copyWith => _$GeoCellCopyWithImpl<GeoCell>(this as GeoCell, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GeoCell;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeoCell&&(identical(other.x, _this.x) || other.x == _this.x)&&(identical(other.y, _this.y) || other.y == _this.y));
}


@override
int get hashCode {
  final _this = this as GeoCell;
  return Object.hash(runtimeType,_this.x,_this.y);
}



}

/// @nodoc
abstract mixin class $GeoCellCopyWith<$Res>  {
  factory $GeoCellCopyWith(GeoCell value, $Res Function(GeoCell) _then) = _$GeoCellCopyWithImpl;
@useResult
$Res call({
 int x, int y
});




}
/// @nodoc
class _$GeoCellCopyWithImpl<$Res>
    implements $GeoCellCopyWith<$Res> {
  _$GeoCellCopyWithImpl(this._self, this._then);

  final GeoCell _self;
  final $Res Function(GeoCell) _then;

/// Create a copy of GeoCell
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,}) {
  return _then(GeoCell(
null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GeoCell].
extension GeoCellPatterns on GeoCell {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeoCell value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeoCell() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeoCell value)  $default,){
final _that = this;
switch (_that) {
case _GeoCell():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeoCell value)?  $default,){
final _that = this;
switch (_that) {
case _GeoCell() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int x,  int y)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeoCell() when $default != null:
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int x,  int y)  $default,) {final _that = this;
switch (_that) {
case _GeoCell():
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int x,  int y)?  $default,) {final _that = this;
switch (_that) {
case _GeoCell() when $default != null:
return $default(_that.x,_that.y);case _:
  return null;

}
}

}

/// @nodoc


class _GeoCell extends GeoCell {
  const _GeoCell(this.x, this.y): super._();
  

@override final  int x;
@override final  int y;

/// Create a copy of GeoCell
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeoCellCopyWith<_GeoCell> get copyWith => __$GeoCellCopyWithImpl<_GeoCell>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeoCell&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}


@override
int get hashCode {
    return Object.hash(runtimeType,x,y);
}



}

/// @nodoc
abstract mixin class _$GeoCellCopyWith<$Res> implements $GeoCellCopyWith<$Res> {
  factory _$GeoCellCopyWith(_GeoCell value, $Res Function(_GeoCell) _then) = __$GeoCellCopyWithImpl;
@override @useResult
$Res call({
 int x, int y
});




}
/// @nodoc
class __$GeoCellCopyWithImpl<$Res>
    implements _$GeoCellCopyWith<$Res> {
  __$GeoCellCopyWithImpl(this._self, this._then);

  final _GeoCell _self;
  final $Res Function(_GeoCell) _then;

/// Create a copy of GeoCell
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,}) {
  return _then(_GeoCell(
null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
