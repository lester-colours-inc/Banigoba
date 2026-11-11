// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ContentItem implements DiagnosticableTreeMixin {

 String get id; String get title; String get url; String get imageUrl; String get sourceName; bool get isEvent; List<String> get places; List<String> get topics; DateTime get publishedAt;/// The day an event starts, when its title said so. Null otherwise.
 DateTime? get startsAt;
/// Create a copy of ContentItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentItemCopyWith<ContentItem> get copyWith => _$ContentItemCopyWithImpl<ContentItem>(this as ContentItem, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as ContentItem;
  properties
    ..add(DiagnosticsProperty('type', 'ContentItem'))
    ..add(DiagnosticsProperty('id', _this.id))..add(DiagnosticsProperty('title', _this.title))..add(DiagnosticsProperty('url', _this.url))..add(DiagnosticsProperty('imageUrl', _this.imageUrl))..add(DiagnosticsProperty('sourceName', _this.sourceName))..add(DiagnosticsProperty('isEvent', _this.isEvent))..add(DiagnosticsProperty('places', _this.places))..add(DiagnosticsProperty('topics', _this.topics))..add(DiagnosticsProperty('publishedAt', _this.publishedAt))..add(DiagnosticsProperty('startsAt', _this.startsAt));
}

@override
bool operator ==(Object other) {
  final _this = this as ContentItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&(identical(other.sourceName, _this.sourceName) || other.sourceName == _this.sourceName)&&(identical(other.isEvent, _this.isEvent) || other.isEvent == _this.isEvent)&&const DeepCollectionEquality().equals(other.places, _this.places)&&const DeepCollectionEquality().equals(other.topics, _this.topics)&&(identical(other.publishedAt, _this.publishedAt) || other.publishedAt == _this.publishedAt)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt));
}


@override
int get hashCode {
  final _this = this as ContentItem;
  return Object.hash(runtimeType,_this.id,_this.title,_this.url,_this.imageUrl,_this.sourceName,_this.isEvent,const DeepCollectionEquality().hash(_this.places),const DeepCollectionEquality().hash(_this.topics),_this.publishedAt,_this.startsAt);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as ContentItem;
  return 'ContentItem(id: ${_this.id}, title: ${_this.title}, url: ${_this.url}, imageUrl: ${_this.imageUrl}, sourceName: ${_this.sourceName}, isEvent: ${_this.isEvent}, places: ${_this.places}, topics: ${_this.topics}, publishedAt: ${_this.publishedAt}, startsAt: ${_this.startsAt})';
}


}

/// @nodoc
abstract mixin class $ContentItemCopyWith<$Res>  {
  factory $ContentItemCopyWith(ContentItem value, $Res Function(ContentItem) _then) = _$ContentItemCopyWithImpl;
@useResult
$Res call({
 String id, String title, String url, String imageUrl, String sourceName, bool isEvent, List<String> places, List<String> topics, DateTime publishedAt, DateTime? startsAt
});




}
/// @nodoc
class _$ContentItemCopyWithImpl<$Res>
    implements $ContentItemCopyWith<$Res> {
  _$ContentItemCopyWithImpl(this._self, this._then);

  final ContentItem _self;
  final $Res Function(ContentItem) _then;

/// Create a copy of ContentItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? url = null,Object? imageUrl = null,Object? sourceName = null,Object? isEvent = null,Object? places = null,Object? topics = null,Object? publishedAt = null,Object? startsAt = freezed,}) {
  return _then(ContentItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,sourceName: null == sourceName ? _self.sourceName : sourceName // ignore: cast_nullable_to_non_nullable
as String,isEvent: null == isEvent ? _self.isEvent : isEvent // ignore: cast_nullable_to_non_nullable
as bool,places: null == places ? _self.places : places // ignore: cast_nullable_to_non_nullable
as List<String>,topics: null == topics ? _self.topics : topics // ignore: cast_nullable_to_non_nullable
as List<String>,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ContentItem].
extension ContentItemPatterns on ContentItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContentItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContentItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContentItem value)  $default,){
final _that = this;
switch (_that) {
case _ContentItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContentItem value)?  $default,){
final _that = this;
switch (_that) {
case _ContentItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String url,  String imageUrl,  String sourceName,  bool isEvent,  List<String> places,  List<String> topics,  DateTime publishedAt,  DateTime? startsAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContentItem() when $default != null:
return $default(_that.id,_that.title,_that.url,_that.imageUrl,_that.sourceName,_that.isEvent,_that.places,_that.topics,_that.publishedAt,_that.startsAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String url,  String imageUrl,  String sourceName,  bool isEvent,  List<String> places,  List<String> topics,  DateTime publishedAt,  DateTime? startsAt)  $default,) {final _that = this;
switch (_that) {
case _ContentItem():
return $default(_that.id,_that.title,_that.url,_that.imageUrl,_that.sourceName,_that.isEvent,_that.places,_that.topics,_that.publishedAt,_that.startsAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String url,  String imageUrl,  String sourceName,  bool isEvent,  List<String> places,  List<String> topics,  DateTime publishedAt,  DateTime? startsAt)?  $default,) {final _that = this;
switch (_that) {
case _ContentItem() when $default != null:
return $default(_that.id,_that.title,_that.url,_that.imageUrl,_that.sourceName,_that.isEvent,_that.places,_that.topics,_that.publishedAt,_that.startsAt);case _:
  return null;

}
}

}

/// @nodoc


class _ContentItem extends ContentItem with DiagnosticableTreeMixin {
  const _ContentItem({required this.id, required this.title, required this.url, required this.imageUrl, required this.sourceName, required this.isEvent, required  List<String> places, required  List<String> topics, required this.publishedAt, this.startsAt}): _places = places,_topics = topics,super._();
  

@override final  String id;
@override final  String title;
@override final  String url;
@override final  String imageUrl;
@override final  String sourceName;
@override final  bool isEvent;
 final  List<String> _places;
@override List<String> get places {
  if (_places is EqualUnmodifiableListView) return _places;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_places);
}

 final  List<String> _topics;
@override List<String> get topics {
  if (_topics is EqualUnmodifiableListView) return _topics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topics);
}

@override final  DateTime publishedAt;
/// The day an event starts, when its title said so. Null otherwise.
@override final  DateTime? startsAt;

/// Create a copy of ContentItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContentItemCopyWith<_ContentItem> get copyWith => __$ContentItemCopyWithImpl<_ContentItem>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'ContentItem'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('url', url))..add(DiagnosticsProperty('imageUrl', imageUrl))..add(DiagnosticsProperty('sourceName', sourceName))..add(DiagnosticsProperty('isEvent', isEvent))..add(DiagnosticsProperty('places', places))..add(DiagnosticsProperty('topics', topics))..add(DiagnosticsProperty('publishedAt', publishedAt))..add(DiagnosticsProperty('startsAt', startsAt));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContentItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.sourceName, sourceName) || other.sourceName == sourceName)&&(identical(other.isEvent, isEvent) || other.isEvent == isEvent)&&const DeepCollectionEquality().equals(other.places, _places)&&const DeepCollectionEquality().equals(other.topics, _topics)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,title,url,imageUrl,sourceName,isEvent,const DeepCollectionEquality().hash(_places),const DeepCollectionEquality().hash(_topics),publishedAt,startsAt);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'ContentItem(id: $id, title: $title, url: $url, imageUrl: $imageUrl, sourceName: $sourceName, isEvent: $isEvent, places: $places, topics: $topics, publishedAt: $publishedAt, startsAt: $startsAt)';
}


}

/// @nodoc
abstract mixin class _$ContentItemCopyWith<$Res> implements $ContentItemCopyWith<$Res> {
  factory _$ContentItemCopyWith(_ContentItem value, $Res Function(_ContentItem) _then) = __$ContentItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String url, String imageUrl, String sourceName, bool isEvent, List<String> places, List<String> topics, DateTime publishedAt, DateTime? startsAt
});




}
/// @nodoc
class __$ContentItemCopyWithImpl<$Res>
    implements _$ContentItemCopyWith<$Res> {
  __$ContentItemCopyWithImpl(this._self, this._then);

  final _ContentItem _self;
  final $Res Function(_ContentItem) _then;

/// Create a copy of ContentItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? url = null,Object? imageUrl = null,Object? sourceName = null,Object? isEvent = null,Object? places = null,Object? topics = null,Object? publishedAt = null,Object? startsAt = freezed,}) {
  return _then(_ContentItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,sourceName: null == sourceName ? _self.sourceName : sourceName // ignore: cast_nullable_to_non_nullable
as String,isEvent: null == isEvent ? _self.isEvent : isEvent // ignore: cast_nullable_to_non_nullable
as bool,places: null == places ? _self._places : places // ignore: cast_nullable_to_non_nullable
as List<String>,topics: null == topics ? _self._topics : topics // ignore: cast_nullable_to_non_nullable
as List<String>,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
