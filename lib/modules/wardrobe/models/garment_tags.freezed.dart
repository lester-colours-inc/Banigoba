// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'garment_tags.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GarmentTags implements DiagnosticableTreeMixin {

/// A short name for the piece, e.g. "Navy linen shirt".
 String get name; String? get category; String? get subcategory; String? get styleTag; String? get gender; List<String> get colours; List<String> get weatherTags; List<String> get functionalTags;
/// Create a copy of GarmentTags
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GarmentTagsCopyWith<GarmentTags> get copyWith => _$GarmentTagsCopyWithImpl<GarmentTags>(this as GarmentTags, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as GarmentTags;
  properties
    ..add(DiagnosticsProperty('type', 'GarmentTags'))
    ..add(DiagnosticsProperty('name', _this.name))..add(DiagnosticsProperty('category', _this.category))..add(DiagnosticsProperty('subcategory', _this.subcategory))..add(DiagnosticsProperty('styleTag', _this.styleTag))..add(DiagnosticsProperty('gender', _this.gender))..add(DiagnosticsProperty('colours', _this.colours))..add(DiagnosticsProperty('weatherTags', _this.weatherTags))..add(DiagnosticsProperty('functionalTags', _this.functionalTags));
}

@override
bool operator ==(Object other) {
  final _this = this as GarmentTags;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GarmentTags&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.subcategory, _this.subcategory) || other.subcategory == _this.subcategory)&&(identical(other.styleTag, _this.styleTag) || other.styleTag == _this.styleTag)&&(identical(other.gender, _this.gender) || other.gender == _this.gender)&&const DeepCollectionEquality().equals(other.colours, _this.colours)&&const DeepCollectionEquality().equals(other.weatherTags, _this.weatherTags)&&const DeepCollectionEquality().equals(other.functionalTags, _this.functionalTags));
}


@override
int get hashCode {
  final _this = this as GarmentTags;
  return Object.hash(runtimeType,_this.name,_this.category,_this.subcategory,_this.styleTag,_this.gender,const DeepCollectionEquality().hash(_this.colours),const DeepCollectionEquality().hash(_this.weatherTags),const DeepCollectionEquality().hash(_this.functionalTags));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as GarmentTags;
  return 'GarmentTags(name: ${_this.name}, category: ${_this.category}, subcategory: ${_this.subcategory}, styleTag: ${_this.styleTag}, gender: ${_this.gender}, colours: ${_this.colours}, weatherTags: ${_this.weatherTags}, functionalTags: ${_this.functionalTags})';
}


}

/// @nodoc
abstract mixin class $GarmentTagsCopyWith<$Res>  {
  factory $GarmentTagsCopyWith(GarmentTags value, $Res Function(GarmentTags) _then) = _$GarmentTagsCopyWithImpl;
@useResult
$Res call({
 String name, String? category, String? subcategory, String? styleTag, String? gender, List<String> colours, List<String> weatherTags, List<String> functionalTags
});




}
/// @nodoc
class _$GarmentTagsCopyWithImpl<$Res>
    implements $GarmentTagsCopyWith<$Res> {
  _$GarmentTagsCopyWithImpl(this._self, this._then);

  final GarmentTags _self;
  final $Res Function(GarmentTags) _then;

/// Create a copy of GarmentTags
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? category = freezed,Object? subcategory = freezed,Object? styleTag = freezed,Object? gender = freezed,Object? colours = null,Object? weatherTags = null,Object? functionalTags = null,}) {
  return _then(GarmentTags(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,subcategory: freezed == subcategory ? _self.subcategory : subcategory // ignore: cast_nullable_to_non_nullable
as String?,styleTag: freezed == styleTag ? _self.styleTag : styleTag // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,colours: null == colours ? _self.colours : colours // ignore: cast_nullable_to_non_nullable
as List<String>,weatherTags: null == weatherTags ? _self.weatherTags : weatherTags // ignore: cast_nullable_to_non_nullable
as List<String>,functionalTags: null == functionalTags ? _self.functionalTags : functionalTags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [GarmentTags].
extension GarmentTagsPatterns on GarmentTags {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GarmentTags value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GarmentTags() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GarmentTags value)  $default,){
final _that = this;
switch (_that) {
case _GarmentTags():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GarmentTags value)?  $default,){
final _that = this;
switch (_that) {
case _GarmentTags() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? category,  String? subcategory,  String? styleTag,  String? gender,  List<String> colours,  List<String> weatherTags,  List<String> functionalTags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GarmentTags() when $default != null:
return $default(_that.name,_that.category,_that.subcategory,_that.styleTag,_that.gender,_that.colours,_that.weatherTags,_that.functionalTags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? category,  String? subcategory,  String? styleTag,  String? gender,  List<String> colours,  List<String> weatherTags,  List<String> functionalTags)  $default,) {final _that = this;
switch (_that) {
case _GarmentTags():
return $default(_that.name,_that.category,_that.subcategory,_that.styleTag,_that.gender,_that.colours,_that.weatherTags,_that.functionalTags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? category,  String? subcategory,  String? styleTag,  String? gender,  List<String> colours,  List<String> weatherTags,  List<String> functionalTags)?  $default,) {final _that = this;
switch (_that) {
case _GarmentTags() when $default != null:
return $default(_that.name,_that.category,_that.subcategory,_that.styleTag,_that.gender,_that.colours,_that.weatherTags,_that.functionalTags);case _:
  return null;

}
}

}

/// @nodoc


class _GarmentTags extends GarmentTags with DiagnosticableTreeMixin {
  const _GarmentTags({this.name = '', this.category, this.subcategory, this.styleTag, this.gender,  List<String> colours = const [],  List<String> weatherTags = const [],  List<String> functionalTags = const []}): _colours = colours,_weatherTags = weatherTags,_functionalTags = functionalTags,super._();
  

/// A short name for the piece, e.g. "Navy linen shirt".
@override@JsonKey() final  String name;
@override final  String? category;
@override final  String? subcategory;
@override final  String? styleTag;
@override final  String? gender;
 final  List<String> _colours;
@override@JsonKey() List<String> get colours {
  if (_colours is EqualUnmodifiableListView) return _colours;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_colours);
}

 final  List<String> _weatherTags;
@override@JsonKey() List<String> get weatherTags {
  if (_weatherTags is EqualUnmodifiableListView) return _weatherTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weatherTags);
}

 final  List<String> _functionalTags;
@override@JsonKey() List<String> get functionalTags {
  if (_functionalTags is EqualUnmodifiableListView) return _functionalTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_functionalTags);
}


/// Create a copy of GarmentTags
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GarmentTagsCopyWith<_GarmentTags> get copyWith => __$GarmentTagsCopyWithImpl<_GarmentTags>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'GarmentTags'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('category', category))..add(DiagnosticsProperty('subcategory', subcategory))..add(DiagnosticsProperty('styleTag', styleTag))..add(DiagnosticsProperty('gender', gender))..add(DiagnosticsProperty('colours', colours))..add(DiagnosticsProperty('weatherTags', weatherTags))..add(DiagnosticsProperty('functionalTags', functionalTags));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GarmentTags&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.subcategory, subcategory) || other.subcategory == subcategory)&&(identical(other.styleTag, styleTag) || other.styleTag == styleTag)&&(identical(other.gender, gender) || other.gender == gender)&&const DeepCollectionEquality().equals(other.colours, _colours)&&const DeepCollectionEquality().equals(other.weatherTags, _weatherTags)&&const DeepCollectionEquality().equals(other.functionalTags, _functionalTags));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,category,subcategory,styleTag,gender,const DeepCollectionEquality().hash(_colours),const DeepCollectionEquality().hash(_weatherTags),const DeepCollectionEquality().hash(_functionalTags));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'GarmentTags(name: $name, category: $category, subcategory: $subcategory, styleTag: $styleTag, gender: $gender, colours: $colours, weatherTags: $weatherTags, functionalTags: $functionalTags)';
}


}

/// @nodoc
abstract mixin class _$GarmentTagsCopyWith<$Res> implements $GarmentTagsCopyWith<$Res> {
  factory _$GarmentTagsCopyWith(_GarmentTags value, $Res Function(_GarmentTags) _then) = __$GarmentTagsCopyWithImpl;
@override @useResult
$Res call({
 String name, String? category, String? subcategory, String? styleTag, String? gender, List<String> colours, List<String> weatherTags, List<String> functionalTags
});




}
/// @nodoc
class __$GarmentTagsCopyWithImpl<$Res>
    implements _$GarmentTagsCopyWith<$Res> {
  __$GarmentTagsCopyWithImpl(this._self, this._then);

  final _GarmentTags _self;
  final $Res Function(_GarmentTags) _then;

/// Create a copy of GarmentTags
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? category = freezed,Object? subcategory = freezed,Object? styleTag = freezed,Object? gender = freezed,Object? colours = null,Object? weatherTags = null,Object? functionalTags = null,}) {
  return _then(_GarmentTags(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,subcategory: freezed == subcategory ? _self.subcategory : subcategory // ignore: cast_nullable_to_non_nullable
as String?,styleTag: freezed == styleTag ? _self.styleTag : styleTag // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,colours: null == colours ? _self._colours : colours // ignore: cast_nullable_to_non_nullable
as List<String>,weatherTags: null == weatherTags ? _self._weatherTags : weatherTags // ignore: cast_nullable_to_non_nullable
as List<String>,functionalTags: null == functionalTags ? _self._functionalTags : functionalTags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
