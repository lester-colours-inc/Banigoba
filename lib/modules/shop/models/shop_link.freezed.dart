// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShopLink implements DiagnosticableTreeMixin {

 String get id; String get ownerId; String get shopName; String get title; ShareScope get scope; ShareAudience get audience; String get note;/// For a category link, the category (lower case, as products store it).
 String get category;/// For a picked link, the pieces in it.
 List<String> get productIds;/// A picture for previews, from the first piece.
 String get coverImageUrl;/// A shop can switch a link off; it then shows nothing.
 bool get active; DateTime? get createdAt;
/// Create a copy of ShopLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopLinkCopyWith<ShopLink> get copyWith => _$ShopLinkCopyWithImpl<ShopLink>(this as ShopLink, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as ShopLink;
  properties
    ..add(DiagnosticsProperty('type', 'ShopLink'))
    ..add(DiagnosticsProperty('id', _this.id))..add(DiagnosticsProperty('ownerId', _this.ownerId))..add(DiagnosticsProperty('shopName', _this.shopName))..add(DiagnosticsProperty('title', _this.title))..add(DiagnosticsProperty('scope', _this.scope))..add(DiagnosticsProperty('audience', _this.audience))..add(DiagnosticsProperty('note', _this.note))..add(DiagnosticsProperty('category', _this.category))..add(DiagnosticsProperty('productIds', _this.productIds))..add(DiagnosticsProperty('coverImageUrl', _this.coverImageUrl))..add(DiagnosticsProperty('active', _this.active))..add(DiagnosticsProperty('createdAt', _this.createdAt));
}

@override
bool operator ==(Object other) {
  final _this = this as ShopLink;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopLink&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.ownerId, _this.ownerId) || other.ownerId == _this.ownerId)&&(identical(other.shopName, _this.shopName) || other.shopName == _this.shopName)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&(identical(other.audience, _this.audience) || other.audience == _this.audience)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.category, _this.category) || other.category == _this.category)&&const DeepCollectionEquality().equals(other.productIds, _this.productIds)&&(identical(other.coverImageUrl, _this.coverImageUrl) || other.coverImageUrl == _this.coverImageUrl)&&(identical(other.active, _this.active) || other.active == _this.active)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as ShopLink;
  return Object.hash(runtimeType,_this.id,_this.ownerId,_this.shopName,_this.title,_this.scope,_this.audience,_this.note,_this.category,const DeepCollectionEquality().hash(_this.productIds),_this.coverImageUrl,_this.active,_this.createdAt);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as ShopLink;
  return 'ShopLink(id: ${_this.id}, ownerId: ${_this.ownerId}, shopName: ${_this.shopName}, title: ${_this.title}, scope: ${_this.scope}, audience: ${_this.audience}, note: ${_this.note}, category: ${_this.category}, productIds: ${_this.productIds}, coverImageUrl: ${_this.coverImageUrl}, active: ${_this.active}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $ShopLinkCopyWith<$Res>  {
  factory $ShopLinkCopyWith(ShopLink value, $Res Function(ShopLink) _then) = _$ShopLinkCopyWithImpl;
@useResult
$Res call({
 String id, String ownerId, String shopName, String title, ShareScope scope, ShareAudience audience, String note, String category, List<String> productIds, String coverImageUrl, bool active, DateTime? createdAt
});




}
/// @nodoc
class _$ShopLinkCopyWithImpl<$Res>
    implements $ShopLinkCopyWith<$Res> {
  _$ShopLinkCopyWithImpl(this._self, this._then);

  final ShopLink _self;
  final $Res Function(ShopLink) _then;

/// Create a copy of ShopLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerId = null,Object? shopName = null,Object? title = null,Object? scope = null,Object? audience = null,Object? note = null,Object? category = null,Object? productIds = null,Object? coverImageUrl = null,Object? active = null,Object? createdAt = freezed,}) {
  return _then(ShopLink(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,shopName: null == shopName ? _self.shopName : shopName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as ShareScope,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as ShareAudience,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,productIds: null == productIds ? _self.productIds : productIds // ignore: cast_nullable_to_non_nullable
as List<String>,coverImageUrl: null == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShopLink].
extension ShopLinkPatterns on ShopLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShopLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShopLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShopLink value)  $default,){
final _that = this;
switch (_that) {
case _ShopLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShopLink value)?  $default,){
final _that = this;
switch (_that) {
case _ShopLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ownerId,  String shopName,  String title,  ShareScope scope,  ShareAudience audience,  String note,  String category,  List<String> productIds,  String coverImageUrl,  bool active,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShopLink() when $default != null:
return $default(_that.id,_that.ownerId,_that.shopName,_that.title,_that.scope,_that.audience,_that.note,_that.category,_that.productIds,_that.coverImageUrl,_that.active,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ownerId,  String shopName,  String title,  ShareScope scope,  ShareAudience audience,  String note,  String category,  List<String> productIds,  String coverImageUrl,  bool active,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _ShopLink():
return $default(_that.id,_that.ownerId,_that.shopName,_that.title,_that.scope,_that.audience,_that.note,_that.category,_that.productIds,_that.coverImageUrl,_that.active,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ownerId,  String shopName,  String title,  ShareScope scope,  ShareAudience audience,  String note,  String category,  List<String> productIds,  String coverImageUrl,  bool active,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ShopLink() when $default != null:
return $default(_that.id,_that.ownerId,_that.shopName,_that.title,_that.scope,_that.audience,_that.note,_that.category,_that.productIds,_that.coverImageUrl,_that.active,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _ShopLink extends ShopLink with DiagnosticableTreeMixin {
  const _ShopLink({required this.id, required this.ownerId, required this.shopName, required this.title, required this.scope, required this.audience, this.note = '', this.category = '',  List<String> productIds = const [], this.coverImageUrl = '', this.active = true, this.createdAt}): _productIds = productIds,super._();
  

@override final  String id;
@override final  String ownerId;
@override final  String shopName;
@override final  String title;
@override final  ShareScope scope;
@override final  ShareAudience audience;
@override@JsonKey() final  String note;
/// For a category link, the category (lower case, as products store it).
@override@JsonKey() final  String category;
/// For a picked link, the pieces in it.
 final  List<String> _productIds;
/// For a picked link, the pieces in it.
@override@JsonKey() List<String> get productIds {
  if (_productIds is EqualUnmodifiableListView) return _productIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_productIds);
}

/// A picture for previews, from the first piece.
@override@JsonKey() final  String coverImageUrl;
/// A shop can switch a link off; it then shows nothing.
@override@JsonKey() final  bool active;
@override final  DateTime? createdAt;

/// Create a copy of ShopLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopLinkCopyWith<_ShopLink> get copyWith => __$ShopLinkCopyWithImpl<_ShopLink>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'ShopLink'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('ownerId', ownerId))..add(DiagnosticsProperty('shopName', shopName))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('scope', scope))..add(DiagnosticsProperty('audience', audience))..add(DiagnosticsProperty('note', note))..add(DiagnosticsProperty('category', category))..add(DiagnosticsProperty('productIds', productIds))..add(DiagnosticsProperty('coverImageUrl', coverImageUrl))..add(DiagnosticsProperty('active', active))..add(DiagnosticsProperty('createdAt', createdAt));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShopLink&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.shopName, shopName) || other.shopName == shopName)&&(identical(other.title, title) || other.title == title)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.note, note) || other.note == note)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.productIds, _productIds)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.active, active) || other.active == active)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,ownerId,shopName,title,scope,audience,note,category,const DeepCollectionEquality().hash(_productIds),coverImageUrl,active,createdAt);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'ShopLink(id: $id, ownerId: $ownerId, shopName: $shopName, title: $title, scope: $scope, audience: $audience, note: $note, category: $category, productIds: $productIds, coverImageUrl: $coverImageUrl, active: $active, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ShopLinkCopyWith<$Res> implements $ShopLinkCopyWith<$Res> {
  factory _$ShopLinkCopyWith(_ShopLink value, $Res Function(_ShopLink) _then) = __$ShopLinkCopyWithImpl;
@override @useResult
$Res call({
 String id, String ownerId, String shopName, String title, ShareScope scope, ShareAudience audience, String note, String category, List<String> productIds, String coverImageUrl, bool active, DateTime? createdAt
});




}
/// @nodoc
class __$ShopLinkCopyWithImpl<$Res>
    implements _$ShopLinkCopyWith<$Res> {
  __$ShopLinkCopyWithImpl(this._self, this._then);

  final _ShopLink _self;
  final $Res Function(_ShopLink) _then;

/// Create a copy of ShopLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerId = null,Object? shopName = null,Object? title = null,Object? scope = null,Object? audience = null,Object? note = null,Object? category = null,Object? productIds = null,Object? coverImageUrl = null,Object? active = null,Object? createdAt = freezed,}) {
  return _then(_ShopLink(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,shopName: null == shopName ? _self.shopName : shopName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as ShareScope,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as ShareAudience,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,productIds: null == productIds ? _self._productIds : productIds // ignore: cast_nullable_to_non_nullable
as List<String>,coverImageUrl: null == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
