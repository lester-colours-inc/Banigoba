// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_matching.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShopperProfile implements DiagnosticableTreeMixin {

 String get userId; BodyProfile get body;/// The styles they chose, e.g. "Smart".
 List<String> get styles;/// How many wardrobe items they own, by category ("tops", "outerwear"...).
 Map<String, int> get ownedByCategory;/// The shops and designers they follow.
 Set<String> get followedSellerIds;
/// Create a copy of ShopperProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopperProfileCopyWith<ShopperProfile> get copyWith => _$ShopperProfileCopyWithImpl<ShopperProfile>(this as ShopperProfile, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as ShopperProfile;
  properties
    ..add(DiagnosticsProperty('type', 'ShopperProfile'))
    ..add(DiagnosticsProperty('userId', _this.userId))..add(DiagnosticsProperty('body', _this.body))..add(DiagnosticsProperty('styles', _this.styles))..add(DiagnosticsProperty('ownedByCategory', _this.ownedByCategory))..add(DiagnosticsProperty('followedSellerIds', _this.followedSellerIds));
}

@override
bool operator ==(Object other) {
  final _this = this as ShopperProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopperProfile&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.body, _this.body) || other.body == _this.body)&&const DeepCollectionEquality().equals(other.styles, _this.styles)&&const DeepCollectionEquality().equals(other.ownedByCategory, _this.ownedByCategory)&&const DeepCollectionEquality().equals(other.followedSellerIds, _this.followedSellerIds));
}


@override
int get hashCode {
  final _this = this as ShopperProfile;
  return Object.hash(runtimeType,_this.userId,_this.body,const DeepCollectionEquality().hash(_this.styles),const DeepCollectionEquality().hash(_this.ownedByCategory),const DeepCollectionEquality().hash(_this.followedSellerIds));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as ShopperProfile;
  return 'ShopperProfile(userId: ${_this.userId}, body: ${_this.body}, styles: ${_this.styles}, ownedByCategory: ${_this.ownedByCategory}, followedSellerIds: ${_this.followedSellerIds})';
}


}

/// @nodoc
abstract mixin class $ShopperProfileCopyWith<$Res>  {
  factory $ShopperProfileCopyWith(ShopperProfile value, $Res Function(ShopperProfile) _then) = _$ShopperProfileCopyWithImpl;
@useResult
$Res call({
 String userId, BodyProfile body, List<String> styles, Map<String, int> ownedByCategory, Set<String> followedSellerIds
});




}
/// @nodoc
class _$ShopperProfileCopyWithImpl<$Res>
    implements $ShopperProfileCopyWith<$Res> {
  _$ShopperProfileCopyWithImpl(this._self, this._then);

  final ShopperProfile _self;
  final $Res Function(ShopperProfile) _then;

/// Create a copy of ShopperProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? body = null,Object? styles = null,Object? ownedByCategory = null,Object? followedSellerIds = null,}) {
  return _then(ShopperProfile(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as BodyProfile,styles: null == styles ? _self.styles : styles // ignore: cast_nullable_to_non_nullable
as List<String>,ownedByCategory: null == ownedByCategory ? _self.ownedByCategory : ownedByCategory // ignore: cast_nullable_to_non_nullable
as Map<String, int>,followedSellerIds: null == followedSellerIds ? _self.followedSellerIds : followedSellerIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ShopperProfile].
extension ShopperProfilePatterns on ShopperProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShopperProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShopperProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShopperProfile value)  $default,){
final _that = this;
switch (_that) {
case _ShopperProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShopperProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ShopperProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  BodyProfile body,  List<String> styles,  Map<String, int> ownedByCategory,  Set<String> followedSellerIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShopperProfile() when $default != null:
return $default(_that.userId,_that.body,_that.styles,_that.ownedByCategory,_that.followedSellerIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  BodyProfile body,  List<String> styles,  Map<String, int> ownedByCategory,  Set<String> followedSellerIds)  $default,) {final _that = this;
switch (_that) {
case _ShopperProfile():
return $default(_that.userId,_that.body,_that.styles,_that.ownedByCategory,_that.followedSellerIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  BodyProfile body,  List<String> styles,  Map<String, int> ownedByCategory,  Set<String> followedSellerIds)?  $default,) {final _that = this;
switch (_that) {
case _ShopperProfile() when $default != null:
return $default(_that.userId,_that.body,_that.styles,_that.ownedByCategory,_that.followedSellerIds);case _:
  return null;

}
}

}

/// @nodoc


class _ShopperProfile extends ShopperProfile with DiagnosticableTreeMixin {
  const _ShopperProfile({required this.userId, this.body = const BodyProfile(),  List<String> styles = const [],  Map<String, int> ownedByCategory = const {},  Set<String> followedSellerIds = const {}}): _styles = styles,_ownedByCategory = ownedByCategory,_followedSellerIds = followedSellerIds,super._();
  

@override final  String userId;
@override@JsonKey() final  BodyProfile body;
/// The styles they chose, e.g. "Smart".
 final  List<String> _styles;
/// The styles they chose, e.g. "Smart".
@override@JsonKey() List<String> get styles {
  if (_styles is EqualUnmodifiableListView) return _styles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_styles);
}

/// How many wardrobe items they own, by category ("tops", "outerwear"...).
 final  Map<String, int> _ownedByCategory;
/// How many wardrobe items they own, by category ("tops", "outerwear"...).
@override@JsonKey() Map<String, int> get ownedByCategory {
  if (_ownedByCategory is EqualUnmodifiableMapView) return _ownedByCategory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_ownedByCategory);
}

/// The shops and designers they follow.
 final  Set<String> _followedSellerIds;
/// The shops and designers they follow.
@override@JsonKey() Set<String> get followedSellerIds {
  if (_followedSellerIds is EqualUnmodifiableSetView) return _followedSellerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_followedSellerIds);
}


/// Create a copy of ShopperProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopperProfileCopyWith<_ShopperProfile> get copyWith => __$ShopperProfileCopyWithImpl<_ShopperProfile>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'ShopperProfile'))
    ..add(DiagnosticsProperty('userId', userId))..add(DiagnosticsProperty('body', body))..add(DiagnosticsProperty('styles', styles))..add(DiagnosticsProperty('ownedByCategory', ownedByCategory))..add(DiagnosticsProperty('followedSellerIds', followedSellerIds));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShopperProfile&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.styles, _styles)&&const DeepCollectionEquality().equals(other.ownedByCategory, _ownedByCategory)&&const DeepCollectionEquality().equals(other.followedSellerIds, _followedSellerIds));
}


@override
int get hashCode {
    return Object.hash(runtimeType,userId,body,const DeepCollectionEquality().hash(_styles),const DeepCollectionEquality().hash(_ownedByCategory),const DeepCollectionEquality().hash(_followedSellerIds));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'ShopperProfile(userId: $userId, body: $body, styles: $styles, ownedByCategory: $ownedByCategory, followedSellerIds: $followedSellerIds)';
}


}

/// @nodoc
abstract mixin class _$ShopperProfileCopyWith<$Res> implements $ShopperProfileCopyWith<$Res> {
  factory _$ShopperProfileCopyWith(_ShopperProfile value, $Res Function(_ShopperProfile) _then) = __$ShopperProfileCopyWithImpl;
@override @useResult
$Res call({
 String userId, BodyProfile body, List<String> styles, Map<String, int> ownedByCategory, Set<String> followedSellerIds
});




}
/// @nodoc
class __$ShopperProfileCopyWithImpl<$Res>
    implements _$ShopperProfileCopyWith<$Res> {
  __$ShopperProfileCopyWithImpl(this._self, this._then);

  final _ShopperProfile _self;
  final $Res Function(_ShopperProfile) _then;

/// Create a copy of ShopperProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? body = null,Object? styles = null,Object? ownedByCategory = null,Object? followedSellerIds = null,}) {
  return _then(_ShopperProfile(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as BodyProfile,styles: null == styles ? _self._styles : styles // ignore: cast_nullable_to_non_nullable
as List<String>,ownedByCategory: null == ownedByCategory ? _self._ownedByCategory : ownedByCategory // ignore: cast_nullable_to_non_nullable
as Map<String, int>,followedSellerIds: null == followedSellerIds ? _self._followedSellerIds : followedSellerIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

/// @nodoc
mixin _$FeedMatch implements DiagnosticableTreeMixin {

 String get productId; int get score;/// "In your size (M)", "Suits your Smart style", ...
 List<String> get reasons;/// The size to offer, or '' for one-size items.
 String get size;
/// Create a copy of FeedMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedMatchCopyWith<FeedMatch> get copyWith => _$FeedMatchCopyWithImpl<FeedMatch>(this as FeedMatch, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as FeedMatch;
  properties
    ..add(DiagnosticsProperty('type', 'FeedMatch'))
    ..add(DiagnosticsProperty('productId', _this.productId))..add(DiagnosticsProperty('score', _this.score))..add(DiagnosticsProperty('reasons', _this.reasons))..add(DiagnosticsProperty('size', _this.size));
}

@override
bool operator ==(Object other) {
  final _this = this as FeedMatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedMatch&&(identical(other.productId, _this.productId) || other.productId == _this.productId)&&(identical(other.score, _this.score) || other.score == _this.score)&&const DeepCollectionEquality().equals(other.reasons, _this.reasons)&&(identical(other.size, _this.size) || other.size == _this.size));
}


@override
int get hashCode {
  final _this = this as FeedMatch;
  return Object.hash(runtimeType,_this.productId,_this.score,const DeepCollectionEquality().hash(_this.reasons),_this.size);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as FeedMatch;
  return 'FeedMatch(productId: ${_this.productId}, score: ${_this.score}, reasons: ${_this.reasons}, size: ${_this.size})';
}


}

/// @nodoc
abstract mixin class $FeedMatchCopyWith<$Res>  {
  factory $FeedMatchCopyWith(FeedMatch value, $Res Function(FeedMatch) _then) = _$FeedMatchCopyWithImpl;
@useResult
$Res call({
 String productId, int score, List<String> reasons, String size
});




}
/// @nodoc
class _$FeedMatchCopyWithImpl<$Res>
    implements $FeedMatchCopyWith<$Res> {
  _$FeedMatchCopyWithImpl(this._self, this._then);

  final FeedMatch _self;
  final $Res Function(FeedMatch) _then;

/// Create a copy of FeedMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? score = null,Object? reasons = null,Object? size = null,}) {
  return _then(FeedMatch(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,reasons: null == reasons ? _self.reasons : reasons // ignore: cast_nullable_to_non_nullable
as List<String>,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedMatch].
extension FeedMatchPatterns on FeedMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedMatch value)  $default,){
final _that = this;
switch (_that) {
case _FeedMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedMatch value)?  $default,){
final _that = this;
switch (_that) {
case _FeedMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  int score,  List<String> reasons,  String size)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedMatch() when $default != null:
return $default(_that.productId,_that.score,_that.reasons,_that.size);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  int score,  List<String> reasons,  String size)  $default,) {final _that = this;
switch (_that) {
case _FeedMatch():
return $default(_that.productId,_that.score,_that.reasons,_that.size);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  int score,  List<String> reasons,  String size)?  $default,) {final _that = this;
switch (_that) {
case _FeedMatch() when $default != null:
return $default(_that.productId,_that.score,_that.reasons,_that.size);case _:
  return null;

}
}

}

/// @nodoc


class _FeedMatch extends FeedMatch with DiagnosticableTreeMixin {
  const _FeedMatch({required this.productId, required this.score, required  List<String> reasons, required this.size}): _reasons = reasons,super._();
  

@override final  String productId;
@override final  int score;
/// "In your size (M)", "Suits your Smart style", ...
 final  List<String> _reasons;
/// "In your size (M)", "Suits your Smart style", ...
@override List<String> get reasons {
  if (_reasons is EqualUnmodifiableListView) return _reasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reasons);
}

/// The size to offer, or '' for one-size items.
@override final  String size;

/// Create a copy of FeedMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedMatchCopyWith<_FeedMatch> get copyWith => __$FeedMatchCopyWithImpl<_FeedMatch>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'FeedMatch'))
    ..add(DiagnosticsProperty('productId', productId))..add(DiagnosticsProperty('score', score))..add(DiagnosticsProperty('reasons', reasons))..add(DiagnosticsProperty('size', size));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedMatch&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.score, score) || other.score == score)&&const DeepCollectionEquality().equals(other.reasons, _reasons)&&(identical(other.size, size) || other.size == size));
}


@override
int get hashCode {
    return Object.hash(runtimeType,productId,score,const DeepCollectionEquality().hash(_reasons),size);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'FeedMatch(productId: $productId, score: $score, reasons: $reasons, size: $size)';
}


}

/// @nodoc
abstract mixin class _$FeedMatchCopyWith<$Res> implements $FeedMatchCopyWith<$Res> {
  factory _$FeedMatchCopyWith(_FeedMatch value, $Res Function(_FeedMatch) _then) = __$FeedMatchCopyWithImpl;
@override @useResult
$Res call({
 String productId, int score, List<String> reasons, String size
});




}
/// @nodoc
class __$FeedMatchCopyWithImpl<$Res>
    implements _$FeedMatchCopyWith<$Res> {
  __$FeedMatchCopyWithImpl(this._self, this._then);

  final _FeedMatch _self;
  final $Res Function(_FeedMatch) _then;

/// Create a copy of FeedMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? score = null,Object? reasons = null,Object? size = null,}) {
  return _then(_FeedMatch(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,reasons: null == reasons ? _self._reasons : reasons // ignore: cast_nullable_to_non_nullable
as List<String>,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
