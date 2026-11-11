// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_outfit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavedOutfit {

 String get id; Map<String, dynamic> get data;
/// Create a copy of SavedOutfit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedOutfitCopyWith<SavedOutfit> get copyWith => _$SavedOutfitCopyWithImpl<SavedOutfit>(this as SavedOutfit, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SavedOutfit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedOutfit&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.data, _this.data));
}


@override
int get hashCode {
  final _this = this as SavedOutfit;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.data));
}

@override
String toString() {
  final _this = this as SavedOutfit;
  return 'SavedOutfit(id: ${_this.id}, data: ${_this.data})';
}


}

/// @nodoc
abstract mixin class $SavedOutfitCopyWith<$Res>  {
  factory $SavedOutfitCopyWith(SavedOutfit value, $Res Function(SavedOutfit) _then) = _$SavedOutfitCopyWithImpl;
@useResult
$Res call({
 String id, Map<String, dynamic> data
});




}
/// @nodoc
class _$SavedOutfitCopyWithImpl<$Res>
    implements $SavedOutfitCopyWith<$Res> {
  _$SavedOutfitCopyWithImpl(this._self, this._then);

  final SavedOutfit _self;
  final $Res Function(SavedOutfit) _then;

/// Create a copy of SavedOutfit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? data = null,}) {
  return _then(SavedOutfit(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedOutfit].
extension SavedOutfitPatterns on SavedOutfit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedOutfit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedOutfit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedOutfit value)  $default,){
final _that = this;
switch (_that) {
case _SavedOutfit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedOutfit value)?  $default,){
final _that = this;
switch (_that) {
case _SavedOutfit() when $default != null:
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
case _SavedOutfit() when $default != null:
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
case _SavedOutfit():
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
case _SavedOutfit() when $default != null:
return $default(_that.id,_that.data);case _:
  return null;

}
}

}

/// @nodoc


class _SavedOutfit extends SavedOutfit {
  const _SavedOutfit(this.id,  Map<String, dynamic> data): _data = data,super._();
  

@override final  String id;
 final  Map<String, dynamic> _data;
@override Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}


/// Create a copy of SavedOutfit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedOutfitCopyWith<_SavedOutfit> get copyWith => __$SavedOutfitCopyWithImpl<_SavedOutfit>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedOutfit&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.data, _data));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_data));
}

@override
String toString() {
    return 'SavedOutfit(id: $id, data: $data)';
}


}

/// @nodoc
abstract mixin class _$SavedOutfitCopyWith<$Res> implements $SavedOutfitCopyWith<$Res> {
  factory _$SavedOutfitCopyWith(_SavedOutfit value, $Res Function(_SavedOutfit) _then) = __$SavedOutfitCopyWithImpl;
@override @useResult
$Res call({
 String id, Map<String, dynamic> data
});




}
/// @nodoc
class __$SavedOutfitCopyWithImpl<$Res>
    implements _$SavedOutfitCopyWith<$Res> {
  __$SavedOutfitCopyWithImpl(this._self, this._then);

  final _SavedOutfit _self;
  final $Res Function(_SavedOutfit) _then;

/// Create a copy of SavedOutfit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? data = null,}) {
  return _then(_SavedOutfit(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
