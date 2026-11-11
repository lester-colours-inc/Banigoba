// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'designer_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DesignerSummary {

 String get id; String get name; String get bio; String get location; List<String> get specialties; String get priceRange; List<PortfolioPiece> get portfolioPieces; String get avatarUrl;
/// Create a copy of DesignerSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignerSummaryCopyWith<DesignerSummary> get copyWith => _$DesignerSummaryCopyWithImpl<DesignerSummary>(this as DesignerSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DesignerSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignerSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.bio, _this.bio) || other.bio == _this.bio)&&(identical(other.location, _this.location) || other.location == _this.location)&&const DeepCollectionEquality().equals(other.specialties, _this.specialties)&&(identical(other.priceRange, _this.priceRange) || other.priceRange == _this.priceRange)&&const DeepCollectionEquality().equals(other.portfolioPieces, _this.portfolioPieces)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl));
}


@override
int get hashCode {
  final _this = this as DesignerSummary;
  return Object.hash(runtimeType,_this.id,_this.name,_this.bio,_this.location,const DeepCollectionEquality().hash(_this.specialties),_this.priceRange,const DeepCollectionEquality().hash(_this.portfolioPieces),_this.avatarUrl);
}

@override
String toString() {
  final _this = this as DesignerSummary;
  return 'DesignerSummary(id: ${_this.id}, name: ${_this.name}, bio: ${_this.bio}, location: ${_this.location}, specialties: ${_this.specialties}, priceRange: ${_this.priceRange}, portfolioPieces: ${_this.portfolioPieces}, avatarUrl: ${_this.avatarUrl})';
}


}

/// @nodoc
abstract mixin class $DesignerSummaryCopyWith<$Res>  {
  factory $DesignerSummaryCopyWith(DesignerSummary value, $Res Function(DesignerSummary) _then) = _$DesignerSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String bio, String location, List<String> specialties, String priceRange, List<PortfolioPiece> portfolioPieces, String avatarUrl
});




}
/// @nodoc
class _$DesignerSummaryCopyWithImpl<$Res>
    implements $DesignerSummaryCopyWith<$Res> {
  _$DesignerSummaryCopyWithImpl(this._self, this._then);

  final DesignerSummary _self;
  final $Res Function(DesignerSummary) _then;

/// Create a copy of DesignerSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? bio = null,Object? location = null,Object? specialties = null,Object? priceRange = null,Object? portfolioPieces = null,Object? avatarUrl = null,}) {
  return _then(DesignerSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,specialties: null == specialties ? _self.specialties : specialties // ignore: cast_nullable_to_non_nullable
as List<String>,priceRange: null == priceRange ? _self.priceRange : priceRange // ignore: cast_nullable_to_non_nullable
as String,portfolioPieces: null == portfolioPieces ? _self.portfolioPieces : portfolioPieces // ignore: cast_nullable_to_non_nullable
as List<PortfolioPiece>,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DesignerSummary].
extension DesignerSummaryPatterns on DesignerSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignerSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignerSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignerSummary value)  $default,){
final _that = this;
switch (_that) {
case _DesignerSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignerSummary value)?  $default,){
final _that = this;
switch (_that) {
case _DesignerSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String bio,  String location,  List<String> specialties,  String priceRange,  List<PortfolioPiece> portfolioPieces,  String avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignerSummary() when $default != null:
return $default(_that.id,_that.name,_that.bio,_that.location,_that.specialties,_that.priceRange,_that.portfolioPieces,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String bio,  String location,  List<String> specialties,  String priceRange,  List<PortfolioPiece> portfolioPieces,  String avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _DesignerSummary():
return $default(_that.id,_that.name,_that.bio,_that.location,_that.specialties,_that.priceRange,_that.portfolioPieces,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String bio,  String location,  List<String> specialties,  String priceRange,  List<PortfolioPiece> portfolioPieces,  String avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _DesignerSummary() when $default != null:
return $default(_that.id,_that.name,_that.bio,_that.location,_that.specialties,_that.priceRange,_that.portfolioPieces,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc


class _DesignerSummary extends DesignerSummary {
  const _DesignerSummary({required this.id, required this.name, required this.bio, required this.location, required  List<String> specialties, required this.priceRange, required  List<PortfolioPiece> portfolioPieces, required this.avatarUrl}): _specialties = specialties,_portfolioPieces = portfolioPieces,super._();
  

@override final  String id;
@override final  String name;
@override final  String bio;
@override final  String location;
 final  List<String> _specialties;
@override List<String> get specialties {
  if (_specialties is EqualUnmodifiableListView) return _specialties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_specialties);
}

@override final  String priceRange;
 final  List<PortfolioPiece> _portfolioPieces;
@override List<PortfolioPiece> get portfolioPieces {
  if (_portfolioPieces is EqualUnmodifiableListView) return _portfolioPieces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_portfolioPieces);
}

@override final  String avatarUrl;

/// Create a copy of DesignerSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignerSummaryCopyWith<_DesignerSummary> get copyWith => __$DesignerSummaryCopyWithImpl<_DesignerSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignerSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other.specialties, _specialties)&&(identical(other.priceRange, priceRange) || other.priceRange == priceRange)&&const DeepCollectionEquality().equals(other.portfolioPieces, _portfolioPieces)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,bio,location,const DeepCollectionEquality().hash(_specialties),priceRange,const DeepCollectionEquality().hash(_portfolioPieces),avatarUrl);
}

@override
String toString() {
    return 'DesignerSummary(id: $id, name: $name, bio: $bio, location: $location, specialties: $specialties, priceRange: $priceRange, portfolioPieces: $portfolioPieces, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$DesignerSummaryCopyWith<$Res> implements $DesignerSummaryCopyWith<$Res> {
  factory _$DesignerSummaryCopyWith(_DesignerSummary value, $Res Function(_DesignerSummary) _then) = __$DesignerSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String bio, String location, List<String> specialties, String priceRange, List<PortfolioPiece> portfolioPieces, String avatarUrl
});




}
/// @nodoc
class __$DesignerSummaryCopyWithImpl<$Res>
    implements _$DesignerSummaryCopyWith<$Res> {
  __$DesignerSummaryCopyWithImpl(this._self, this._then);

  final _DesignerSummary _self;
  final $Res Function(_DesignerSummary) _then;

/// Create a copy of DesignerSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? bio = null,Object? location = null,Object? specialties = null,Object? priceRange = null,Object? portfolioPieces = null,Object? avatarUrl = null,}) {
  return _then(_DesignerSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,specialties: null == specialties ? _self._specialties : specialties // ignore: cast_nullable_to_non_nullable
as List<String>,priceRange: null == priceRange ? _self.priceRange : priceRange // ignore: cast_nullable_to_non_nullable
as String,portfolioPieces: null == portfolioPieces ? _self._portfolioPieces : portfolioPieces // ignore: cast_nullable_to_non_nullable
as List<PortfolioPiece>,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
