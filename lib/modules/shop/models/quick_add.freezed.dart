// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quick_add.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuickAddDraft implements DiagnosticableTreeMixin {

 QuickKind get kind; double? get price; String get name;/// Pieces in hand per size (sized kinds only).
 Map<String, int> get sizes;/// Pieces in hand for kinds with no sizes.
 int get quantity; bool get hasPhoto;


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as QuickAddDraft;
  properties
    ..add(DiagnosticsProperty('type', 'QuickAddDraft'))
    ..add(DiagnosticsProperty('kind', _this.kind))..add(DiagnosticsProperty('price', _this.price))..add(DiagnosticsProperty('name', _this.name))..add(DiagnosticsProperty('sizes', _this.sizes))..add(DiagnosticsProperty('quantity', _this.quantity))..add(DiagnosticsProperty('hasPhoto', _this.hasPhoto));
}

@override
bool operator ==(Object other) {
  final _this = this as QuickAddDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickAddDraft&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.price, _this.price) || other.price == _this.price)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.sizes, _this.sizes)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.hasPhoto, _this.hasPhoto) || other.hasPhoto == _this.hasPhoto));
}


@override
int get hashCode {
  final _this = this as QuickAddDraft;
  return Object.hash(runtimeType,_this.kind,_this.price,_this.name,const DeepCollectionEquality().hash(_this.sizes),_this.quantity,_this.hasPhoto);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as QuickAddDraft;
  return 'QuickAddDraft(kind: ${_this.kind}, price: ${_this.price}, name: ${_this.name}, sizes: ${_this.sizes}, quantity: ${_this.quantity}, hasPhoto: ${_this.hasPhoto})';
}


}




/// Adds pattern-matching-related methods to [QuickAddDraft].
extension QuickAddDraftPatterns on QuickAddDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuickAddDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuickAddDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuickAddDraft value)  $default,){
final _that = this;
switch (_that) {
case _QuickAddDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuickAddDraft value)?  $default,){
final _that = this;
switch (_that) {
case _QuickAddDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( QuickKind kind,  double? price,  String name,  Map<String, int> sizes,  int quantity,  bool hasPhoto)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuickAddDraft() when $default != null:
return $default(_that.kind,_that.price,_that.name,_that.sizes,_that.quantity,_that.hasPhoto);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( QuickKind kind,  double? price,  String name,  Map<String, int> sizes,  int quantity,  bool hasPhoto)  $default,) {final _that = this;
switch (_that) {
case _QuickAddDraft():
return $default(_that.kind,_that.price,_that.name,_that.sizes,_that.quantity,_that.hasPhoto);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( QuickKind kind,  double? price,  String name,  Map<String, int> sizes,  int quantity,  bool hasPhoto)?  $default,) {final _that = this;
switch (_that) {
case _QuickAddDraft() when $default != null:
return $default(_that.kind,_that.price,_that.name,_that.sizes,_that.quantity,_that.hasPhoto);case _:
  return null;

}
}

}

/// @nodoc


class _QuickAddDraft extends QuickAddDraft with DiagnosticableTreeMixin {
  const _QuickAddDraft({this.kind = QuickKind.tops, this.price, this.name = '',  Map<String, int> sizes = const {}, this.quantity = 1, this.hasPhoto = false}): _sizes = sizes,super._();
  

@override@JsonKey() final  QuickKind kind;
@override final  double? price;
@override@JsonKey() final  String name;
/// Pieces in hand per size (sized kinds only).
 final  Map<String, int> _sizes;
/// Pieces in hand per size (sized kinds only).
@override@JsonKey() Map<String, int> get sizes {
  if (_sizes is EqualUnmodifiableMapView) return _sizes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sizes);
}

/// Pieces in hand for kinds with no sizes.
@override@JsonKey() final  int quantity;
@override@JsonKey() final  bool hasPhoto;



@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'QuickAddDraft'))
    ..add(DiagnosticsProperty('kind', kind))..add(DiagnosticsProperty('price', price))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('sizes', sizes))..add(DiagnosticsProperty('quantity', quantity))..add(DiagnosticsProperty('hasPhoto', hasPhoto));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuickAddDraft&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.price, price) || other.price == price)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.sizes, _sizes)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.hasPhoto, hasPhoto) || other.hasPhoto == hasPhoto));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,price,name,const DeepCollectionEquality().hash(_sizes),quantity,hasPhoto);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'QuickAddDraft(kind: $kind, price: $price, name: $name, sizes: $sizes, quantity: $quantity, hasPhoto: $hasPhoto)';
}


}




// dart format on
