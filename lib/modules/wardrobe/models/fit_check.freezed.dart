// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fit_check.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SizeChart implements DiagnosticableTreeMixin {

 Map<String, Map<BodyMeasurement, double>> get sizes;
/// Create a copy of SizeChart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SizeChartCopyWith<SizeChart> get copyWith => _$SizeChartCopyWithImpl<SizeChart>(this as SizeChart, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SizeChart;
  properties
    ..add(DiagnosticsProperty('type', 'SizeChart'))
    ..add(DiagnosticsProperty('sizes', _this.sizes));
}

@override
bool operator ==(Object other) {
  final _this = this as SizeChart;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SizeChart&&const DeepCollectionEquality().equals(other.sizes, _this.sizes));
}


@override
int get hashCode {
  final _this = this as SizeChart;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.sizes));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SizeChart;
  return 'SizeChart(sizes: ${_this.sizes})';
}


}

/// @nodoc
abstract mixin class $SizeChartCopyWith<$Res>  {
  factory $SizeChartCopyWith(SizeChart value, $Res Function(SizeChart) _then) = _$SizeChartCopyWithImpl;
@useResult
$Res call({
 Map<String, Map<BodyMeasurement, double>> sizes
});




}
/// @nodoc
class _$SizeChartCopyWithImpl<$Res>
    implements $SizeChartCopyWith<$Res> {
  _$SizeChartCopyWithImpl(this._self, this._then);

  final SizeChart _self;
  final $Res Function(SizeChart) _then;

/// Create a copy of SizeChart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sizes = null,}) {
  return _then(SizeChart(
null == sizes ? _self.sizes : sizes // ignore: cast_nullable_to_non_nullable
as Map<String, Map<BodyMeasurement, double>>,
  ));
}

}


/// Adds pattern-matching-related methods to [SizeChart].
extension SizeChartPatterns on SizeChart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SizeChart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SizeChart() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SizeChart value)  $default,){
final _that = this;
switch (_that) {
case _SizeChart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SizeChart value)?  $default,){
final _that = this;
switch (_that) {
case _SizeChart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, Map<BodyMeasurement, double>> sizes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SizeChart() when $default != null:
return $default(_that.sizes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, Map<BodyMeasurement, double>> sizes)  $default,) {final _that = this;
switch (_that) {
case _SizeChart():
return $default(_that.sizes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, Map<BodyMeasurement, double>> sizes)?  $default,) {final _that = this;
switch (_that) {
case _SizeChart() when $default != null:
return $default(_that.sizes);case _:
  return null;

}
}

}

/// @nodoc


class _SizeChart extends SizeChart with DiagnosticableTreeMixin {
  const _SizeChart( Map<String, Map<BodyMeasurement, double>> sizes): _sizes = sizes,super._();
  

 final  Map<String, Map<BodyMeasurement, double>> _sizes;
@override Map<String, Map<BodyMeasurement, double>> get sizes {
  if (_sizes is EqualUnmodifiableMapView) return _sizes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sizes);
}


/// Create a copy of SizeChart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SizeChartCopyWith<_SizeChart> get copyWith => __$SizeChartCopyWithImpl<_SizeChart>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SizeChart'))
    ..add(DiagnosticsProperty('sizes', sizes));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SizeChart&&const DeepCollectionEquality().equals(other.sizes, _sizes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_sizes));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SizeChart(sizes: $sizes)';
}


}

/// @nodoc
abstract mixin class _$SizeChartCopyWith<$Res> implements $SizeChartCopyWith<$Res> {
  factory _$SizeChartCopyWith(_SizeChart value, $Res Function(_SizeChart) _then) = __$SizeChartCopyWithImpl;
@override @useResult
$Res call({
 Map<String, Map<BodyMeasurement, double>> sizes
});




}
/// @nodoc
class __$SizeChartCopyWithImpl<$Res>
    implements _$SizeChartCopyWith<$Res> {
  __$SizeChartCopyWithImpl(this._self, this._then);

  final _SizeChart _self;
  final $Res Function(_SizeChart) _then;

/// Create a copy of SizeChart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sizes = null,}) {
  return _then(_SizeChart(
null == sizes ? _self._sizes : sizes // ignore: cast_nullable_to_non_nullable
as Map<String, Map<BodyMeasurement, double>>,
  ));
}


}

/// @nodoc
mixin _$FitPart implements DiagnosticableTreeMixin {

 BodyMeasurement get part; double get garmentCm; double get bodyCm; FitVerdict get verdict;
/// Create a copy of FitPart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FitPartCopyWith<FitPart> get copyWith => _$FitPartCopyWithImpl<FitPart>(this as FitPart, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as FitPart;
  properties
    ..add(DiagnosticsProperty('type', 'FitPart'))
    ..add(DiagnosticsProperty('part', _this.part))..add(DiagnosticsProperty('garmentCm', _this.garmentCm))..add(DiagnosticsProperty('bodyCm', _this.bodyCm))..add(DiagnosticsProperty('verdict', _this.verdict));
}

@override
bool operator ==(Object other) {
  final _this = this as FitPart;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FitPart&&(identical(other.part, _this.part) || other.part == _this.part)&&(identical(other.garmentCm, _this.garmentCm) || other.garmentCm == _this.garmentCm)&&(identical(other.bodyCm, _this.bodyCm) || other.bodyCm == _this.bodyCm)&&(identical(other.verdict, _this.verdict) || other.verdict == _this.verdict));
}


@override
int get hashCode {
  final _this = this as FitPart;
  return Object.hash(runtimeType,_this.part,_this.garmentCm,_this.bodyCm,_this.verdict);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as FitPart;
  return 'FitPart(part: ${_this.part}, garmentCm: ${_this.garmentCm}, bodyCm: ${_this.bodyCm}, verdict: ${_this.verdict})';
}


}

/// @nodoc
abstract mixin class $FitPartCopyWith<$Res>  {
  factory $FitPartCopyWith(FitPart value, $Res Function(FitPart) _then) = _$FitPartCopyWithImpl;
@useResult
$Res call({
 BodyMeasurement part, double garmentCm, double bodyCm, FitVerdict verdict
});




}
/// @nodoc
class _$FitPartCopyWithImpl<$Res>
    implements $FitPartCopyWith<$Res> {
  _$FitPartCopyWithImpl(this._self, this._then);

  final FitPart _self;
  final $Res Function(FitPart) _then;

/// Create a copy of FitPart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? part = null,Object? garmentCm = null,Object? bodyCm = null,Object? verdict = null,}) {
  return _then(FitPart(
part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as BodyMeasurement,garmentCm: null == garmentCm ? _self.garmentCm : garmentCm // ignore: cast_nullable_to_non_nullable
as double,bodyCm: null == bodyCm ? _self.bodyCm : bodyCm // ignore: cast_nullable_to_non_nullable
as double,verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as FitVerdict,
  ));
}

}


/// Adds pattern-matching-related methods to [FitPart].
extension FitPartPatterns on FitPart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FitPart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FitPart() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FitPart value)  $default,){
final _that = this;
switch (_that) {
case _FitPart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FitPart value)?  $default,){
final _that = this;
switch (_that) {
case _FitPart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BodyMeasurement part,  double garmentCm,  double bodyCm,  FitVerdict verdict)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FitPart() when $default != null:
return $default(_that.part,_that.garmentCm,_that.bodyCm,_that.verdict);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BodyMeasurement part,  double garmentCm,  double bodyCm,  FitVerdict verdict)  $default,) {final _that = this;
switch (_that) {
case _FitPart():
return $default(_that.part,_that.garmentCm,_that.bodyCm,_that.verdict);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BodyMeasurement part,  double garmentCm,  double bodyCm,  FitVerdict verdict)?  $default,) {final _that = this;
switch (_that) {
case _FitPart() when $default != null:
return $default(_that.part,_that.garmentCm,_that.bodyCm,_that.verdict);case _:
  return null;

}
}

}

/// @nodoc


class _FitPart extends FitPart with DiagnosticableTreeMixin {
  const _FitPart({required this.part, required this.garmentCm, required this.bodyCm, required this.verdict}): super._();
  

@override final  BodyMeasurement part;
@override final  double garmentCm;
@override final  double bodyCm;
@override final  FitVerdict verdict;

/// Create a copy of FitPart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FitPartCopyWith<_FitPart> get copyWith => __$FitPartCopyWithImpl<_FitPart>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'FitPart'))
    ..add(DiagnosticsProperty('part', part))..add(DiagnosticsProperty('garmentCm', garmentCm))..add(DiagnosticsProperty('bodyCm', bodyCm))..add(DiagnosticsProperty('verdict', verdict));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FitPart&&(identical(other.part, part) || other.part == part)&&(identical(other.garmentCm, garmentCm) || other.garmentCm == garmentCm)&&(identical(other.bodyCm, bodyCm) || other.bodyCm == bodyCm)&&(identical(other.verdict, verdict) || other.verdict == verdict));
}


@override
int get hashCode {
    return Object.hash(runtimeType,part,garmentCm,bodyCm,verdict);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'FitPart(part: $part, garmentCm: $garmentCm, bodyCm: $bodyCm, verdict: $verdict)';
}


}

/// @nodoc
abstract mixin class _$FitPartCopyWith<$Res> implements $FitPartCopyWith<$Res> {
  factory _$FitPartCopyWith(_FitPart value, $Res Function(_FitPart) _then) = __$FitPartCopyWithImpl;
@override @useResult
$Res call({
 BodyMeasurement part, double garmentCm, double bodyCm, FitVerdict verdict
});




}
/// @nodoc
class __$FitPartCopyWithImpl<$Res>
    implements _$FitPartCopyWith<$Res> {
  __$FitPartCopyWithImpl(this._self, this._then);

  final _FitPart _self;
  final $Res Function(_FitPart) _then;

/// Create a copy of FitPart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? part = null,Object? garmentCm = null,Object? bodyCm = null,Object? verdict = null,}) {
  return _then(_FitPart(
part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as BodyMeasurement,garmentCm: null == garmentCm ? _self.garmentCm : garmentCm // ignore: cast_nullable_to_non_nullable
as double,bodyCm: null == bodyCm ? _self.bodyCm : bodyCm // ignore: cast_nullable_to_non_nullable
as double,verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as FitVerdict,
  ));
}


}

/// @nodoc
mixin _$FitCheck implements DiagnosticableTreeMixin {

/// The size compared, or '' when the chart covers every size.
 String get size; List<FitPart> get parts;/// The size that fits best across the chart, or null when unknown.
 String? get recommendedSize;
/// Create a copy of FitCheck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FitCheckCopyWith<FitCheck> get copyWith => _$FitCheckCopyWithImpl<FitCheck>(this as FitCheck, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as FitCheck;
  properties
    ..add(DiagnosticsProperty('type', 'FitCheck'))
    ..add(DiagnosticsProperty('size', _this.size))..add(DiagnosticsProperty('parts', _this.parts))..add(DiagnosticsProperty('recommendedSize', _this.recommendedSize));
}

@override
bool operator ==(Object other) {
  final _this = this as FitCheck;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FitCheck&&(identical(other.size, _this.size) || other.size == _this.size)&&const DeepCollectionEquality().equals(other.parts, _this.parts)&&(identical(other.recommendedSize, _this.recommendedSize) || other.recommendedSize == _this.recommendedSize));
}


@override
int get hashCode {
  final _this = this as FitCheck;
  return Object.hash(runtimeType,_this.size,const DeepCollectionEquality().hash(_this.parts),_this.recommendedSize);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as FitCheck;
  return 'FitCheck(size: ${_this.size}, parts: ${_this.parts}, recommendedSize: ${_this.recommendedSize})';
}


}

/// @nodoc
abstract mixin class $FitCheckCopyWith<$Res>  {
  factory $FitCheckCopyWith(FitCheck value, $Res Function(FitCheck) _then) = _$FitCheckCopyWithImpl;
@useResult
$Res call({
 String size, List<FitPart> parts, String? recommendedSize
});




}
/// @nodoc
class _$FitCheckCopyWithImpl<$Res>
    implements $FitCheckCopyWith<$Res> {
  _$FitCheckCopyWithImpl(this._self, this._then);

  final FitCheck _self;
  final $Res Function(FitCheck) _then;

/// Create a copy of FitCheck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? size = null,Object? parts = null,Object? recommendedSize = freezed,}) {
  return _then(FitCheck(
size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as List<FitPart>,recommendedSize: freezed == recommendedSize ? _self.recommendedSize : recommendedSize // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FitCheck].
extension FitCheckPatterns on FitCheck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FitCheck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FitCheck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FitCheck value)  $default,){
final _that = this;
switch (_that) {
case _FitCheck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FitCheck value)?  $default,){
final _that = this;
switch (_that) {
case _FitCheck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String size,  List<FitPart> parts,  String? recommendedSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FitCheck() when $default != null:
return $default(_that.size,_that.parts,_that.recommendedSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String size,  List<FitPart> parts,  String? recommendedSize)  $default,) {final _that = this;
switch (_that) {
case _FitCheck():
return $default(_that.size,_that.parts,_that.recommendedSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String size,  List<FitPart> parts,  String? recommendedSize)?  $default,) {final _that = this;
switch (_that) {
case _FitCheck() when $default != null:
return $default(_that.size,_that.parts,_that.recommendedSize);case _:
  return null;

}
}

}

/// @nodoc


class _FitCheck extends FitCheck with DiagnosticableTreeMixin {
  const _FitCheck({required this.size, required  List<FitPart> parts, this.recommendedSize}): _parts = parts,super._();
  

/// The size compared, or '' when the chart covers every size.
@override final  String size;
 final  List<FitPart> _parts;
@override List<FitPart> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}

/// The size that fits best across the chart, or null when unknown.
@override final  String? recommendedSize;

/// Create a copy of FitCheck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FitCheckCopyWith<_FitCheck> get copyWith => __$FitCheckCopyWithImpl<_FitCheck>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'FitCheck'))
    ..add(DiagnosticsProperty('size', size))..add(DiagnosticsProperty('parts', parts))..add(DiagnosticsProperty('recommendedSize', recommendedSize));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FitCheck&&(identical(other.size, size) || other.size == size)&&const DeepCollectionEquality().equals(other.parts, _parts)&&(identical(other.recommendedSize, recommendedSize) || other.recommendedSize == recommendedSize));
}


@override
int get hashCode {
    return Object.hash(runtimeType,size,const DeepCollectionEquality().hash(_parts),recommendedSize);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'FitCheck(size: $size, parts: $parts, recommendedSize: $recommendedSize)';
}


}

/// @nodoc
abstract mixin class _$FitCheckCopyWith<$Res> implements $FitCheckCopyWith<$Res> {
  factory _$FitCheckCopyWith(_FitCheck value, $Res Function(_FitCheck) _then) = __$FitCheckCopyWithImpl;
@override @useResult
$Res call({
 String size, List<FitPart> parts, String? recommendedSize
});




}
/// @nodoc
class __$FitCheckCopyWithImpl<$Res>
    implements _$FitCheckCopyWith<$Res> {
  __$FitCheckCopyWithImpl(this._self, this._then);

  final _FitCheck _self;
  final $Res Function(_FitCheck) _then;

/// Create a copy of FitCheck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? size = null,Object? parts = null,Object? recommendedSize = freezed,}) {
  return _then(_FitCheck(
size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<FitPart>,recommendedSize: freezed == recommendedSize ? _self.recommendedSize : recommendedSize // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
