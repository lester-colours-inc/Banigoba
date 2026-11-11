// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'commission.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommissionRates {

/// Fraction of the seller's price added for the platform.
 double get commission;/// Fraction of the commission paid to the referring influencer.
 double get influencerShare;
/// Create a copy of CommissionRates
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommissionRatesCopyWith<CommissionRates> get copyWith => _$CommissionRatesCopyWithImpl<CommissionRates>(this as CommissionRates, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CommissionRates;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommissionRates&&(identical(other.commission, _this.commission) || other.commission == _this.commission)&&(identical(other.influencerShare, _this.influencerShare) || other.influencerShare == _this.influencerShare));
}


@override
int get hashCode {
  final _this = this as CommissionRates;
  return Object.hash(runtimeType,_this.commission,_this.influencerShare);
}

@override
String toString() {
  final _this = this as CommissionRates;
  return 'CommissionRates(commission: ${_this.commission}, influencerShare: ${_this.influencerShare})';
}


}

/// @nodoc
abstract mixin class $CommissionRatesCopyWith<$Res>  {
  factory $CommissionRatesCopyWith(CommissionRates value, $Res Function(CommissionRates) _then) = _$CommissionRatesCopyWithImpl;
@useResult
$Res call({
 double commission, double influencerShare
});




}
/// @nodoc
class _$CommissionRatesCopyWithImpl<$Res>
    implements $CommissionRatesCopyWith<$Res> {
  _$CommissionRatesCopyWithImpl(this._self, this._then);

  final CommissionRates _self;
  final $Res Function(CommissionRates) _then;

/// Create a copy of CommissionRates
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? commission = null,Object? influencerShare = null,}) {
  return _then(CommissionRates(
commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as double,influencerShare: null == influencerShare ? _self.influencerShare : influencerShare // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CommissionRates].
extension CommissionRatesPatterns on CommissionRates {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommissionRates value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommissionRates() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommissionRates value)  $default,){
final _that = this;
switch (_that) {
case _CommissionRates():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommissionRates value)?  $default,){
final _that = this;
switch (_that) {
case _CommissionRates() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double commission,  double influencerShare)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommissionRates() when $default != null:
return $default(_that.commission,_that.influencerShare);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double commission,  double influencerShare)  $default,) {final _that = this;
switch (_that) {
case _CommissionRates():
return $default(_that.commission,_that.influencerShare);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double commission,  double influencerShare)?  $default,) {final _that = this;
switch (_that) {
case _CommissionRates() when $default != null:
return $default(_that.commission,_that.influencerShare);case _:
  return null;

}
}

}

/// @nodoc


class _CommissionRates extends CommissionRates {
  const _CommissionRates({this.commission = kDefaultCommissionRate, this.influencerShare = kDefaultInfluencerShare}): super._();
  

/// Fraction of the seller's price added for the platform.
@override@JsonKey() final  double commission;
/// Fraction of the commission paid to the referring influencer.
@override@JsonKey() final  double influencerShare;

/// Create a copy of CommissionRates
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommissionRatesCopyWith<_CommissionRates> get copyWith => __$CommissionRatesCopyWithImpl<_CommissionRates>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommissionRates&&(identical(other.commission, commission) || other.commission == commission)&&(identical(other.influencerShare, influencerShare) || other.influencerShare == influencerShare));
}


@override
int get hashCode {
    return Object.hash(runtimeType,commission,influencerShare);
}

@override
String toString() {
    return 'CommissionRates(commission: $commission, influencerShare: $influencerShare)';
}


}

/// @nodoc
abstract mixin class _$CommissionRatesCopyWith<$Res> implements $CommissionRatesCopyWith<$Res> {
  factory _$CommissionRatesCopyWith(_CommissionRates value, $Res Function(_CommissionRates) _then) = __$CommissionRatesCopyWithImpl;
@override @useResult
$Res call({
 double commission, double influencerShare
});




}
/// @nodoc
class __$CommissionRatesCopyWithImpl<$Res>
    implements _$CommissionRatesCopyWith<$Res> {
  __$CommissionRatesCopyWithImpl(this._self, this._then);

  final _CommissionRates _self;
  final $Res Function(_CommissionRates) _then;

/// Create a copy of CommissionRates
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? commission = null,Object? influencerShare = null,}) {
  return _then(_CommissionRates(
commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as double,influencerShare: null == influencerShare ? _self.influencerShare : influencerShare // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
