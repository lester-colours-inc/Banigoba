// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'packing_outfit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PackingOutfit {

 String get id; Map<String, dynamic> get data;
/// Create a copy of PackingOutfit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PackingOutfitCopyWith<PackingOutfit> get copyWith => _$PackingOutfitCopyWithImpl<PackingOutfit>(this as PackingOutfit, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PackingOutfit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PackingOutfit&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.data, _this.data));
}


@override
int get hashCode {
  final _this = this as PackingOutfit;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.data));
}

@override
String toString() {
  final _this = this as PackingOutfit;
  return 'PackingOutfit(id: ${_this.id}, data: ${_this.data})';
}


}

/// @nodoc
abstract mixin class $PackingOutfitCopyWith<$Res>  {
  factory $PackingOutfitCopyWith(PackingOutfit value, $Res Function(PackingOutfit) _then) = _$PackingOutfitCopyWithImpl;
@useResult
$Res call({
 String id, Map<String, dynamic> data
});




}
/// @nodoc
class _$PackingOutfitCopyWithImpl<$Res>
    implements $PackingOutfitCopyWith<$Res> {
  _$PackingOutfitCopyWithImpl(this._self, this._then);

  final PackingOutfit _self;
  final $Res Function(PackingOutfit) _then;

/// Create a copy of PackingOutfit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? data = null,}) {
  return _then(PackingOutfit(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [PackingOutfit].
extension PackingOutfitPatterns on PackingOutfit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PackingOutfit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PackingOutfit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PackingOutfit value)  $default,){
final _that = this;
switch (_that) {
case _PackingOutfit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PackingOutfit value)?  $default,){
final _that = this;
switch (_that) {
case _PackingOutfit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Map<String, dynamic> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PackingOutfit() when $default != null:
return $default(_that.id,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Map<String, dynamic> data)  $default,) {final _that = this;
switch (_that) {
case _PackingOutfit():
return $default(_that.id,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Map<String, dynamic> data)?  $default,) {final _that = this;
switch (_that) {
case _PackingOutfit() when $default != null:
return $default(_that.id,_that.data);case _:
  return null;

}
}

}

/// @nodoc


class _PackingOutfit extends PackingOutfit {
  const _PackingOutfit(this.id,  Map<String, dynamic> data): _data = data,super._();
  

@override final  String id;
 final  Map<String, dynamic> _data;
@override Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}


/// Create a copy of PackingOutfit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PackingOutfitCopyWith<_PackingOutfit> get copyWith => __$PackingOutfitCopyWithImpl<_PackingOutfit>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PackingOutfit&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.data, _data));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_data));
}

@override
String toString() {
    return 'PackingOutfit(id: $id, data: $data)';
}


}

/// @nodoc
abstract mixin class _$PackingOutfitCopyWith<$Res> implements $PackingOutfitCopyWith<$Res> {
  factory _$PackingOutfitCopyWith(_PackingOutfit value, $Res Function(_PackingOutfit) _then) = __$PackingOutfitCopyWithImpl;
@override @useResult
$Res call({
 String id, Map<String, dynamic> data
});




}
/// @nodoc
class __$PackingOutfitCopyWithImpl<$Res>
    implements _$PackingOutfitCopyWith<$Res> {
  __$PackingOutfitCopyWithImpl(this._self, this._then);

  final _PackingOutfit _self;
  final $Res Function(_PackingOutfit) _then;

/// Create a copy of PackingOutfit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? data = null,}) {
  return _then(_PackingOutfit(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
