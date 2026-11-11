// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ledger_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LedgerSummary implements DiagnosticableTreeMixin {

 double get owedDue; double get owedPending; double get owedSettled; double get earnedDue; double get earnedPending; double get earnedSettled;/// How many sales the entries come from.
 int get sales;
/// Create a copy of LedgerSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LedgerSummaryCopyWith<LedgerSummary> get copyWith => _$LedgerSummaryCopyWithImpl<LedgerSummary>(this as LedgerSummary, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as LedgerSummary;
  properties
    ..add(DiagnosticsProperty('type', 'LedgerSummary'))
    ..add(DiagnosticsProperty('owedDue', _this.owedDue))..add(DiagnosticsProperty('owedPending', _this.owedPending))..add(DiagnosticsProperty('owedSettled', _this.owedSettled))..add(DiagnosticsProperty('earnedDue', _this.earnedDue))..add(DiagnosticsProperty('earnedPending', _this.earnedPending))..add(DiagnosticsProperty('earnedSettled', _this.earnedSettled))..add(DiagnosticsProperty('sales', _this.sales));
}

@override
bool operator ==(Object other) {
  final _this = this as LedgerSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LedgerSummary&&(identical(other.owedDue, _this.owedDue) || other.owedDue == _this.owedDue)&&(identical(other.owedPending, _this.owedPending) || other.owedPending == _this.owedPending)&&(identical(other.owedSettled, _this.owedSettled) || other.owedSettled == _this.owedSettled)&&(identical(other.earnedDue, _this.earnedDue) || other.earnedDue == _this.earnedDue)&&(identical(other.earnedPending, _this.earnedPending) || other.earnedPending == _this.earnedPending)&&(identical(other.earnedSettled, _this.earnedSettled) || other.earnedSettled == _this.earnedSettled)&&(identical(other.sales, _this.sales) || other.sales == _this.sales));
}


@override
int get hashCode {
  final _this = this as LedgerSummary;
  return Object.hash(runtimeType,_this.owedDue,_this.owedPending,_this.owedSettled,_this.earnedDue,_this.earnedPending,_this.earnedSettled,_this.sales);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as LedgerSummary;
  return 'LedgerSummary(owedDue: ${_this.owedDue}, owedPending: ${_this.owedPending}, owedSettled: ${_this.owedSettled}, earnedDue: ${_this.earnedDue}, earnedPending: ${_this.earnedPending}, earnedSettled: ${_this.earnedSettled}, sales: ${_this.sales})';
}


}

/// @nodoc
abstract mixin class $LedgerSummaryCopyWith<$Res>  {
  factory $LedgerSummaryCopyWith(LedgerSummary value, $Res Function(LedgerSummary) _then) = _$LedgerSummaryCopyWithImpl;
@useResult
$Res call({
 double owedDue, double owedPending, double owedSettled, double earnedDue, double earnedPending, double earnedSettled, int sales
});




}
/// @nodoc
class _$LedgerSummaryCopyWithImpl<$Res>
    implements $LedgerSummaryCopyWith<$Res> {
  _$LedgerSummaryCopyWithImpl(this._self, this._then);

  final LedgerSummary _self;
  final $Res Function(LedgerSummary) _then;

/// Create a copy of LedgerSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owedDue = null,Object? owedPending = null,Object? owedSettled = null,Object? earnedDue = null,Object? earnedPending = null,Object? earnedSettled = null,Object? sales = null,}) {
  return _then(LedgerSummary(
owedDue: null == owedDue ? _self.owedDue : owedDue // ignore: cast_nullable_to_non_nullable
as double,owedPending: null == owedPending ? _self.owedPending : owedPending // ignore: cast_nullable_to_non_nullable
as double,owedSettled: null == owedSettled ? _self.owedSettled : owedSettled // ignore: cast_nullable_to_non_nullable
as double,earnedDue: null == earnedDue ? _self.earnedDue : earnedDue // ignore: cast_nullable_to_non_nullable
as double,earnedPending: null == earnedPending ? _self.earnedPending : earnedPending // ignore: cast_nullable_to_non_nullable
as double,earnedSettled: null == earnedSettled ? _self.earnedSettled : earnedSettled // ignore: cast_nullable_to_non_nullable
as double,sales: null == sales ? _self.sales : sales // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LedgerSummary].
extension LedgerSummaryPatterns on LedgerSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LedgerSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LedgerSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LedgerSummary value)  $default,){
final _that = this;
switch (_that) {
case _LedgerSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LedgerSummary value)?  $default,){
final _that = this;
switch (_that) {
case _LedgerSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double owedDue,  double owedPending,  double owedSettled,  double earnedDue,  double earnedPending,  double earnedSettled,  int sales)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LedgerSummary() when $default != null:
return $default(_that.owedDue,_that.owedPending,_that.owedSettled,_that.earnedDue,_that.earnedPending,_that.earnedSettled,_that.sales);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double owedDue,  double owedPending,  double owedSettled,  double earnedDue,  double earnedPending,  double earnedSettled,  int sales)  $default,) {final _that = this;
switch (_that) {
case _LedgerSummary():
return $default(_that.owedDue,_that.owedPending,_that.owedSettled,_that.earnedDue,_that.earnedPending,_that.earnedSettled,_that.sales);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double owedDue,  double owedPending,  double owedSettled,  double earnedDue,  double earnedPending,  double earnedSettled,  int sales)?  $default,) {final _that = this;
switch (_that) {
case _LedgerSummary() when $default != null:
return $default(_that.owedDue,_that.owedPending,_that.owedSettled,_that.earnedDue,_that.earnedPending,_that.earnedSettled,_that.sales);case _:
  return null;

}
}

}

/// @nodoc


class _LedgerSummary extends LedgerSummary with DiagnosticableTreeMixin {
  const _LedgerSummary({this.owedDue = 0, this.owedPending = 0, this.owedSettled = 0, this.earnedDue = 0, this.earnedPending = 0, this.earnedSettled = 0, this.sales = 0}): super._();
  

@override@JsonKey() final  double owedDue;
@override@JsonKey() final  double owedPending;
@override@JsonKey() final  double owedSettled;
@override@JsonKey() final  double earnedDue;
@override@JsonKey() final  double earnedPending;
@override@JsonKey() final  double earnedSettled;
/// How many sales the entries come from.
@override@JsonKey() final  int sales;

/// Create a copy of LedgerSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LedgerSummaryCopyWith<_LedgerSummary> get copyWith => __$LedgerSummaryCopyWithImpl<_LedgerSummary>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'LedgerSummary'))
    ..add(DiagnosticsProperty('owedDue', owedDue))..add(DiagnosticsProperty('owedPending', owedPending))..add(DiagnosticsProperty('owedSettled', owedSettled))..add(DiagnosticsProperty('earnedDue', earnedDue))..add(DiagnosticsProperty('earnedPending', earnedPending))..add(DiagnosticsProperty('earnedSettled', earnedSettled))..add(DiagnosticsProperty('sales', sales));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LedgerSummary&&(identical(other.owedDue, owedDue) || other.owedDue == owedDue)&&(identical(other.owedPending, owedPending) || other.owedPending == owedPending)&&(identical(other.owedSettled, owedSettled) || other.owedSettled == owedSettled)&&(identical(other.earnedDue, earnedDue) || other.earnedDue == earnedDue)&&(identical(other.earnedPending, earnedPending) || other.earnedPending == earnedPending)&&(identical(other.earnedSettled, earnedSettled) || other.earnedSettled == earnedSettled)&&(identical(other.sales, sales) || other.sales == sales));
}


@override
int get hashCode {
    return Object.hash(runtimeType,owedDue,owedPending,owedSettled,earnedDue,earnedPending,earnedSettled,sales);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'LedgerSummary(owedDue: $owedDue, owedPending: $owedPending, owedSettled: $owedSettled, earnedDue: $earnedDue, earnedPending: $earnedPending, earnedSettled: $earnedSettled, sales: $sales)';
}


}

/// @nodoc
abstract mixin class _$LedgerSummaryCopyWith<$Res> implements $LedgerSummaryCopyWith<$Res> {
  factory _$LedgerSummaryCopyWith(_LedgerSummary value, $Res Function(_LedgerSummary) _then) = __$LedgerSummaryCopyWithImpl;
@override @useResult
$Res call({
 double owedDue, double owedPending, double owedSettled, double earnedDue, double earnedPending, double earnedSettled, int sales
});




}
/// @nodoc
class __$LedgerSummaryCopyWithImpl<$Res>
    implements _$LedgerSummaryCopyWith<$Res> {
  __$LedgerSummaryCopyWithImpl(this._self, this._then);

  final _LedgerSummary _self;
  final $Res Function(_LedgerSummary) _then;

/// Create a copy of LedgerSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owedDue = null,Object? owedPending = null,Object? owedSettled = null,Object? earnedDue = null,Object? earnedPending = null,Object? earnedSettled = null,Object? sales = null,}) {
  return _then(_LedgerSummary(
owedDue: null == owedDue ? _self.owedDue : owedDue // ignore: cast_nullable_to_non_nullable
as double,owedPending: null == owedPending ? _self.owedPending : owedPending // ignore: cast_nullable_to_non_nullable
as double,owedSettled: null == owedSettled ? _self.owedSettled : owedSettled // ignore: cast_nullable_to_non_nullable
as double,earnedDue: null == earnedDue ? _self.earnedDue : earnedDue // ignore: cast_nullable_to_non_nullable
as double,earnedPending: null == earnedPending ? _self.earnedPending : earnedPending // ignore: cast_nullable_to_non_nullable
as double,earnedSettled: null == earnedSettled ? _self.earnedSettled : earnedSettled // ignore: cast_nullable_to_non_nullable
as double,sales: null == sales ? _self.sales : sales // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
