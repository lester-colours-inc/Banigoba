// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'look_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StyleArchetype implements DiagnosticableTreeMixin {

 String get id; String get name;/// One short line shown under the name.
 String get tagline;/// How the archetype is described to the image model.
 String get promptHint;
/// Create a copy of StyleArchetype
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StyleArchetypeCopyWith<StyleArchetype> get copyWith => _$StyleArchetypeCopyWithImpl<StyleArchetype>(this as StyleArchetype, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as StyleArchetype;
  properties
    ..add(DiagnosticsProperty('type', 'StyleArchetype'))
    ..add(DiagnosticsProperty('id', _this.id))..add(DiagnosticsProperty('name', _this.name))..add(DiagnosticsProperty('tagline', _this.tagline))..add(DiagnosticsProperty('promptHint', _this.promptHint));
}

@override
bool operator ==(Object other) {
  final _this = this as StyleArchetype;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StyleArchetype&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.tagline, _this.tagline) || other.tagline == _this.tagline)&&(identical(other.promptHint, _this.promptHint) || other.promptHint == _this.promptHint));
}


@override
int get hashCode {
  final _this = this as StyleArchetype;
  return Object.hash(runtimeType,_this.id,_this.name,_this.tagline,_this.promptHint);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as StyleArchetype;
  return 'StyleArchetype(id: ${_this.id}, name: ${_this.name}, tagline: ${_this.tagline}, promptHint: ${_this.promptHint})';
}


}

/// @nodoc
abstract mixin class $StyleArchetypeCopyWith<$Res>  {
  factory $StyleArchetypeCopyWith(StyleArchetype value, $Res Function(StyleArchetype) _then) = _$StyleArchetypeCopyWithImpl;
@useResult
$Res call({
 String id, String name, String tagline, String promptHint
});




}
/// @nodoc
class _$StyleArchetypeCopyWithImpl<$Res>
    implements $StyleArchetypeCopyWith<$Res> {
  _$StyleArchetypeCopyWithImpl(this._self, this._then);

  final StyleArchetype _self;
  final $Res Function(StyleArchetype) _then;

/// Create a copy of StyleArchetype
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? tagline = null,Object? promptHint = null,}) {
  return _then(StyleArchetype(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,promptHint: null == promptHint ? _self.promptHint : promptHint // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StyleArchetype].
extension StyleArchetypePatterns on StyleArchetype {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StyleArchetype value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StyleArchetype() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StyleArchetype value)  $default,){
final _that = this;
switch (_that) {
case _StyleArchetype():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StyleArchetype value)?  $default,){
final _that = this;
switch (_that) {
case _StyleArchetype() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String tagline,  String promptHint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StyleArchetype() when $default != null:
return $default(_that.id,_that.name,_that.tagline,_that.promptHint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String tagline,  String promptHint)  $default,) {final _that = this;
switch (_that) {
case _StyleArchetype():
return $default(_that.id,_that.name,_that.tagline,_that.promptHint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String tagline,  String promptHint)?  $default,) {final _that = this;
switch (_that) {
case _StyleArchetype() when $default != null:
return $default(_that.id,_that.name,_that.tagline,_that.promptHint);case _:
  return null;

}
}

}

/// @nodoc


class _StyleArchetype extends StyleArchetype with DiagnosticableTreeMixin {
  const _StyleArchetype({required this.id, required this.name, required this.tagline, required this.promptHint}): super._();
  

@override final  String id;
@override final  String name;
/// One short line shown under the name.
@override final  String tagline;
/// How the archetype is described to the image model.
@override final  String promptHint;

/// Create a copy of StyleArchetype
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StyleArchetypeCopyWith<_StyleArchetype> get copyWith => __$StyleArchetypeCopyWithImpl<_StyleArchetype>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'StyleArchetype'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('tagline', tagline))..add(DiagnosticsProperty('promptHint', promptHint));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StyleArchetype&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.promptHint, promptHint) || other.promptHint == promptHint));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,tagline,promptHint);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'StyleArchetype(id: $id, name: $name, tagline: $tagline, promptHint: $promptHint)';
}


}

/// @nodoc
abstract mixin class _$StyleArchetypeCopyWith<$Res> implements $StyleArchetypeCopyWith<$Res> {
  factory _$StyleArchetypeCopyWith(_StyleArchetype value, $Res Function(_StyleArchetype) _then) = __$StyleArchetypeCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String tagline, String promptHint
});




}
/// @nodoc
class __$StyleArchetypeCopyWithImpl<$Res>
    implements _$StyleArchetypeCopyWith<$Res> {
  __$StyleArchetypeCopyWithImpl(this._self, this._then);

  final _StyleArchetype _self;
  final $Res Function(_StyleArchetype) _then;

/// Create a copy of StyleArchetype
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? tagline = null,Object? promptHint = null,}) {
  return _then(_StyleArchetype(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,promptHint: null == promptHint ? _self.promptHint : promptHint // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$StyleTrend implements DiagnosticableTreeMixin {

 String get id; String get name; String get tagline; String get promptHint;/// Hair trends are offered only when the scope changes hair; clothing
/// trends only when it changes clothing.
 bool get isHair;
/// Create a copy of StyleTrend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StyleTrendCopyWith<StyleTrend> get copyWith => _$StyleTrendCopyWithImpl<StyleTrend>(this as StyleTrend, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as StyleTrend;
  properties
    ..add(DiagnosticsProperty('type', 'StyleTrend'))
    ..add(DiagnosticsProperty('id', _this.id))..add(DiagnosticsProperty('name', _this.name))..add(DiagnosticsProperty('tagline', _this.tagline))..add(DiagnosticsProperty('promptHint', _this.promptHint))..add(DiagnosticsProperty('isHair', _this.isHair));
}

@override
bool operator ==(Object other) {
  final _this = this as StyleTrend;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StyleTrend&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.tagline, _this.tagline) || other.tagline == _this.tagline)&&(identical(other.promptHint, _this.promptHint) || other.promptHint == _this.promptHint)&&(identical(other.isHair, _this.isHair) || other.isHair == _this.isHair));
}


@override
int get hashCode {
  final _this = this as StyleTrend;
  return Object.hash(runtimeType,_this.id,_this.name,_this.tagline,_this.promptHint,_this.isHair);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as StyleTrend;
  return 'StyleTrend(id: ${_this.id}, name: ${_this.name}, tagline: ${_this.tagline}, promptHint: ${_this.promptHint}, isHair: ${_this.isHair})';
}


}

/// @nodoc
abstract mixin class $StyleTrendCopyWith<$Res>  {
  factory $StyleTrendCopyWith(StyleTrend value, $Res Function(StyleTrend) _then) = _$StyleTrendCopyWithImpl;
@useResult
$Res call({
 String id, String name, String tagline, String promptHint, bool isHair
});




}
/// @nodoc
class _$StyleTrendCopyWithImpl<$Res>
    implements $StyleTrendCopyWith<$Res> {
  _$StyleTrendCopyWithImpl(this._self, this._then);

  final StyleTrend _self;
  final $Res Function(StyleTrend) _then;

/// Create a copy of StyleTrend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? tagline = null,Object? promptHint = null,Object? isHair = null,}) {
  return _then(StyleTrend(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,promptHint: null == promptHint ? _self.promptHint : promptHint // ignore: cast_nullable_to_non_nullable
as String,isHair: null == isHair ? _self.isHair : isHair // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StyleTrend].
extension StyleTrendPatterns on StyleTrend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StyleTrend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StyleTrend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StyleTrend value)  $default,){
final _that = this;
switch (_that) {
case _StyleTrend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StyleTrend value)?  $default,){
final _that = this;
switch (_that) {
case _StyleTrend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String tagline,  String promptHint,  bool isHair)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StyleTrend() when $default != null:
return $default(_that.id,_that.name,_that.tagline,_that.promptHint,_that.isHair);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String tagline,  String promptHint,  bool isHair)  $default,) {final _that = this;
switch (_that) {
case _StyleTrend():
return $default(_that.id,_that.name,_that.tagline,_that.promptHint,_that.isHair);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String tagline,  String promptHint,  bool isHair)?  $default,) {final _that = this;
switch (_that) {
case _StyleTrend() when $default != null:
return $default(_that.id,_that.name,_that.tagline,_that.promptHint,_that.isHair);case _:
  return null;

}
}

}

/// @nodoc


class _StyleTrend extends StyleTrend with DiagnosticableTreeMixin {
  const _StyleTrend({required this.id, required this.name, required this.tagline, required this.promptHint, this.isHair = false}): super._();
  

@override final  String id;
@override final  String name;
@override final  String tagline;
@override final  String promptHint;
/// Hair trends are offered only when the scope changes hair; clothing
/// trends only when it changes clothing.
@override@JsonKey() final  bool isHair;

/// Create a copy of StyleTrend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StyleTrendCopyWith<_StyleTrend> get copyWith => __$StyleTrendCopyWithImpl<_StyleTrend>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'StyleTrend'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('tagline', tagline))..add(DiagnosticsProperty('promptHint', promptHint))..add(DiagnosticsProperty('isHair', isHair));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StyleTrend&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.promptHint, promptHint) || other.promptHint == promptHint)&&(identical(other.isHair, isHair) || other.isHair == isHair));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,tagline,promptHint,isHair);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'StyleTrend(id: $id, name: $name, tagline: $tagline, promptHint: $promptHint, isHair: $isHair)';
}


}

/// @nodoc
abstract mixin class _$StyleTrendCopyWith<$Res> implements $StyleTrendCopyWith<$Res> {
  factory _$StyleTrendCopyWith(_StyleTrend value, $Res Function(_StyleTrend) _then) = __$StyleTrendCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String tagline, String promptHint, bool isHair
});




}
/// @nodoc
class __$StyleTrendCopyWithImpl<$Res>
    implements _$StyleTrendCopyWith<$Res> {
  __$StyleTrendCopyWithImpl(this._self, this._then);

  final _StyleTrend _self;
  final $Res Function(_StyleTrend) _then;

/// Create a copy of StyleTrend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? tagline = null,Object? promptHint = null,Object? isHair = null,}) {
  return _then(_StyleTrend(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,promptHint: null == promptHint ? _self.promptHint : promptHint // ignore: cast_nullable_to_non_nullable
as String,isHair: null == isHair ? _self.isHair : isHair // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$LookRequest implements DiagnosticableTreeMixin {

 String get photoUrl; LookScope get scope; LookSource get source;/// Optional extra words the user adds to any non-describe source.
 String get extraNote;/// The user's profile details: clothes are fitted to their real size, and
/// a Fashion Idol or Style twin look keeps their face from the face photo.
 BodyProfile get body;
/// Create a copy of LookRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LookRequestCopyWith<LookRequest> get copyWith => _$LookRequestCopyWithImpl<LookRequest>(this as LookRequest, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as LookRequest;
  properties
    ..add(DiagnosticsProperty('type', 'LookRequest'))
    ..add(DiagnosticsProperty('photoUrl', _this.photoUrl))..add(DiagnosticsProperty('scope', _this.scope))..add(DiagnosticsProperty('source', _this.source))..add(DiagnosticsProperty('extraNote', _this.extraNote))..add(DiagnosticsProperty('body', _this.body));
}

@override
bool operator ==(Object other) {
  final _this = this as LookRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LookRequest&&(identical(other.photoUrl, _this.photoUrl) || other.photoUrl == _this.photoUrl)&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.extraNote, _this.extraNote) || other.extraNote == _this.extraNote)&&(identical(other.body, _this.body) || other.body == _this.body));
}


@override
int get hashCode {
  final _this = this as LookRequest;
  return Object.hash(runtimeType,_this.photoUrl,_this.scope,_this.source,_this.extraNote,_this.body);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as LookRequest;
  return 'LookRequest(photoUrl: ${_this.photoUrl}, scope: ${_this.scope}, source: ${_this.source}, extraNote: ${_this.extraNote}, body: ${_this.body})';
}


}

/// @nodoc
abstract mixin class $LookRequestCopyWith<$Res>  {
  factory $LookRequestCopyWith(LookRequest value, $Res Function(LookRequest) _then) = _$LookRequestCopyWithImpl;
@useResult
$Res call({
 String photoUrl, LookScope scope, LookSource source, String extraNote, BodyProfile body
});




}
/// @nodoc
class _$LookRequestCopyWithImpl<$Res>
    implements $LookRequestCopyWith<$Res> {
  _$LookRequestCopyWithImpl(this._self, this._then);

  final LookRequest _self;
  final $Res Function(LookRequest) _then;

/// Create a copy of LookRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? photoUrl = null,Object? scope = null,Object? source = null,Object? extraNote = null,Object? body = null,}) {
  return _then(LookRequest(
photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as LookScope,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LookSource,extraNote: null == extraNote ? _self.extraNote : extraNote // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as BodyProfile,
  ));
}

}


/// Adds pattern-matching-related methods to [LookRequest].
extension LookRequestPatterns on LookRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LookRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LookRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LookRequest value)  $default,){
final _that = this;
switch (_that) {
case _LookRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LookRequest value)?  $default,){
final _that = this;
switch (_that) {
case _LookRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String photoUrl,  LookScope scope,  LookSource source,  String extraNote,  BodyProfile body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LookRequest() when $default != null:
return $default(_that.photoUrl,_that.scope,_that.source,_that.extraNote,_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String photoUrl,  LookScope scope,  LookSource source,  String extraNote,  BodyProfile body)  $default,) {final _that = this;
switch (_that) {
case _LookRequest():
return $default(_that.photoUrl,_that.scope,_that.source,_that.extraNote,_that.body);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String photoUrl,  LookScope scope,  LookSource source,  String extraNote,  BodyProfile body)?  $default,) {final _that = this;
switch (_that) {
case _LookRequest() when $default != null:
return $default(_that.photoUrl,_that.scope,_that.source,_that.extraNote,_that.body);case _:
  return null;

}
}

}

/// @nodoc


class _LookRequest extends LookRequest with DiagnosticableTreeMixin {
  const _LookRequest({required this.photoUrl, required this.scope, required this.source, this.extraNote = '', this.body = const BodyProfile()}): super._();
  

@override final  String photoUrl;
@override final  LookScope scope;
@override final  LookSource source;
/// Optional extra words the user adds to any non-describe source.
@override@JsonKey() final  String extraNote;
/// The user's profile details: clothes are fitted to their real size, and
/// a Fashion Idol or Style twin look keeps their face from the face photo.
@override@JsonKey() final  BodyProfile body;

/// Create a copy of LookRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LookRequestCopyWith<_LookRequest> get copyWith => __$LookRequestCopyWithImpl<_LookRequest>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'LookRequest'))
    ..add(DiagnosticsProperty('photoUrl', photoUrl))..add(DiagnosticsProperty('scope', scope))..add(DiagnosticsProperty('source', source))..add(DiagnosticsProperty('extraNote', extraNote))..add(DiagnosticsProperty('body', body));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LookRequest&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.source, source) || other.source == source)&&(identical(other.extraNote, extraNote) || other.extraNote == extraNote)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode {
    return Object.hash(runtimeType,photoUrl,scope,source,extraNote,body);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'LookRequest(photoUrl: $photoUrl, scope: $scope, source: $source, extraNote: $extraNote, body: $body)';
}


}

/// @nodoc
abstract mixin class _$LookRequestCopyWith<$Res> implements $LookRequestCopyWith<$Res> {
  factory _$LookRequestCopyWith(_LookRequest value, $Res Function(_LookRequest) _then) = __$LookRequestCopyWithImpl;
@override @useResult
$Res call({
 String photoUrl, LookScope scope, LookSource source, String extraNote, BodyProfile body
});




}
/// @nodoc
class __$LookRequestCopyWithImpl<$Res>
    implements _$LookRequestCopyWith<$Res> {
  __$LookRequestCopyWithImpl(this._self, this._then);

  final _LookRequest _self;
  final $Res Function(_LookRequest) _then;

/// Create a copy of LookRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? photoUrl = null,Object? scope = null,Object? source = null,Object? extraNote = null,Object? body = null,}) {
  return _then(_LookRequest(
photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as LookScope,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LookSource,extraNote: null == extraNote ? _self.extraNote : extraNote // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as BodyProfile,
  ));
}


}

// dart format on
