// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'affirmation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AffirmationProvenance {

 String get historicalSource; String get contributor; String get contributorRights; String get curator; DateTime? get reviewedAt;
/// Create a copy of AffirmationProvenance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AffirmationProvenanceCopyWith<AffirmationProvenance> get copyWith => _$AffirmationProvenanceCopyWithImpl<AffirmationProvenance>(this as AffirmationProvenance, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AffirmationProvenance;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AffirmationProvenance&&(identical(other.historicalSource, _this.historicalSource) || other.historicalSource == _this.historicalSource)&&(identical(other.contributor, _this.contributor) || other.contributor == _this.contributor)&&(identical(other.contributorRights, _this.contributorRights) || other.contributorRights == _this.contributorRights)&&(identical(other.curator, _this.curator) || other.curator == _this.curator)&&(identical(other.reviewedAt, _this.reviewedAt) || other.reviewedAt == _this.reviewedAt));
}


@override
int get hashCode {
  final _this = this as AffirmationProvenance;
  return Object.hash(runtimeType,_this.historicalSource,_this.contributor,_this.contributorRights,_this.curator,_this.reviewedAt);
}

@override
String toString() {
  final _this = this as AffirmationProvenance;
  return 'AffirmationProvenance(historicalSource: ${_this.historicalSource}, contributor: ${_this.contributor}, contributorRights: ${_this.contributorRights}, curator: ${_this.curator}, reviewedAt: ${_this.reviewedAt})';
}


}

/// @nodoc
abstract mixin class $AffirmationProvenanceCopyWith<$Res>  {
  factory $AffirmationProvenanceCopyWith(AffirmationProvenance value, $Res Function(AffirmationProvenance) _then) = _$AffirmationProvenanceCopyWithImpl;
@useResult
$Res call({
 String historicalSource, String contributor, String contributorRights, String curator, DateTime? reviewedAt
});




}
/// @nodoc
class _$AffirmationProvenanceCopyWithImpl<$Res>
    implements $AffirmationProvenanceCopyWith<$Res> {
  _$AffirmationProvenanceCopyWithImpl(this._self, this._then);

  final AffirmationProvenance _self;
  final $Res Function(AffirmationProvenance) _then;

/// Create a copy of AffirmationProvenance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? historicalSource = null,Object? contributor = null,Object? contributorRights = null,Object? curator = null,Object? reviewedAt = freezed,}) {
  return _then(AffirmationProvenance(
historicalSource: null == historicalSource ? _self.historicalSource : historicalSource // ignore: cast_nullable_to_non_nullable
as String,contributor: null == contributor ? _self.contributor : contributor // ignore: cast_nullable_to_non_nullable
as String,contributorRights: null == contributorRights ? _self.contributorRights : contributorRights // ignore: cast_nullable_to_non_nullable
as String,curator: null == curator ? _self.curator : curator // ignore: cast_nullable_to_non_nullable
as String,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AffirmationProvenance].
extension AffirmationProvenancePatterns on AffirmationProvenance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AffirmationProvenance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AffirmationProvenance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AffirmationProvenance value)  $default,){
final _that = this;
switch (_that) {
case _AffirmationProvenance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AffirmationProvenance value)?  $default,){
final _that = this;
switch (_that) {
case _AffirmationProvenance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String historicalSource,  String contributor,  String contributorRights,  String curator,  DateTime? reviewedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AffirmationProvenance() when $default != null:
return $default(_that.historicalSource,_that.contributor,_that.contributorRights,_that.curator,_that.reviewedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String historicalSource,  String contributor,  String contributorRights,  String curator,  DateTime? reviewedAt)  $default,) {final _that = this;
switch (_that) {
case _AffirmationProvenance():
return $default(_that.historicalSource,_that.contributor,_that.contributorRights,_that.curator,_that.reviewedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String historicalSource,  String contributor,  String contributorRights,  String curator,  DateTime? reviewedAt)?  $default,) {final _that = this;
switch (_that) {
case _AffirmationProvenance() when $default != null:
return $default(_that.historicalSource,_that.contributor,_that.contributorRights,_that.curator,_that.reviewedAt);case _:
  return null;

}
}

}

/// @nodoc


class _AffirmationProvenance extends AffirmationProvenance {
  const _AffirmationProvenance({this.historicalSource = '', this.contributor = '', this.contributorRights = '', this.curator = '', this.reviewedAt}): super._();
  

@override@JsonKey() final  String historicalSource;
@override@JsonKey() final  String contributor;
@override@JsonKey() final  String contributorRights;
@override@JsonKey() final  String curator;
@override final  DateTime? reviewedAt;

/// Create a copy of AffirmationProvenance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AffirmationProvenanceCopyWith<_AffirmationProvenance> get copyWith => __$AffirmationProvenanceCopyWithImpl<_AffirmationProvenance>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AffirmationProvenance&&(identical(other.historicalSource, historicalSource) || other.historicalSource == historicalSource)&&(identical(other.contributor, contributor) || other.contributor == contributor)&&(identical(other.contributorRights, contributorRights) || other.contributorRights == contributorRights)&&(identical(other.curator, curator) || other.curator == curator)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,historicalSource,contributor,contributorRights,curator,reviewedAt);
}

@override
String toString() {
    return 'AffirmationProvenance(historicalSource: $historicalSource, contributor: $contributor, contributorRights: $contributorRights, curator: $curator, reviewedAt: $reviewedAt)';
}


}

/// @nodoc
abstract mixin class _$AffirmationProvenanceCopyWith<$Res> implements $AffirmationProvenanceCopyWith<$Res> {
  factory _$AffirmationProvenanceCopyWith(_AffirmationProvenance value, $Res Function(_AffirmationProvenance) _then) = __$AffirmationProvenanceCopyWithImpl;
@override @useResult
$Res call({
 String historicalSource, String contributor, String contributorRights, String curator, DateTime? reviewedAt
});




}
/// @nodoc
class __$AffirmationProvenanceCopyWithImpl<$Res>
    implements _$AffirmationProvenanceCopyWith<$Res> {
  __$AffirmationProvenanceCopyWithImpl(this._self, this._then);

  final _AffirmationProvenance _self;
  final $Res Function(_AffirmationProvenance) _then;

/// Create a copy of AffirmationProvenance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? historicalSource = null,Object? contributor = null,Object? contributorRights = null,Object? curator = null,Object? reviewedAt = freezed,}) {
  return _then(_AffirmationProvenance(
historicalSource: null == historicalSource ? _self.historicalSource : historicalSource // ignore: cast_nullable_to_non_nullable
as String,contributor: null == contributor ? _self.contributor : contributor // ignore: cast_nullable_to_non_nullable
as String,contributorRights: null == contributorRights ? _self.contributorRights : contributorRights // ignore: cast_nullable_to_non_nullable
as String,curator: null == curator ? _self.curator : curator // ignore: cast_nullable_to_non_nullable
as String,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$AffirmationDefinition {

 String get id; String get text;/// Accessible text label. Required so custom emoji are never the only
/// carrier of meaning (NFR-006, and the localisation rules in BNG SRS 001).
 String get shortLabel; AffirmationCategory get category; String get emoji; String get language; String get translation; String get transliteration; String get pronunciation; String get meaning; String get country; String get region; String get culture; String get communityScope; String get occasion; String get formality; String get audioUrl; String get audioTranscript; String get performer; AffirmationReviewState get reviewState; AffirmationProvenance get provenance; int get version; List<String> get safetyLabels; String get retirementReason;
/// Create a copy of AffirmationDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AffirmationDefinitionCopyWith<AffirmationDefinition> get copyWith => _$AffirmationDefinitionCopyWithImpl<AffirmationDefinition>(this as AffirmationDefinition, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AffirmationDefinition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AffirmationDefinition&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.shortLabel, _this.shortLabel) || other.shortLabel == _this.shortLabel)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.emoji, _this.emoji) || other.emoji == _this.emoji)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.translation, _this.translation) || other.translation == _this.translation)&&(identical(other.transliteration, _this.transliteration) || other.transliteration == _this.transliteration)&&(identical(other.pronunciation, _this.pronunciation) || other.pronunciation == _this.pronunciation)&&(identical(other.meaning, _this.meaning) || other.meaning == _this.meaning)&&(identical(other.country, _this.country) || other.country == _this.country)&&(identical(other.region, _this.region) || other.region == _this.region)&&(identical(other.culture, _this.culture) || other.culture == _this.culture)&&(identical(other.communityScope, _this.communityScope) || other.communityScope == _this.communityScope)&&(identical(other.occasion, _this.occasion) || other.occasion == _this.occasion)&&(identical(other.formality, _this.formality) || other.formality == _this.formality)&&(identical(other.audioUrl, _this.audioUrl) || other.audioUrl == _this.audioUrl)&&(identical(other.audioTranscript, _this.audioTranscript) || other.audioTranscript == _this.audioTranscript)&&(identical(other.performer, _this.performer) || other.performer == _this.performer)&&(identical(other.reviewState, _this.reviewState) || other.reviewState == _this.reviewState)&&(identical(other.provenance, _this.provenance) || other.provenance == _this.provenance)&&(identical(other.version, _this.version) || other.version == _this.version)&&const DeepCollectionEquality().equals(other.safetyLabels, _this.safetyLabels)&&(identical(other.retirementReason, _this.retirementReason) || other.retirementReason == _this.retirementReason));
}


@override
int get hashCode {
  final _this = this as AffirmationDefinition;
  return Object.hashAll([runtimeType,_this.id,_this.text,_this.shortLabel,_this.category,_this.emoji,_this.language,_this.translation,_this.transliteration,_this.pronunciation,_this.meaning,_this.country,_this.region,_this.culture,_this.communityScope,_this.occasion,_this.formality,_this.audioUrl,_this.audioTranscript,_this.performer,_this.reviewState,_this.provenance,_this.version,const DeepCollectionEquality().hash(_this.safetyLabels),_this.retirementReason]);
}

@override
String toString() {
  final _this = this as AffirmationDefinition;
  return 'AffirmationDefinition(id: ${_this.id}, text: ${_this.text}, shortLabel: ${_this.shortLabel}, category: ${_this.category}, emoji: ${_this.emoji}, language: ${_this.language}, translation: ${_this.translation}, transliteration: ${_this.transliteration}, pronunciation: ${_this.pronunciation}, meaning: ${_this.meaning}, country: ${_this.country}, region: ${_this.region}, culture: ${_this.culture}, communityScope: ${_this.communityScope}, occasion: ${_this.occasion}, formality: ${_this.formality}, audioUrl: ${_this.audioUrl}, audioTranscript: ${_this.audioTranscript}, performer: ${_this.performer}, reviewState: ${_this.reviewState}, provenance: ${_this.provenance}, version: ${_this.version}, safetyLabels: ${_this.safetyLabels}, retirementReason: ${_this.retirementReason})';
}


}

/// @nodoc
abstract mixin class $AffirmationDefinitionCopyWith<$Res>  {
  factory $AffirmationDefinitionCopyWith(AffirmationDefinition value, $Res Function(AffirmationDefinition) _then) = _$AffirmationDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String text, String shortLabel, AffirmationCategory category, String emoji, String language, String translation, String transliteration, String pronunciation, String meaning, String country, String region, String culture, String communityScope, String occasion, String formality, String audioUrl, String audioTranscript, String performer, AffirmationReviewState reviewState, AffirmationProvenance provenance, int version, List<String> safetyLabels, String retirementReason
});


$AffirmationProvenanceCopyWith<$Res> get provenance;

}
/// @nodoc
class _$AffirmationDefinitionCopyWithImpl<$Res>
    implements $AffirmationDefinitionCopyWith<$Res> {
  _$AffirmationDefinitionCopyWithImpl(this._self, this._then);

  final AffirmationDefinition _self;
  final $Res Function(AffirmationDefinition) _then;

/// Create a copy of AffirmationDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? shortLabel = null,Object? category = null,Object? emoji = null,Object? language = null,Object? translation = null,Object? transliteration = null,Object? pronunciation = null,Object? meaning = null,Object? country = null,Object? region = null,Object? culture = null,Object? communityScope = null,Object? occasion = null,Object? formality = null,Object? audioUrl = null,Object? audioTranscript = null,Object? performer = null,Object? reviewState = null,Object? provenance = null,Object? version = null,Object? safetyLabels = null,Object? retirementReason = null,}) {
  return _then(AffirmationDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,shortLabel: null == shortLabel ? _self.shortLabel : shortLabel // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as AffirmationCategory,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,translation: null == translation ? _self.translation : translation // ignore: cast_nullable_to_non_nullable
as String,transliteration: null == transliteration ? _self.transliteration : transliteration // ignore: cast_nullable_to_non_nullable
as String,pronunciation: null == pronunciation ? _self.pronunciation : pronunciation // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,culture: null == culture ? _self.culture : culture // ignore: cast_nullable_to_non_nullable
as String,communityScope: null == communityScope ? _self.communityScope : communityScope // ignore: cast_nullable_to_non_nullable
as String,occasion: null == occasion ? _self.occasion : occasion // ignore: cast_nullable_to_non_nullable
as String,formality: null == formality ? _self.formality : formality // ignore: cast_nullable_to_non_nullable
as String,audioUrl: null == audioUrl ? _self.audioUrl : audioUrl // ignore: cast_nullable_to_non_nullable
as String,audioTranscript: null == audioTranscript ? _self.audioTranscript : audioTranscript // ignore: cast_nullable_to_non_nullable
as String,performer: null == performer ? _self.performer : performer // ignore: cast_nullable_to_non_nullable
as String,reviewState: null == reviewState ? _self.reviewState : reviewState // ignore: cast_nullable_to_non_nullable
as AffirmationReviewState,provenance: null == provenance ? _self.provenance : provenance // ignore: cast_nullable_to_non_nullable
as AffirmationProvenance,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,safetyLabels: null == safetyLabels ? _self.safetyLabels : safetyLabels // ignore: cast_nullable_to_non_nullable
as List<String>,retirementReason: null == retirementReason ? _self.retirementReason : retirementReason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of AffirmationDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AffirmationProvenanceCopyWith<$Res> get provenance {
  
  return $AffirmationProvenanceCopyWith<$Res>(_self.provenance, (value) {
    return _then(_self.copyWith(provenance: value));
  });
}
}


/// Adds pattern-matching-related methods to [AffirmationDefinition].
extension AffirmationDefinitionPatterns on AffirmationDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AffirmationDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AffirmationDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AffirmationDefinition value)  $default,){
final _that = this;
switch (_that) {
case _AffirmationDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AffirmationDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _AffirmationDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text,  String shortLabel,  AffirmationCategory category,  String emoji,  String language,  String translation,  String transliteration,  String pronunciation,  String meaning,  String country,  String region,  String culture,  String communityScope,  String occasion,  String formality,  String audioUrl,  String audioTranscript,  String performer,  AffirmationReviewState reviewState,  AffirmationProvenance provenance,  int version,  List<String> safetyLabels,  String retirementReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AffirmationDefinition() when $default != null:
return $default(_that.id,_that.text,_that.shortLabel,_that.category,_that.emoji,_that.language,_that.translation,_that.transliteration,_that.pronunciation,_that.meaning,_that.country,_that.region,_that.culture,_that.communityScope,_that.occasion,_that.formality,_that.audioUrl,_that.audioTranscript,_that.performer,_that.reviewState,_that.provenance,_that.version,_that.safetyLabels,_that.retirementReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text,  String shortLabel,  AffirmationCategory category,  String emoji,  String language,  String translation,  String transliteration,  String pronunciation,  String meaning,  String country,  String region,  String culture,  String communityScope,  String occasion,  String formality,  String audioUrl,  String audioTranscript,  String performer,  AffirmationReviewState reviewState,  AffirmationProvenance provenance,  int version,  List<String> safetyLabels,  String retirementReason)  $default,) {final _that = this;
switch (_that) {
case _AffirmationDefinition():
return $default(_that.id,_that.text,_that.shortLabel,_that.category,_that.emoji,_that.language,_that.translation,_that.transliteration,_that.pronunciation,_that.meaning,_that.country,_that.region,_that.culture,_that.communityScope,_that.occasion,_that.formality,_that.audioUrl,_that.audioTranscript,_that.performer,_that.reviewState,_that.provenance,_that.version,_that.safetyLabels,_that.retirementReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text,  String shortLabel,  AffirmationCategory category,  String emoji,  String language,  String translation,  String transliteration,  String pronunciation,  String meaning,  String country,  String region,  String culture,  String communityScope,  String occasion,  String formality,  String audioUrl,  String audioTranscript,  String performer,  AffirmationReviewState reviewState,  AffirmationProvenance provenance,  int version,  List<String> safetyLabels,  String retirementReason)?  $default,) {final _that = this;
switch (_that) {
case _AffirmationDefinition() when $default != null:
return $default(_that.id,_that.text,_that.shortLabel,_that.category,_that.emoji,_that.language,_that.translation,_that.transliteration,_that.pronunciation,_that.meaning,_that.country,_that.region,_that.culture,_that.communityScope,_that.occasion,_that.formality,_that.audioUrl,_that.audioTranscript,_that.performer,_that.reviewState,_that.provenance,_that.version,_that.safetyLabels,_that.retirementReason);case _:
  return null;

}
}

}

/// @nodoc


class _AffirmationDefinition extends AffirmationDefinition {
  const _AffirmationDefinition({required this.id, required this.text, required this.shortLabel, required this.category, required this.emoji, this.language = 'en', this.translation = '', this.transliteration = '', this.pronunciation = '', this.meaning = '', this.country = '', this.region = '', this.culture = '', this.communityScope = '', this.occasion = '', this.formality = '', this.audioUrl = '', this.audioTranscript = '', this.performer = '', this.reviewState = AffirmationReviewState.draft, this.provenance = const AffirmationProvenance(), this.version = 1,  List<String> safetyLabels = const [], this.retirementReason = ''}): _safetyLabels = safetyLabels,super._();
  

@override final  String id;
@override final  String text;
/// Accessible text label. Required so custom emoji are never the only
/// carrier of meaning (NFR-006, and the localisation rules in BNG SRS 001).
@override final  String shortLabel;
@override final  AffirmationCategory category;
@override final  String emoji;
@override@JsonKey() final  String language;
@override@JsonKey() final  String translation;
@override@JsonKey() final  String transliteration;
@override@JsonKey() final  String pronunciation;
@override@JsonKey() final  String meaning;
@override@JsonKey() final  String country;
@override@JsonKey() final  String region;
@override@JsonKey() final  String culture;
@override@JsonKey() final  String communityScope;
@override@JsonKey() final  String occasion;
@override@JsonKey() final  String formality;
@override@JsonKey() final  String audioUrl;
@override@JsonKey() final  String audioTranscript;
@override@JsonKey() final  String performer;
@override@JsonKey() final  AffirmationReviewState reviewState;
@override@JsonKey() final  AffirmationProvenance provenance;
@override@JsonKey() final  int version;
 final  List<String> _safetyLabels;
@override@JsonKey() List<String> get safetyLabels {
  if (_safetyLabels is EqualUnmodifiableListView) return _safetyLabels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_safetyLabels);
}

@override@JsonKey() final  String retirementReason;

/// Create a copy of AffirmationDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AffirmationDefinitionCopyWith<_AffirmationDefinition> get copyWith => __$AffirmationDefinitionCopyWithImpl<_AffirmationDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AffirmationDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.shortLabel, shortLabel) || other.shortLabel == shortLabel)&&(identical(other.category, category) || other.category == category)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.language, language) || other.language == language)&&(identical(other.translation, translation) || other.translation == translation)&&(identical(other.transliteration, transliteration) || other.transliteration == transliteration)&&(identical(other.pronunciation, pronunciation) || other.pronunciation == pronunciation)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.country, country) || other.country == country)&&(identical(other.region, region) || other.region == region)&&(identical(other.culture, culture) || other.culture == culture)&&(identical(other.communityScope, communityScope) || other.communityScope == communityScope)&&(identical(other.occasion, occasion) || other.occasion == occasion)&&(identical(other.formality, formality) || other.formality == formality)&&(identical(other.audioUrl, audioUrl) || other.audioUrl == audioUrl)&&(identical(other.audioTranscript, audioTranscript) || other.audioTranscript == audioTranscript)&&(identical(other.performer, performer) || other.performer == performer)&&(identical(other.reviewState, reviewState) || other.reviewState == reviewState)&&(identical(other.provenance, provenance) || other.provenance == provenance)&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other.safetyLabels, _safetyLabels)&&(identical(other.retirementReason, retirementReason) || other.retirementReason == retirementReason));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,text,shortLabel,category,emoji,language,translation,transliteration,pronunciation,meaning,country,region,culture,communityScope,occasion,formality,audioUrl,audioTranscript,performer,reviewState,provenance,version,const DeepCollectionEquality().hash(_safetyLabels),retirementReason]);
}

@override
String toString() {
    return 'AffirmationDefinition(id: $id, text: $text, shortLabel: $shortLabel, category: $category, emoji: $emoji, language: $language, translation: $translation, transliteration: $transliteration, pronunciation: $pronunciation, meaning: $meaning, country: $country, region: $region, culture: $culture, communityScope: $communityScope, occasion: $occasion, formality: $formality, audioUrl: $audioUrl, audioTranscript: $audioTranscript, performer: $performer, reviewState: $reviewState, provenance: $provenance, version: $version, safetyLabels: $safetyLabels, retirementReason: $retirementReason)';
}


}

/// @nodoc
abstract mixin class _$AffirmationDefinitionCopyWith<$Res> implements $AffirmationDefinitionCopyWith<$Res> {
  factory _$AffirmationDefinitionCopyWith(_AffirmationDefinition value, $Res Function(_AffirmationDefinition) _then) = __$AffirmationDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, String shortLabel, AffirmationCategory category, String emoji, String language, String translation, String transliteration, String pronunciation, String meaning, String country, String region, String culture, String communityScope, String occasion, String formality, String audioUrl, String audioTranscript, String performer, AffirmationReviewState reviewState, AffirmationProvenance provenance, int version, List<String> safetyLabels, String retirementReason
});


@override $AffirmationProvenanceCopyWith<$Res> get provenance;

}
/// @nodoc
class __$AffirmationDefinitionCopyWithImpl<$Res>
    implements _$AffirmationDefinitionCopyWith<$Res> {
  __$AffirmationDefinitionCopyWithImpl(this._self, this._then);

  final _AffirmationDefinition _self;
  final $Res Function(_AffirmationDefinition) _then;

/// Create a copy of AffirmationDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? shortLabel = null,Object? category = null,Object? emoji = null,Object? language = null,Object? translation = null,Object? transliteration = null,Object? pronunciation = null,Object? meaning = null,Object? country = null,Object? region = null,Object? culture = null,Object? communityScope = null,Object? occasion = null,Object? formality = null,Object? audioUrl = null,Object? audioTranscript = null,Object? performer = null,Object? reviewState = null,Object? provenance = null,Object? version = null,Object? safetyLabels = null,Object? retirementReason = null,}) {
  return _then(_AffirmationDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,shortLabel: null == shortLabel ? _self.shortLabel : shortLabel // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as AffirmationCategory,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,translation: null == translation ? _self.translation : translation // ignore: cast_nullable_to_non_nullable
as String,transliteration: null == transliteration ? _self.transliteration : transliteration // ignore: cast_nullable_to_non_nullable
as String,pronunciation: null == pronunciation ? _self.pronunciation : pronunciation // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,culture: null == culture ? _self.culture : culture // ignore: cast_nullable_to_non_nullable
as String,communityScope: null == communityScope ? _self.communityScope : communityScope // ignore: cast_nullable_to_non_nullable
as String,occasion: null == occasion ? _self.occasion : occasion // ignore: cast_nullable_to_non_nullable
as String,formality: null == formality ? _self.formality : formality // ignore: cast_nullable_to_non_nullable
as String,audioUrl: null == audioUrl ? _self.audioUrl : audioUrl // ignore: cast_nullable_to_non_nullable
as String,audioTranscript: null == audioTranscript ? _self.audioTranscript : audioTranscript // ignore: cast_nullable_to_non_nullable
as String,performer: null == performer ? _self.performer : performer // ignore: cast_nullable_to_non_nullable
as String,reviewState: null == reviewState ? _self.reviewState : reviewState // ignore: cast_nullable_to_non_nullable
as AffirmationReviewState,provenance: null == provenance ? _self.provenance : provenance // ignore: cast_nullable_to_non_nullable
as AffirmationProvenance,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,safetyLabels: null == safetyLabels ? _self._safetyLabels : safetyLabels // ignore: cast_nullable_to_non_nullable
as List<String>,retirementReason: null == retirementReason ? _self.retirementReason : retirementReason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of AffirmationDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AffirmationProvenanceCopyWith<$Res> get provenance {
  
  return $AffirmationProvenanceCopyWith<$Res>(_self.provenance, (value) {
    return _then(_self.copyWith(provenance: value));
  });
}
}

/// @nodoc
mixin _$Affirmation {

 String get id; String get senderId; String get senderName; AffirmationTargetType get targetType; String get targetId; String get targetOwnerId;/// Library entry this affirmation was sent from.
 String get definitionId; String get emoji; String get shortLabel; String get text; AffirmationCategory get category; DateTime get createdAt; String get language; String get meaning;/// Optional user-authored supportive text. Moderated for harassment,
/// sexualisation, manipulation and spam.
 String get personalMessage; String get moderationState;/// Set on records produced by the like-to-affirmation backfill, so the
/// migration can be identified and reversed.
 bool get migratedFromLike;
/// Create a copy of Affirmation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AffirmationCopyWith<Affirmation> get copyWith => _$AffirmationCopyWithImpl<Affirmation>(this as Affirmation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Affirmation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Affirmation&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.senderId, _this.senderId) || other.senderId == _this.senderId)&&(identical(other.senderName, _this.senderName) || other.senderName == _this.senderName)&&(identical(other.targetType, _this.targetType) || other.targetType == _this.targetType)&&(identical(other.targetId, _this.targetId) || other.targetId == _this.targetId)&&(identical(other.targetOwnerId, _this.targetOwnerId) || other.targetOwnerId == _this.targetOwnerId)&&(identical(other.definitionId, _this.definitionId) || other.definitionId == _this.definitionId)&&(identical(other.emoji, _this.emoji) || other.emoji == _this.emoji)&&(identical(other.shortLabel, _this.shortLabel) || other.shortLabel == _this.shortLabel)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.meaning, _this.meaning) || other.meaning == _this.meaning)&&(identical(other.personalMessage, _this.personalMessage) || other.personalMessage == _this.personalMessage)&&(identical(other.moderationState, _this.moderationState) || other.moderationState == _this.moderationState)&&(identical(other.migratedFromLike, _this.migratedFromLike) || other.migratedFromLike == _this.migratedFromLike));
}


@override
int get hashCode {
  final _this = this as Affirmation;
  return Object.hash(runtimeType,_this.id,_this.senderId,_this.senderName,_this.targetType,_this.targetId,_this.targetOwnerId,_this.definitionId,_this.emoji,_this.shortLabel,_this.text,_this.category,_this.createdAt,_this.language,_this.meaning,_this.personalMessage,_this.moderationState,_this.migratedFromLike);
}

@override
String toString() {
  final _this = this as Affirmation;
  return 'Affirmation(id: ${_this.id}, senderId: ${_this.senderId}, senderName: ${_this.senderName}, targetType: ${_this.targetType}, targetId: ${_this.targetId}, targetOwnerId: ${_this.targetOwnerId}, definitionId: ${_this.definitionId}, emoji: ${_this.emoji}, shortLabel: ${_this.shortLabel}, text: ${_this.text}, category: ${_this.category}, createdAt: ${_this.createdAt}, language: ${_this.language}, meaning: ${_this.meaning}, personalMessage: ${_this.personalMessage}, moderationState: ${_this.moderationState}, migratedFromLike: ${_this.migratedFromLike})';
}


}

/// @nodoc
abstract mixin class $AffirmationCopyWith<$Res>  {
  factory $AffirmationCopyWith(Affirmation value, $Res Function(Affirmation) _then) = _$AffirmationCopyWithImpl;
@useResult
$Res call({
 String id, String senderId, String senderName, AffirmationTargetType targetType, String targetId, String targetOwnerId, String definitionId, String emoji, String shortLabel, String text, AffirmationCategory category, DateTime createdAt, String language, String meaning, String personalMessage, String moderationState, bool migratedFromLike
});




}
/// @nodoc
class _$AffirmationCopyWithImpl<$Res>
    implements $AffirmationCopyWith<$Res> {
  _$AffirmationCopyWithImpl(this._self, this._then);

  final Affirmation _self;
  final $Res Function(Affirmation) _then;

/// Create a copy of Affirmation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? senderId = null,Object? senderName = null,Object? targetType = null,Object? targetId = null,Object? targetOwnerId = null,Object? definitionId = null,Object? emoji = null,Object? shortLabel = null,Object? text = null,Object? category = null,Object? createdAt = null,Object? language = null,Object? meaning = null,Object? personalMessage = null,Object? moderationState = null,Object? migratedFromLike = null,}) {
  return _then(Affirmation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as AffirmationTargetType,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,targetOwnerId: null == targetOwnerId ? _self.targetOwnerId : targetOwnerId // ignore: cast_nullable_to_non_nullable
as String,definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,shortLabel: null == shortLabel ? _self.shortLabel : shortLabel // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as AffirmationCategory,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,personalMessage: null == personalMessage ? _self.personalMessage : personalMessage // ignore: cast_nullable_to_non_nullable
as String,moderationState: null == moderationState ? _self.moderationState : moderationState // ignore: cast_nullable_to_non_nullable
as String,migratedFromLike: null == migratedFromLike ? _self.migratedFromLike : migratedFromLike // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Affirmation].
extension AffirmationPatterns on Affirmation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Affirmation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Affirmation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Affirmation value)  $default,){
final _that = this;
switch (_that) {
case _Affirmation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Affirmation value)?  $default,){
final _that = this;
switch (_that) {
case _Affirmation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String senderId,  String senderName,  AffirmationTargetType targetType,  String targetId,  String targetOwnerId,  String definitionId,  String emoji,  String shortLabel,  String text,  AffirmationCategory category,  DateTime createdAt,  String language,  String meaning,  String personalMessage,  String moderationState,  bool migratedFromLike)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Affirmation() when $default != null:
return $default(_that.id,_that.senderId,_that.senderName,_that.targetType,_that.targetId,_that.targetOwnerId,_that.definitionId,_that.emoji,_that.shortLabel,_that.text,_that.category,_that.createdAt,_that.language,_that.meaning,_that.personalMessage,_that.moderationState,_that.migratedFromLike);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String senderId,  String senderName,  AffirmationTargetType targetType,  String targetId,  String targetOwnerId,  String definitionId,  String emoji,  String shortLabel,  String text,  AffirmationCategory category,  DateTime createdAt,  String language,  String meaning,  String personalMessage,  String moderationState,  bool migratedFromLike)  $default,) {final _that = this;
switch (_that) {
case _Affirmation():
return $default(_that.id,_that.senderId,_that.senderName,_that.targetType,_that.targetId,_that.targetOwnerId,_that.definitionId,_that.emoji,_that.shortLabel,_that.text,_that.category,_that.createdAt,_that.language,_that.meaning,_that.personalMessage,_that.moderationState,_that.migratedFromLike);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String senderId,  String senderName,  AffirmationTargetType targetType,  String targetId,  String targetOwnerId,  String definitionId,  String emoji,  String shortLabel,  String text,  AffirmationCategory category,  DateTime createdAt,  String language,  String meaning,  String personalMessage,  String moderationState,  bool migratedFromLike)?  $default,) {final _that = this;
switch (_that) {
case _Affirmation() when $default != null:
return $default(_that.id,_that.senderId,_that.senderName,_that.targetType,_that.targetId,_that.targetOwnerId,_that.definitionId,_that.emoji,_that.shortLabel,_that.text,_that.category,_that.createdAt,_that.language,_that.meaning,_that.personalMessage,_that.moderationState,_that.migratedFromLike);case _:
  return null;

}
}

}

/// @nodoc


class _Affirmation extends Affirmation {
  const _Affirmation({required this.id, required this.senderId, required this.senderName, required this.targetType, required this.targetId, required this.targetOwnerId, required this.definitionId, required this.emoji, required this.shortLabel, required this.text, required this.category, required this.createdAt, this.language = 'en', this.meaning = '', this.personalMessage = '', this.moderationState = 'clear', this.migratedFromLike = false}): super._();
  

@override final  String id;
@override final  String senderId;
@override final  String senderName;
@override final  AffirmationTargetType targetType;
@override final  String targetId;
@override final  String targetOwnerId;
/// Library entry this affirmation was sent from.
@override final  String definitionId;
@override final  String emoji;
@override final  String shortLabel;
@override final  String text;
@override final  AffirmationCategory category;
@override final  DateTime createdAt;
@override@JsonKey() final  String language;
@override@JsonKey() final  String meaning;
/// Optional user-authored supportive text. Moderated for harassment,
/// sexualisation, manipulation and spam.
@override@JsonKey() final  String personalMessage;
@override@JsonKey() final  String moderationState;
/// Set on records produced by the like-to-affirmation backfill, so the
/// migration can be identified and reversed.
@override@JsonKey() final  bool migratedFromLike;

/// Create a copy of Affirmation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AffirmationCopyWith<_Affirmation> get copyWith => __$AffirmationCopyWithImpl<_Affirmation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Affirmation&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.targetOwnerId, targetOwnerId) || other.targetOwnerId == targetOwnerId)&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.shortLabel, shortLabel) || other.shortLabel == shortLabel)&&(identical(other.text, text) || other.text == text)&&(identical(other.category, category) || other.category == category)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.language, language) || other.language == language)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.personalMessage, personalMessage) || other.personalMessage == personalMessage)&&(identical(other.moderationState, moderationState) || other.moderationState == moderationState)&&(identical(other.migratedFromLike, migratedFromLike) || other.migratedFromLike == migratedFromLike));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,senderId,senderName,targetType,targetId,targetOwnerId,definitionId,emoji,shortLabel,text,category,createdAt,language,meaning,personalMessage,moderationState,migratedFromLike);
}

@override
String toString() {
    return 'Affirmation(id: $id, senderId: $senderId, senderName: $senderName, targetType: $targetType, targetId: $targetId, targetOwnerId: $targetOwnerId, definitionId: $definitionId, emoji: $emoji, shortLabel: $shortLabel, text: $text, category: $category, createdAt: $createdAt, language: $language, meaning: $meaning, personalMessage: $personalMessage, moderationState: $moderationState, migratedFromLike: $migratedFromLike)';
}


}

/// @nodoc
abstract mixin class _$AffirmationCopyWith<$Res> implements $AffirmationCopyWith<$Res> {
  factory _$AffirmationCopyWith(_Affirmation value, $Res Function(_Affirmation) _then) = __$AffirmationCopyWithImpl;
@override @useResult
$Res call({
 String id, String senderId, String senderName, AffirmationTargetType targetType, String targetId, String targetOwnerId, String definitionId, String emoji, String shortLabel, String text, AffirmationCategory category, DateTime createdAt, String language, String meaning, String personalMessage, String moderationState, bool migratedFromLike
});




}
/// @nodoc
class __$AffirmationCopyWithImpl<$Res>
    implements _$AffirmationCopyWith<$Res> {
  __$AffirmationCopyWithImpl(this._self, this._then);

  final _Affirmation _self;
  final $Res Function(_Affirmation) _then;

/// Create a copy of Affirmation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? senderId = null,Object? senderName = null,Object? targetType = null,Object? targetId = null,Object? targetOwnerId = null,Object? definitionId = null,Object? emoji = null,Object? shortLabel = null,Object? text = null,Object? category = null,Object? createdAt = null,Object? language = null,Object? meaning = null,Object? personalMessage = null,Object? moderationState = null,Object? migratedFromLike = null,}) {
  return _then(_Affirmation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as AffirmationTargetType,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,targetOwnerId: null == targetOwnerId ? _self.targetOwnerId : targetOwnerId // ignore: cast_nullable_to_non_nullable
as String,definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,shortLabel: null == shortLabel ? _self.shortLabel : shortLabel // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as AffirmationCategory,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,personalMessage: null == personalMessage ? _self.personalMessage : personalMessage // ignore: cast_nullable_to_non_nullable
as String,moderationState: null == moderationState ? _self.moderationState : moderationState // ignore: cast_nullable_to_non_nullable
as String,migratedFromLike: null == migratedFromLike ? _self.migratedFromLike : migratedFromLike // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
