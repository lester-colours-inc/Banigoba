// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'look_purchase.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShopPick implements DiagnosticableTreeMixin {

 Map<String, dynamic> get product;/// The size to add to the cart, or '' for a one-size piece.
 String get size;/// "In your size (M)", "Suits your Smart style", ...
 List<String> get reasons; int get score;
/// Create a copy of ShopPick
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopPickCopyWith<ShopPick> get copyWith => _$ShopPickCopyWithImpl<ShopPick>(this as ShopPick, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as ShopPick;
  properties
    ..add(DiagnosticsProperty('type', 'ShopPick'))
    ..add(DiagnosticsProperty('product', _this.product))..add(DiagnosticsProperty('size', _this.size))..add(DiagnosticsProperty('reasons', _this.reasons))..add(DiagnosticsProperty('score', _this.score));
}

@override
bool operator ==(Object other) {
  final _this = this as ShopPick;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopPick&&const DeepCollectionEquality().equals(other.product, _this.product)&&(identical(other.size, _this.size) || other.size == _this.size)&&const DeepCollectionEquality().equals(other.reasons, _this.reasons)&&(identical(other.score, _this.score) || other.score == _this.score));
}


@override
int get hashCode {
  final _this = this as ShopPick;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.product),_this.size,const DeepCollectionEquality().hash(_this.reasons),_this.score);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as ShopPick;
  return 'ShopPick(product: ${_this.product}, size: ${_this.size}, reasons: ${_this.reasons}, score: ${_this.score})';
}


}

/// @nodoc
abstract mixin class $ShopPickCopyWith<$Res>  {
  factory $ShopPickCopyWith(ShopPick value, $Res Function(ShopPick) _then) = _$ShopPickCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic> product, String size, List<String> reasons, int score
});




}
/// @nodoc
class _$ShopPickCopyWithImpl<$Res>
    implements $ShopPickCopyWith<$Res> {
  _$ShopPickCopyWithImpl(this._self, this._then);

  final ShopPick _self;
  final $Res Function(ShopPick) _then;

/// Create a copy of ShopPick
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? product = null,Object? size = null,Object? reasons = null,Object? score = null,}) {
  return _then(ShopPick(
product: null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,reasons: null == reasons ? _self.reasons : reasons // ignore: cast_nullable_to_non_nullable
as List<String>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ShopPick].
extension ShopPickPatterns on ShopPick {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShopPick value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShopPick() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShopPick value)  $default,){
final _that = this;
switch (_that) {
case _ShopPick():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShopPick value)?  $default,){
final _that = this;
switch (_that) {
case _ShopPick() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, dynamic> product,  String size,  List<String> reasons,  int score)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShopPick() when $default != null:
return $default(_that.product,_that.size,_that.reasons,_that.score);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, dynamic> product,  String size,  List<String> reasons,  int score)  $default,) {final _that = this;
switch (_that) {
case _ShopPick():
return $default(_that.product,_that.size,_that.reasons,_that.score);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, dynamic> product,  String size,  List<String> reasons,  int score)?  $default,) {final _that = this;
switch (_that) {
case _ShopPick() when $default != null:
return $default(_that.product,_that.size,_that.reasons,_that.score);case _:
  return null;

}
}

}

/// @nodoc


class _ShopPick extends ShopPick with DiagnosticableTreeMixin {
  const _ShopPick({required  Map<String, dynamic> product, required this.size, required  List<String> reasons, required this.score}): _product = product,_reasons = reasons,super._();
  

 final  Map<String, dynamic> _product;
@override Map<String, dynamic> get product {
  if (_product is EqualUnmodifiableMapView) return _product;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_product);
}

/// The size to add to the cart, or '' for a one-size piece.
@override final  String size;
/// "In your size (M)", "Suits your Smart style", ...
 final  List<String> _reasons;
/// "In your size (M)", "Suits your Smart style", ...
@override List<String> get reasons {
  if (_reasons is EqualUnmodifiableListView) return _reasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reasons);
}

@override final  int score;

/// Create a copy of ShopPick
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopPickCopyWith<_ShopPick> get copyWith => __$ShopPickCopyWithImpl<_ShopPick>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'ShopPick'))
    ..add(DiagnosticsProperty('product', product))..add(DiagnosticsProperty('size', size))..add(DiagnosticsProperty('reasons', reasons))..add(DiagnosticsProperty('score', score));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShopPick&&const DeepCollectionEquality().equals(other.product, _product)&&(identical(other.size, size) || other.size == size)&&const DeepCollectionEquality().equals(other.reasons, _reasons)&&(identical(other.score, score) || other.score == score));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_product),size,const DeepCollectionEquality().hash(_reasons),score);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'ShopPick(product: $product, size: $size, reasons: $reasons, score: $score)';
}


}

/// @nodoc
abstract mixin class _$ShopPickCopyWith<$Res> implements $ShopPickCopyWith<$Res> {
  factory _$ShopPickCopyWith(_ShopPick value, $Res Function(_ShopPick) _then) = __$ShopPickCopyWithImpl;
@override @useResult
$Res call({
 Map<String, dynamic> product, String size, List<String> reasons, int score
});




}
/// @nodoc
class __$ShopPickCopyWithImpl<$Res>
    implements _$ShopPickCopyWith<$Res> {
  __$ShopPickCopyWithImpl(this._self, this._then);

  final _ShopPick _self;
  final $Res Function(_ShopPick) _then;

/// Create a copy of ShopPick
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? product = null,Object? size = null,Object? reasons = null,Object? score = null,}) {
  return _then(_ShopPick(
product: null == product ? _self._product : product // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,reasons: null == reasons ? _self._reasons : reasons // ignore: cast_nullable_to_non_nullable
as List<String>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$PieceAdvice implements DiagnosticableTreeMixin {

 LookPart get part;/// Wardrobe items of the right kind.
 List<Map<String, dynamic>> get owned; List<ShopPick> get picks;
/// Create a copy of PieceAdvice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PieceAdviceCopyWith<PieceAdvice> get copyWith => _$PieceAdviceCopyWithImpl<PieceAdvice>(this as PieceAdvice, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as PieceAdvice;
  properties
    ..add(DiagnosticsProperty('type', 'PieceAdvice'))
    ..add(DiagnosticsProperty('part', _this.part))..add(DiagnosticsProperty('owned', _this.owned))..add(DiagnosticsProperty('picks', _this.picks));
}

@override
bool operator ==(Object other) {
  final _this = this as PieceAdvice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PieceAdvice&&(identical(other.part, _this.part) || other.part == _this.part)&&const DeepCollectionEquality().equals(other.owned, _this.owned)&&const DeepCollectionEquality().equals(other.picks, _this.picks));
}


@override
int get hashCode {
  final _this = this as PieceAdvice;
  return Object.hash(runtimeType,_this.part,const DeepCollectionEquality().hash(_this.owned),const DeepCollectionEquality().hash(_this.picks));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as PieceAdvice;
  return 'PieceAdvice(part: ${_this.part}, owned: ${_this.owned}, picks: ${_this.picks})';
}


}

/// @nodoc
abstract mixin class $PieceAdviceCopyWith<$Res>  {
  factory $PieceAdviceCopyWith(PieceAdvice value, $Res Function(PieceAdvice) _then) = _$PieceAdviceCopyWithImpl;
@useResult
$Res call({
 LookPart part, List<Map<String, dynamic>> owned, List<ShopPick> picks
});




}
/// @nodoc
class _$PieceAdviceCopyWithImpl<$Res>
    implements $PieceAdviceCopyWith<$Res> {
  _$PieceAdviceCopyWithImpl(this._self, this._then);

  final PieceAdvice _self;
  final $Res Function(PieceAdvice) _then;

/// Create a copy of PieceAdvice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? part = null,Object? owned = null,Object? picks = null,}) {
  return _then(PieceAdvice(
part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as LookPart,owned: null == owned ? _self.owned : owned // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,picks: null == picks ? _self.picks : picks // ignore: cast_nullable_to_non_nullable
as List<ShopPick>,
  ));
}

}


/// Adds pattern-matching-related methods to [PieceAdvice].
extension PieceAdvicePatterns on PieceAdvice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PieceAdvice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PieceAdvice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PieceAdvice value)  $default,){
final _that = this;
switch (_that) {
case _PieceAdvice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PieceAdvice value)?  $default,){
final _that = this;
switch (_that) {
case _PieceAdvice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LookPart part,  List<Map<String, dynamic>> owned,  List<ShopPick> picks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PieceAdvice() when $default != null:
return $default(_that.part,_that.owned,_that.picks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LookPart part,  List<Map<String, dynamic>> owned,  List<ShopPick> picks)  $default,) {final _that = this;
switch (_that) {
case _PieceAdvice():
return $default(_that.part,_that.owned,_that.picks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LookPart part,  List<Map<String, dynamic>> owned,  List<ShopPick> picks)?  $default,) {final _that = this;
switch (_that) {
case _PieceAdvice() when $default != null:
return $default(_that.part,_that.owned,_that.picks);case _:
  return null;

}
}

}

/// @nodoc


class _PieceAdvice extends PieceAdvice with DiagnosticableTreeMixin {
  const _PieceAdvice({required this.part, required  List<Map<String, dynamic>> owned, required  List<ShopPick> picks}): _owned = owned,_picks = picks,super._();
  

@override final  LookPart part;
/// Wardrobe items of the right kind.
 final  List<Map<String, dynamic>> _owned;
/// Wardrobe items of the right kind.
@override List<Map<String, dynamic>> get owned {
  if (_owned is EqualUnmodifiableListView) return _owned;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_owned);
}

 final  List<ShopPick> _picks;
@override List<ShopPick> get picks {
  if (_picks is EqualUnmodifiableListView) return _picks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_picks);
}


/// Create a copy of PieceAdvice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PieceAdviceCopyWith<_PieceAdvice> get copyWith => __$PieceAdviceCopyWithImpl<_PieceAdvice>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'PieceAdvice'))
    ..add(DiagnosticsProperty('part', part))..add(DiagnosticsProperty('owned', owned))..add(DiagnosticsProperty('picks', picks));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PieceAdvice&&(identical(other.part, part) || other.part == part)&&const DeepCollectionEquality().equals(other.owned, _owned)&&const DeepCollectionEquality().equals(other.picks, _picks));
}


@override
int get hashCode {
    return Object.hash(runtimeType,part,const DeepCollectionEquality().hash(_owned),const DeepCollectionEquality().hash(_picks));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'PieceAdvice(part: $part, owned: $owned, picks: $picks)';
}


}

/// @nodoc
abstract mixin class _$PieceAdviceCopyWith<$Res> implements $PieceAdviceCopyWith<$Res> {
  factory _$PieceAdviceCopyWith(_PieceAdvice value, $Res Function(_PieceAdvice) _then) = __$PieceAdviceCopyWithImpl;
@override @useResult
$Res call({
 LookPart part, List<Map<String, dynamic>> owned, List<ShopPick> picks
});




}
/// @nodoc
class __$PieceAdviceCopyWithImpl<$Res>
    implements _$PieceAdviceCopyWith<$Res> {
  __$PieceAdviceCopyWithImpl(this._self, this._then);

  final _PieceAdvice _self;
  final $Res Function(_PieceAdvice) _then;

/// Create a copy of PieceAdvice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? part = null,Object? owned = null,Object? picks = null,}) {
  return _then(_PieceAdvice(
part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as LookPart,owned: null == owned ? _self._owned : owned // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,picks: null == picks ? _self._picks : picks // ignore: cast_nullable_to_non_nullable
as List<ShopPick>,
  ));
}


}

// dart format on
