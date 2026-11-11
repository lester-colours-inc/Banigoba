// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeliverySettings implements DiagnosticableTreeMixin {

 bool get delivers; double get fee;/// Areas the shop covers. Empty means anywhere the buyer gives an address.
 List<String> get areas; String get note;
/// Create a copy of DeliverySettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliverySettingsCopyWith<DeliverySettings> get copyWith => _$DeliverySettingsCopyWithImpl<DeliverySettings>(this as DeliverySettings, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as DeliverySettings;
  properties
    ..add(DiagnosticsProperty('type', 'DeliverySettings'))
    ..add(DiagnosticsProperty('delivers', _this.delivers))..add(DiagnosticsProperty('fee', _this.fee))..add(DiagnosticsProperty('areas', _this.areas))..add(DiagnosticsProperty('note', _this.note));
}

@override
bool operator ==(Object other) {
  final _this = this as DeliverySettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliverySettings&&(identical(other.delivers, _this.delivers) || other.delivers == _this.delivers)&&(identical(other.fee, _this.fee) || other.fee == _this.fee)&&const DeepCollectionEquality().equals(other.areas, _this.areas)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as DeliverySettings;
  return Object.hash(runtimeType,_this.delivers,_this.fee,const DeepCollectionEquality().hash(_this.areas),_this.note);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as DeliverySettings;
  return 'DeliverySettings(delivers: ${_this.delivers}, fee: ${_this.fee}, areas: ${_this.areas}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $DeliverySettingsCopyWith<$Res>  {
  factory $DeliverySettingsCopyWith(DeliverySettings value, $Res Function(DeliverySettings) _then) = _$DeliverySettingsCopyWithImpl;
@useResult
$Res call({
 bool delivers, double fee, List<String> areas, String note
});




}
/// @nodoc
class _$DeliverySettingsCopyWithImpl<$Res>
    implements $DeliverySettingsCopyWith<$Res> {
  _$DeliverySettingsCopyWithImpl(this._self, this._then);

  final DeliverySettings _self;
  final $Res Function(DeliverySettings) _then;

/// Create a copy of DeliverySettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? delivers = null,Object? fee = null,Object? areas = null,Object? note = null,}) {
  return _then(DeliverySettings(
delivers: null == delivers ? _self.delivers : delivers // ignore: cast_nullable_to_non_nullable
as bool,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as double,areas: null == areas ? _self.areas : areas // ignore: cast_nullable_to_non_nullable
as List<String>,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DeliverySettings].
extension DeliverySettingsPatterns on DeliverySettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliverySettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliverySettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliverySettings value)  $default,){
final _that = this;
switch (_that) {
case _DeliverySettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliverySettings value)?  $default,){
final _that = this;
switch (_that) {
case _DeliverySettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool delivers,  double fee,  List<String> areas,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliverySettings() when $default != null:
return $default(_that.delivers,_that.fee,_that.areas,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool delivers,  double fee,  List<String> areas,  String note)  $default,) {final _that = this;
switch (_that) {
case _DeliverySettings():
return $default(_that.delivers,_that.fee,_that.areas,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool delivers,  double fee,  List<String> areas,  String note)?  $default,) {final _that = this;
switch (_that) {
case _DeliverySettings() when $default != null:
return $default(_that.delivers,_that.fee,_that.areas,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _DeliverySettings extends DeliverySettings with DiagnosticableTreeMixin {
  const _DeliverySettings({this.delivers = false, this.fee = 0,  List<String> areas = const [], this.note = ''}): _areas = areas,super._();
  

@override@JsonKey() final  bool delivers;
@override@JsonKey() final  double fee;
/// Areas the shop covers. Empty means anywhere the buyer gives an address.
 final  List<String> _areas;
/// Areas the shop covers. Empty means anywhere the buyer gives an address.
@override@JsonKey() List<String> get areas {
  if (_areas is EqualUnmodifiableListView) return _areas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_areas);
}

@override@JsonKey() final  String note;

/// Create a copy of DeliverySettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliverySettingsCopyWith<_DeliverySettings> get copyWith => __$DeliverySettingsCopyWithImpl<_DeliverySettings>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'DeliverySettings'))
    ..add(DiagnosticsProperty('delivers', delivers))..add(DiagnosticsProperty('fee', fee))..add(DiagnosticsProperty('areas', areas))..add(DiagnosticsProperty('note', note));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliverySettings&&(identical(other.delivers, delivers) || other.delivers == delivers)&&(identical(other.fee, fee) || other.fee == fee)&&const DeepCollectionEquality().equals(other.areas, _areas)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,delivers,fee,const DeepCollectionEquality().hash(_areas),note);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'DeliverySettings(delivers: $delivers, fee: $fee, areas: $areas, note: $note)';
}


}

/// @nodoc
abstract mixin class _$DeliverySettingsCopyWith<$Res> implements $DeliverySettingsCopyWith<$Res> {
  factory _$DeliverySettingsCopyWith(_DeliverySettings value, $Res Function(_DeliverySettings) _then) = __$DeliverySettingsCopyWithImpl;
@override @useResult
$Res call({
 bool delivers, double fee, List<String> areas, String note
});




}
/// @nodoc
class __$DeliverySettingsCopyWithImpl<$Res>
    implements _$DeliverySettingsCopyWith<$Res> {
  __$DeliverySettingsCopyWithImpl(this._self, this._then);

  final _DeliverySettings _self;
  final $Res Function(_DeliverySettings) _then;

/// Create a copy of DeliverySettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? delivers = null,Object? fee = null,Object? areas = null,Object? note = null,}) {
  return _then(_DeliverySettings(
delivers: null == delivers ? _self.delivers : delivers // ignore: cast_nullable_to_non_nullable
as bool,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as double,areas: null == areas ? _self._areas : areas // ignore: cast_nullable_to_non_nullable
as List<String>,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$OrderTotals implements DiagnosticableTreeMixin {

 double get items; double get fee;/// The platform's commission, added on top of the seller's price.
 double get commission;
/// Create a copy of OrderTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderTotalsCopyWith<OrderTotals> get copyWith => _$OrderTotalsCopyWithImpl<OrderTotals>(this as OrderTotals, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as OrderTotals;
  properties
    ..add(DiagnosticsProperty('type', 'OrderTotals'))
    ..add(DiagnosticsProperty('items', _this.items))..add(DiagnosticsProperty('fee', _this.fee))..add(DiagnosticsProperty('commission', _this.commission));
}

@override
bool operator ==(Object other) {
  final _this = this as OrderTotals;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderTotals&&(identical(other.items, _this.items) || other.items == _this.items)&&(identical(other.fee, _this.fee) || other.fee == _this.fee)&&(identical(other.commission, _this.commission) || other.commission == _this.commission));
}


@override
int get hashCode {
  final _this = this as OrderTotals;
  return Object.hash(runtimeType,_this.items,_this.fee,_this.commission);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as OrderTotals;
  return 'OrderTotals(items: ${_this.items}, fee: ${_this.fee}, commission: ${_this.commission})';
}


}

/// @nodoc
abstract mixin class $OrderTotalsCopyWith<$Res>  {
  factory $OrderTotalsCopyWith(OrderTotals value, $Res Function(OrderTotals) _then) = _$OrderTotalsCopyWithImpl;
@useResult
$Res call({
 double items, double fee, double commission
});




}
/// @nodoc
class _$OrderTotalsCopyWithImpl<$Res>
    implements $OrderTotalsCopyWith<$Res> {
  _$OrderTotalsCopyWithImpl(this._self, this._then);

  final OrderTotals _self;
  final $Res Function(OrderTotals) _then;

/// Create a copy of OrderTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? fee = null,Object? commission = null,}) {
  return _then(OrderTotals(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as double,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as double,commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderTotals].
extension OrderTotalsPatterns on OrderTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderTotals value)  $default,){
final _that = this;
switch (_that) {
case _OrderTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderTotals value)?  $default,){
final _that = this;
switch (_that) {
case _OrderTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double items,  double fee,  double commission)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderTotals() when $default != null:
return $default(_that.items,_that.fee,_that.commission);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double items,  double fee,  double commission)  $default,) {final _that = this;
switch (_that) {
case _OrderTotals():
return $default(_that.items,_that.fee,_that.commission);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double items,  double fee,  double commission)?  $default,) {final _that = this;
switch (_that) {
case _OrderTotals() when $default != null:
return $default(_that.items,_that.fee,_that.commission);case _:
  return null;

}
}

}

/// @nodoc


class _OrderTotals extends OrderTotals with DiagnosticableTreeMixin {
  const _OrderTotals({required this.items, required this.fee, this.commission = 0}): super._();
  

@override final  double items;
@override final  double fee;
/// The platform's commission, added on top of the seller's price.
@override@JsonKey() final  double commission;

/// Create a copy of OrderTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderTotalsCopyWith<_OrderTotals> get copyWith => __$OrderTotalsCopyWithImpl<_OrderTotals>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'OrderTotals'))
    ..add(DiagnosticsProperty('items', items))..add(DiagnosticsProperty('fee', fee))..add(DiagnosticsProperty('commission', commission));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderTotals&&(identical(other.items, items) || other.items == items)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.commission, commission) || other.commission == commission));
}


@override
int get hashCode {
    return Object.hash(runtimeType,items,fee,commission);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'OrderTotals(items: $items, fee: $fee, commission: $commission)';
}


}

/// @nodoc
abstract mixin class _$OrderTotalsCopyWith<$Res> implements $OrderTotalsCopyWith<$Res> {
  factory _$OrderTotalsCopyWith(_OrderTotals value, $Res Function(_OrderTotals) _then) = __$OrderTotalsCopyWithImpl;
@override @useResult
$Res call({
 double items, double fee, double commission
});




}
/// @nodoc
class __$OrderTotalsCopyWithImpl<$Res>
    implements _$OrderTotalsCopyWith<$Res> {
  __$OrderTotalsCopyWithImpl(this._self, this._then);

  final _OrderTotals _self;
  final $Res Function(_OrderTotals) _then;

/// Create a copy of OrderTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? fee = null,Object? commission = null,}) {
  return _then(_OrderTotals(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as double,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as double,commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
