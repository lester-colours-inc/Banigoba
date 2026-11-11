// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StockSummary {

 int get total; int get soldOut; int get low;
/// Create a copy of StockSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockSummaryCopyWith<StockSummary> get copyWith => _$StockSummaryCopyWithImpl<StockSummary>(this as StockSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as StockSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockSummary&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.soldOut, _this.soldOut) || other.soldOut == _this.soldOut)&&(identical(other.low, _this.low) || other.low == _this.low));
}


@override
int get hashCode {
  final _this = this as StockSummary;
  return Object.hash(runtimeType,_this.total,_this.soldOut,_this.low);
}

@override
String toString() {
  final _this = this as StockSummary;
  return 'StockSummary(total: ${_this.total}, soldOut: ${_this.soldOut}, low: ${_this.low})';
}


}

/// @nodoc
abstract mixin class $StockSummaryCopyWith<$Res>  {
  factory $StockSummaryCopyWith(StockSummary value, $Res Function(StockSummary) _then) = _$StockSummaryCopyWithImpl;
@useResult
$Res call({
 int total, int soldOut, int low
});




}
/// @nodoc
class _$StockSummaryCopyWithImpl<$Res>
    implements $StockSummaryCopyWith<$Res> {
  _$StockSummaryCopyWithImpl(this._self, this._then);

  final StockSummary _self;
  final $Res Function(StockSummary) _then;

/// Create a copy of StockSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? soldOut = null,Object? low = null,}) {
  return _then(StockSummary(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,soldOut: null == soldOut ? _self.soldOut : soldOut // ignore: cast_nullable_to_non_nullable
as int,low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StockSummary].
extension StockSummaryPatterns on StockSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockSummary value)  $default,){
final _that = this;
switch (_that) {
case _StockSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockSummary value)?  $default,){
final _that = this;
switch (_that) {
case _StockSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total,  int soldOut,  int low)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockSummary() when $default != null:
return $default(_that.total,_that.soldOut,_that.low);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total,  int soldOut,  int low)  $default,) {final _that = this;
switch (_that) {
case _StockSummary():
return $default(_that.total,_that.soldOut,_that.low);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total,  int soldOut,  int low)?  $default,) {final _that = this;
switch (_that) {
case _StockSummary() when $default != null:
return $default(_that.total,_that.soldOut,_that.low);case _:
  return null;

}
}

}

/// @nodoc


class _StockSummary extends StockSummary {
  const _StockSummary({required this.total, required this.soldOut, required this.low}): super._();
  

@override final  int total;
@override final  int soldOut;
@override final  int low;

/// Create a copy of StockSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockSummaryCopyWith<_StockSummary> get copyWith => __$StockSummaryCopyWithImpl<_StockSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockSummary&&(identical(other.total, total) || other.total == total)&&(identical(other.soldOut, soldOut) || other.soldOut == soldOut)&&(identical(other.low, low) || other.low == low));
}


@override
int get hashCode {
    return Object.hash(runtimeType,total,soldOut,low);
}

@override
String toString() {
    return 'StockSummary(total: $total, soldOut: $soldOut, low: $low)';
}


}

/// @nodoc
abstract mixin class _$StockSummaryCopyWith<$Res> implements $StockSummaryCopyWith<$Res> {
  factory _$StockSummaryCopyWith(_StockSummary value, $Res Function(_StockSummary) _then) = __$StockSummaryCopyWithImpl;
@override @useResult
$Res call({
 int total, int soldOut, int low
});




}
/// @nodoc
class __$StockSummaryCopyWithImpl<$Res>
    implements _$StockSummaryCopyWith<$Res> {
  __$StockSummaryCopyWithImpl(this._self, this._then);

  final _StockSummary _self;
  final $Res Function(_StockSummary) _then;

/// Create a copy of StockSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? soldOut = null,Object? low = null,}) {
  return _then(_StockSummary(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,soldOut: null == soldOut ? _self.soldOut : soldOut // ignore: cast_nullable_to_non_nullable
as int,low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
