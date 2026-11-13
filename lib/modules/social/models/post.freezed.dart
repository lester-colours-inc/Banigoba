// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Post {

 String get id; String get authorId; String get caption; int get commentCount; DateTime get createdAt; String get imageURL; String get outfitId; List<String> get productIds; List<Map<String, dynamic>> get products; PostVisibility get visibility; PostKind get kind;/// Set when this post is a repost or quote of another post.
 String get repostOfId; String get repostOfAuthorId;/// The reposter's own words on a quote. Empty on a plain repost.
 String get quoteText;
/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostCopyWith<Post> get copyWith => _$PostCopyWithImpl<Post>(this as Post, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Post;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Post&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.authorId, _this.authorId) || other.authorId == _this.authorId)&&(identical(other.caption, _this.caption) || other.caption == _this.caption)&&(identical(other.commentCount, _this.commentCount) || other.commentCount == _this.commentCount)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.imageURL, _this.imageURL) || other.imageURL == _this.imageURL)&&(identical(other.outfitId, _this.outfitId) || other.outfitId == _this.outfitId)&&const DeepCollectionEquality().equals(other.productIds, _this.productIds)&&const DeepCollectionEquality().equals(other.products, _this.products)&&(identical(other.visibility, _this.visibility) || other.visibility == _this.visibility)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.repostOfId, _this.repostOfId) || other.repostOfId == _this.repostOfId)&&(identical(other.repostOfAuthorId, _this.repostOfAuthorId) || other.repostOfAuthorId == _this.repostOfAuthorId)&&(identical(other.quoteText, _this.quoteText) || other.quoteText == _this.quoteText));
}


@override
int get hashCode {
  final _this = this as Post;
  return Object.hash(runtimeType,_this.id,_this.authorId,_this.caption,_this.commentCount,_this.createdAt,_this.imageURL,_this.outfitId,const DeepCollectionEquality().hash(_this.productIds),const DeepCollectionEquality().hash(_this.products),_this.visibility,_this.kind,_this.repostOfId,_this.repostOfAuthorId,_this.quoteText);
}

@override
String toString() {
  final _this = this as Post;
  return 'Post(id: ${_this.id}, authorId: ${_this.authorId}, caption: ${_this.caption}, commentCount: ${_this.commentCount}, createdAt: ${_this.createdAt}, imageURL: ${_this.imageURL}, outfitId: ${_this.outfitId}, productIds: ${_this.productIds}, products: ${_this.products}, visibility: ${_this.visibility}, kind: ${_this.kind}, repostOfId: ${_this.repostOfId}, repostOfAuthorId: ${_this.repostOfAuthorId}, quoteText: ${_this.quoteText})';
}


}

/// @nodoc
abstract mixin class $PostCopyWith<$Res>  {
  factory $PostCopyWith(Post value, $Res Function(Post) _then) = _$PostCopyWithImpl;
@useResult
$Res call({
 String id, String authorId, String caption, int commentCount, DateTime createdAt, String imageURL, String outfitId, List<String> productIds, List<Map<String, dynamic>> products, PostVisibility visibility, PostKind kind, String repostOfId, String repostOfAuthorId, String quoteText
});




}
/// @nodoc
class _$PostCopyWithImpl<$Res>
    implements $PostCopyWith<$Res> {
  _$PostCopyWithImpl(this._self, this._then);

  final Post _self;
  final $Res Function(Post) _then;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? authorId = null,Object? caption = null,Object? commentCount = null,Object? createdAt = null,Object? imageURL = null,Object? outfitId = null,Object? productIds = null,Object? products = null,Object? visibility = null,Object? kind = null,Object? repostOfId = null,Object? repostOfAuthorId = null,Object? quoteText = null,}) {
  return _then(Post(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,imageURL: null == imageURL ? _self.imageURL : imageURL // ignore: cast_nullable_to_non_nullable
as String,outfitId: null == outfitId ? _self.outfitId : outfitId // ignore: cast_nullable_to_non_nullable
as String,productIds: null == productIds ? _self.productIds : productIds // ignore: cast_nullable_to_non_nullable
as List<String>,products: null == products ? _self.products : products // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as PostVisibility,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PostKind,repostOfId: null == repostOfId ? _self.repostOfId : repostOfId // ignore: cast_nullable_to_non_nullable
as String,repostOfAuthorId: null == repostOfAuthorId ? _self.repostOfAuthorId : repostOfAuthorId // ignore: cast_nullable_to_non_nullable
as String,quoteText: null == quoteText ? _self.quoteText : quoteText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Post].
extension PostPatterns on Post {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Post value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Post() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Post value)  $default,){
final _that = this;
switch (_that) {
case _Post():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Post value)?  $default,){
final _that = this;
switch (_that) {
case _Post() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String authorId,  String caption,  int commentCount,  DateTime createdAt,  String imageURL,  String outfitId,  List<String> productIds,  List<Map<String, dynamic>> products,  PostVisibility visibility,  PostKind kind,  String repostOfId,  String repostOfAuthorId,  String quoteText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Post() when $default != null:
return $default(_that.id,_that.authorId,_that.caption,_that.commentCount,_that.createdAt,_that.imageURL,_that.outfitId,_that.productIds,_that.products,_that.visibility,_that.kind,_that.repostOfId,_that.repostOfAuthorId,_that.quoteText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String authorId,  String caption,  int commentCount,  DateTime createdAt,  String imageURL,  String outfitId,  List<String> productIds,  List<Map<String, dynamic>> products,  PostVisibility visibility,  PostKind kind,  String repostOfId,  String repostOfAuthorId,  String quoteText)  $default,) {final _that = this;
switch (_that) {
case _Post():
return $default(_that.id,_that.authorId,_that.caption,_that.commentCount,_that.createdAt,_that.imageURL,_that.outfitId,_that.productIds,_that.products,_that.visibility,_that.kind,_that.repostOfId,_that.repostOfAuthorId,_that.quoteText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String authorId,  String caption,  int commentCount,  DateTime createdAt,  String imageURL,  String outfitId,  List<String> productIds,  List<Map<String, dynamic>> products,  PostVisibility visibility,  PostKind kind,  String repostOfId,  String repostOfAuthorId,  String quoteText)?  $default,) {final _that = this;
switch (_that) {
case _Post() when $default != null:
return $default(_that.id,_that.authorId,_that.caption,_that.commentCount,_that.createdAt,_that.imageURL,_that.outfitId,_that.productIds,_that.products,_that.visibility,_that.kind,_that.repostOfId,_that.repostOfAuthorId,_that.quoteText);case _:
  return null;

}
}

}

/// @nodoc


class _Post extends Post {
  const _Post({required this.id, required this.authorId, required this.caption, required this.commentCount, required this.createdAt, required this.imageURL, this.outfitId = '',  List<String> productIds = const [],  List<Map<String, dynamic>> products = const [], this.visibility = PostVisibility.private, this.kind = PostKind.look, this.repostOfId = '', this.repostOfAuthorId = '', this.quoteText = ''}): _productIds = productIds,_products = products,super._();
  

@override final  String id;
@override final  String authorId;
@override final  String caption;
@override final  int commentCount;
@override final  DateTime createdAt;
@override final  String imageURL;
@override@JsonKey() final  String outfitId;
 final  List<String> _productIds;
@override@JsonKey() List<String> get productIds {
  if (_productIds is EqualUnmodifiableListView) return _productIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_productIds);
}

 final  List<Map<String, dynamic>> _products;
@override@JsonKey() List<Map<String, dynamic>> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}

@override@JsonKey() final  PostVisibility visibility;
@override@JsonKey() final  PostKind kind;
/// Set when this post is a repost or quote of another post.
@override@JsonKey() final  String repostOfId;
@override@JsonKey() final  String repostOfAuthorId;
/// The reposter's own words on a quote. Empty on a plain repost.
@override@JsonKey() final  String quoteText;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostCopyWith<_Post> get copyWith => __$PostCopyWithImpl<_Post>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Post&&(identical(other.id, id) || other.id == id)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.imageURL, imageURL) || other.imageURL == imageURL)&&(identical(other.outfitId, outfitId) || other.outfitId == outfitId)&&const DeepCollectionEquality().equals(other.productIds, _productIds)&&const DeepCollectionEquality().equals(other.products, _products)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.repostOfId, repostOfId) || other.repostOfId == repostOfId)&&(identical(other.repostOfAuthorId, repostOfAuthorId) || other.repostOfAuthorId == repostOfAuthorId)&&(identical(other.quoteText, quoteText) || other.quoteText == quoteText));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,authorId,caption,commentCount,createdAt,imageURL,outfitId,const DeepCollectionEquality().hash(_productIds),const DeepCollectionEquality().hash(_products),visibility,kind,repostOfId,repostOfAuthorId,quoteText);
}

@override
String toString() {
    return 'Post(id: $id, authorId: $authorId, caption: $caption, commentCount: $commentCount, createdAt: $createdAt, imageURL: $imageURL, outfitId: $outfitId, productIds: $productIds, products: $products, visibility: $visibility, kind: $kind, repostOfId: $repostOfId, repostOfAuthorId: $repostOfAuthorId, quoteText: $quoteText)';
}


}

/// @nodoc
abstract mixin class _$PostCopyWith<$Res> implements $PostCopyWith<$Res> {
  factory _$PostCopyWith(_Post value, $Res Function(_Post) _then) = __$PostCopyWithImpl;
@override @useResult
$Res call({
 String id, String authorId, String caption, int commentCount, DateTime createdAt, String imageURL, String outfitId, List<String> productIds, List<Map<String, dynamic>> products, PostVisibility visibility, PostKind kind, String repostOfId, String repostOfAuthorId, String quoteText
});




}
/// @nodoc
class __$PostCopyWithImpl<$Res>
    implements _$PostCopyWith<$Res> {
  __$PostCopyWithImpl(this._self, this._then);

  final _Post _self;
  final $Res Function(_Post) _then;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? authorId = null,Object? caption = null,Object? commentCount = null,Object? createdAt = null,Object? imageURL = null,Object? outfitId = null,Object? productIds = null,Object? products = null,Object? visibility = null,Object? kind = null,Object? repostOfId = null,Object? repostOfAuthorId = null,Object? quoteText = null,}) {
  return _then(_Post(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,imageURL: null == imageURL ? _self.imageURL : imageURL // ignore: cast_nullable_to_non_nullable
as String,outfitId: null == outfitId ? _self.outfitId : outfitId // ignore: cast_nullable_to_non_nullable
as String,productIds: null == productIds ? _self._productIds : productIds // ignore: cast_nullable_to_non_nullable
as List<String>,products: null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as PostVisibility,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PostKind,repostOfId: null == repostOfId ? _self.repostOfId : repostOfId // ignore: cast_nullable_to_non_nullable
as String,repostOfAuthorId: null == repostOfAuthorId ? _self.repostOfAuthorId : repostOfAuthorId // ignore: cast_nullable_to_non_nullable
as String,quoteText: null == quoteText ? _self.quoteText : quoteText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PostComment {

 String get id; String get authorId; DateTime get createdAt; String get profileImageURL; String get text; String get username;
/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostCommentCopyWith<PostComment> get copyWith => _$PostCommentCopyWithImpl<PostComment>(this as PostComment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PostComment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostComment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.authorId, _this.authorId) || other.authorId == _this.authorId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.profileImageURL, _this.profileImageURL) || other.profileImageURL == _this.profileImageURL)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.username, _this.username) || other.username == _this.username));
}


@override
int get hashCode {
  final _this = this as PostComment;
  return Object.hash(runtimeType,_this.id,_this.authorId,_this.createdAt,_this.profileImageURL,_this.text,_this.username);
}

@override
String toString() {
  final _this = this as PostComment;
  return 'PostComment(id: ${_this.id}, authorId: ${_this.authorId}, createdAt: ${_this.createdAt}, profileImageURL: ${_this.profileImageURL}, text: ${_this.text}, username: ${_this.username})';
}


}

/// @nodoc
abstract mixin class $PostCommentCopyWith<$Res>  {
  factory $PostCommentCopyWith(PostComment value, $Res Function(PostComment) _then) = _$PostCommentCopyWithImpl;
@useResult
$Res call({
 String id, String authorId, DateTime createdAt, String profileImageURL, String text, String username
});




}
/// @nodoc
class _$PostCommentCopyWithImpl<$Res>
    implements $PostCommentCopyWith<$Res> {
  _$PostCommentCopyWithImpl(this._self, this._then);

  final PostComment _self;
  final $Res Function(PostComment) _then;

/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? authorId = null,Object? createdAt = null,Object? profileImageURL = null,Object? text = null,Object? username = null,}) {
  return _then(PostComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,profileImageURL: null == profileImageURL ? _self.profileImageURL : profileImageURL // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PostComment].
extension PostCommentPatterns on PostComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostComment value)  $default,){
final _that = this;
switch (_that) {
case _PostComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostComment value)?  $default,){
final _that = this;
switch (_that) {
case _PostComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String authorId,  DateTime createdAt,  String profileImageURL,  String text,  String username)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostComment() when $default != null:
return $default(_that.id,_that.authorId,_that.createdAt,_that.profileImageURL,_that.text,_that.username);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String authorId,  DateTime createdAt,  String profileImageURL,  String text,  String username)  $default,) {final _that = this;
switch (_that) {
case _PostComment():
return $default(_that.id,_that.authorId,_that.createdAt,_that.profileImageURL,_that.text,_that.username);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String authorId,  DateTime createdAt,  String profileImageURL,  String text,  String username)?  $default,) {final _that = this;
switch (_that) {
case _PostComment() when $default != null:
return $default(_that.id,_that.authorId,_that.createdAt,_that.profileImageURL,_that.text,_that.username);case _:
  return null;

}
}

}

/// @nodoc


class _PostComment extends PostComment {
  const _PostComment({required this.id, required this.authorId, required this.createdAt, required this.profileImageURL, required this.text, required this.username}): super._();
  

@override final  String id;
@override final  String authorId;
@override final  DateTime createdAt;
@override final  String profileImageURL;
@override final  String text;
@override final  String username;

/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostCommentCopyWith<_PostComment> get copyWith => __$PostCommentCopyWithImpl<_PostComment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostComment&&(identical(other.id, id) || other.id == id)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.profileImageURL, profileImageURL) || other.profileImageURL == profileImageURL)&&(identical(other.text, text) || other.text == text)&&(identical(other.username, username) || other.username == username));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,authorId,createdAt,profileImageURL,text,username);
}

@override
String toString() {
    return 'PostComment(id: $id, authorId: $authorId, createdAt: $createdAt, profileImageURL: $profileImageURL, text: $text, username: $username)';
}


}

/// @nodoc
abstract mixin class _$PostCommentCopyWith<$Res> implements $PostCommentCopyWith<$Res> {
  factory _$PostCommentCopyWith(_PostComment value, $Res Function(_PostComment) _then) = __$PostCommentCopyWithImpl;
@override @useResult
$Res call({
 String id, String authorId, DateTime createdAt, String profileImageURL, String text, String username
});




}
/// @nodoc
class __$PostCommentCopyWithImpl<$Res>
    implements _$PostCommentCopyWith<$Res> {
  __$PostCommentCopyWithImpl(this._self, this._then);

  final _PostComment _self;
  final $Res Function(_PostComment) _then;

/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? authorId = null,Object? createdAt = null,Object? profileImageURL = null,Object? text = null,Object? username = null,}) {
  return _then(_PostComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,profileImageURL: null == profileImageURL ? _self.profileImageURL : profileImageURL // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
