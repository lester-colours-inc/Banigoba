// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'makeover_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MakeoverStage {

 MakeoverDomain get domain; MakeoverStageStatus get status;/// Images this stage produced. The stage that runs last carries the
/// selectable alternatives; earlier stages carry a single intermediate.
 List<String> get outputImageUrls; String get errorMessage; DateTime? get startedAt; DateTime? get completedAt;
/// Create a copy of MakeoverStage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MakeoverStageCopyWith<MakeoverStage> get copyWith => _$MakeoverStageCopyWithImpl<MakeoverStage>(this as MakeoverStage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MakeoverStage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MakeoverStage&&(identical(other.domain, _this.domain) || other.domain == _this.domain)&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.outputImageUrls, _this.outputImageUrls)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt));
}


@override
int get hashCode {
  final _this = this as MakeoverStage;
  return Object.hash(runtimeType,_this.domain,_this.status,const DeepCollectionEquality().hash(_this.outputImageUrls),_this.errorMessage,_this.startedAt,_this.completedAt);
}

@override
String toString() {
  final _this = this as MakeoverStage;
  return 'MakeoverStage(domain: ${_this.domain}, status: ${_this.status}, outputImageUrls: ${_this.outputImageUrls}, errorMessage: ${_this.errorMessage}, startedAt: ${_this.startedAt}, completedAt: ${_this.completedAt})';
}


}

/// @nodoc
abstract mixin class $MakeoverStageCopyWith<$Res>  {
  factory $MakeoverStageCopyWith(MakeoverStage value, $Res Function(MakeoverStage) _then) = _$MakeoverStageCopyWithImpl;
@useResult
$Res call({
 MakeoverDomain domain, MakeoverStageStatus status, List<String> outputImageUrls, String errorMessage, DateTime? startedAt, DateTime? completedAt
});




}
/// @nodoc
class _$MakeoverStageCopyWithImpl<$Res>
    implements $MakeoverStageCopyWith<$Res> {
  _$MakeoverStageCopyWithImpl(this._self, this._then);

  final MakeoverStage _self;
  final $Res Function(MakeoverStage) _then;

/// Create a copy of MakeoverStage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? domain = null,Object? status = null,Object? outputImageUrls = null,Object? errorMessage = null,Object? startedAt = freezed,Object? completedAt = freezed,}) {
  return _then(MakeoverStage(
domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as MakeoverDomain,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MakeoverStageStatus,outputImageUrls: null == outputImageUrls ? _self.outputImageUrls : outputImageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MakeoverStage].
extension MakeoverStagePatterns on MakeoverStage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MakeoverStage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MakeoverStage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MakeoverStage value)  $default,){
final _that = this;
switch (_that) {
case _MakeoverStage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MakeoverStage value)?  $default,){
final _that = this;
switch (_that) {
case _MakeoverStage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MakeoverDomain domain,  MakeoverStageStatus status,  List<String> outputImageUrls,  String errorMessage,  DateTime? startedAt,  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MakeoverStage() when $default != null:
return $default(_that.domain,_that.status,_that.outputImageUrls,_that.errorMessage,_that.startedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MakeoverDomain domain,  MakeoverStageStatus status,  List<String> outputImageUrls,  String errorMessage,  DateTime? startedAt,  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _MakeoverStage():
return $default(_that.domain,_that.status,_that.outputImageUrls,_that.errorMessage,_that.startedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MakeoverDomain domain,  MakeoverStageStatus status,  List<String> outputImageUrls,  String errorMessage,  DateTime? startedAt,  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _MakeoverStage() when $default != null:
return $default(_that.domain,_that.status,_that.outputImageUrls,_that.errorMessage,_that.startedAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc


class _MakeoverStage extends MakeoverStage {
  const _MakeoverStage({required this.domain, this.status = MakeoverStageStatus.queued,  List<String> outputImageUrls = const [], this.errorMessage = '', this.startedAt, this.completedAt}): _outputImageUrls = outputImageUrls,super._();
  

@override final  MakeoverDomain domain;
@override@JsonKey() final  MakeoverStageStatus status;
/// Images this stage produced. The stage that runs last carries the
/// selectable alternatives; earlier stages carry a single intermediate.
 final  List<String> _outputImageUrls;
/// Images this stage produced. The stage that runs last carries the
/// selectable alternatives; earlier stages carry a single intermediate.
@override@JsonKey() List<String> get outputImageUrls {
  if (_outputImageUrls is EqualUnmodifiableListView) return _outputImageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outputImageUrls);
}

@override@JsonKey() final  String errorMessage;
@override final  DateTime? startedAt;
@override final  DateTime? completedAt;

/// Create a copy of MakeoverStage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MakeoverStageCopyWith<_MakeoverStage> get copyWith => __$MakeoverStageCopyWithImpl<_MakeoverStage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MakeoverStage&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.outputImageUrls, _outputImageUrls)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,domain,status,const DeepCollectionEquality().hash(_outputImageUrls),errorMessage,startedAt,completedAt);
}

@override
String toString() {
    return 'MakeoverStage(domain: $domain, status: $status, outputImageUrls: $outputImageUrls, errorMessage: $errorMessage, startedAt: $startedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$MakeoverStageCopyWith<$Res> implements $MakeoverStageCopyWith<$Res> {
  factory _$MakeoverStageCopyWith(_MakeoverStage value, $Res Function(_MakeoverStage) _then) = __$MakeoverStageCopyWithImpl;
@override @useResult
$Res call({
 MakeoverDomain domain, MakeoverStageStatus status, List<String> outputImageUrls, String errorMessage, DateTime? startedAt, DateTime? completedAt
});




}
/// @nodoc
class __$MakeoverStageCopyWithImpl<$Res>
    implements _$MakeoverStageCopyWith<$Res> {
  __$MakeoverStageCopyWithImpl(this._self, this._then);

  final _MakeoverStage _self;
  final $Res Function(_MakeoverStage) _then;

/// Create a copy of MakeoverStage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? domain = null,Object? status = null,Object? outputImageUrls = null,Object? errorMessage = null,Object? startedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_MakeoverStage(
domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as MakeoverDomain,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MakeoverStageStatus,outputImageUrls: null == outputImageUrls ? _self._outputImageUrls : outputImageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$MakeoverIntent {

 String get occasion; String get desiredFeeling;/// Hair instruction. Empty means hair is left alone.
 String get hairPrompt;/// Catalogue products to try on. Empty means clothing is left alone.
 List<Map<String, dynamic>> get garments; String get climate; String get modestyPreference; String get budget; List<String> get exclusions;
/// Create a copy of MakeoverIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MakeoverIntentCopyWith<MakeoverIntent> get copyWith => _$MakeoverIntentCopyWithImpl<MakeoverIntent>(this as MakeoverIntent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MakeoverIntent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MakeoverIntent&&(identical(other.occasion, _this.occasion) || other.occasion == _this.occasion)&&(identical(other.desiredFeeling, _this.desiredFeeling) || other.desiredFeeling == _this.desiredFeeling)&&(identical(other.hairPrompt, _this.hairPrompt) || other.hairPrompt == _this.hairPrompt)&&const DeepCollectionEquality().equals(other.garments, _this.garments)&&(identical(other.climate, _this.climate) || other.climate == _this.climate)&&(identical(other.modestyPreference, _this.modestyPreference) || other.modestyPreference == _this.modestyPreference)&&(identical(other.budget, _this.budget) || other.budget == _this.budget)&&const DeepCollectionEquality().equals(other.exclusions, _this.exclusions));
}


@override
int get hashCode {
  final _this = this as MakeoverIntent;
  return Object.hash(runtimeType,_this.occasion,_this.desiredFeeling,_this.hairPrompt,const DeepCollectionEquality().hash(_this.garments),_this.climate,_this.modestyPreference,_this.budget,const DeepCollectionEquality().hash(_this.exclusions));
}

@override
String toString() {
  final _this = this as MakeoverIntent;
  return 'MakeoverIntent(occasion: ${_this.occasion}, desiredFeeling: ${_this.desiredFeeling}, hairPrompt: ${_this.hairPrompt}, garments: ${_this.garments}, climate: ${_this.climate}, modestyPreference: ${_this.modestyPreference}, budget: ${_this.budget}, exclusions: ${_this.exclusions})';
}


}

/// @nodoc
abstract mixin class $MakeoverIntentCopyWith<$Res>  {
  factory $MakeoverIntentCopyWith(MakeoverIntent value, $Res Function(MakeoverIntent) _then) = _$MakeoverIntentCopyWithImpl;
@useResult
$Res call({
 String occasion, String desiredFeeling, String hairPrompt, List<Map<String, dynamic>> garments, String climate, String modestyPreference, String budget, List<String> exclusions
});




}
/// @nodoc
class _$MakeoverIntentCopyWithImpl<$Res>
    implements $MakeoverIntentCopyWith<$Res> {
  _$MakeoverIntentCopyWithImpl(this._self, this._then);

  final MakeoverIntent _self;
  final $Res Function(MakeoverIntent) _then;

/// Create a copy of MakeoverIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? occasion = null,Object? desiredFeeling = null,Object? hairPrompt = null,Object? garments = null,Object? climate = null,Object? modestyPreference = null,Object? budget = null,Object? exclusions = null,}) {
  return _then(MakeoverIntent(
occasion: null == occasion ? _self.occasion : occasion // ignore: cast_nullable_to_non_nullable
as String,desiredFeeling: null == desiredFeeling ? _self.desiredFeeling : desiredFeeling // ignore: cast_nullable_to_non_nullable
as String,hairPrompt: null == hairPrompt ? _self.hairPrompt : hairPrompt // ignore: cast_nullable_to_non_nullable
as String,garments: null == garments ? _self.garments : garments // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,climate: null == climate ? _self.climate : climate // ignore: cast_nullable_to_non_nullable
as String,modestyPreference: null == modestyPreference ? _self.modestyPreference : modestyPreference // ignore: cast_nullable_to_non_nullable
as String,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as String,exclusions: null == exclusions ? _self.exclusions : exclusions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MakeoverIntent].
extension MakeoverIntentPatterns on MakeoverIntent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MakeoverIntent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MakeoverIntent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MakeoverIntent value)  $default,){
final _that = this;
switch (_that) {
case _MakeoverIntent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MakeoverIntent value)?  $default,){
final _that = this;
switch (_that) {
case _MakeoverIntent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String occasion,  String desiredFeeling,  String hairPrompt,  List<Map<String, dynamic>> garments,  String climate,  String modestyPreference,  String budget,  List<String> exclusions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MakeoverIntent() when $default != null:
return $default(_that.occasion,_that.desiredFeeling,_that.hairPrompt,_that.garments,_that.climate,_that.modestyPreference,_that.budget,_that.exclusions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String occasion,  String desiredFeeling,  String hairPrompt,  List<Map<String, dynamic>> garments,  String climate,  String modestyPreference,  String budget,  List<String> exclusions)  $default,) {final _that = this;
switch (_that) {
case _MakeoverIntent():
return $default(_that.occasion,_that.desiredFeeling,_that.hairPrompt,_that.garments,_that.climate,_that.modestyPreference,_that.budget,_that.exclusions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String occasion,  String desiredFeeling,  String hairPrompt,  List<Map<String, dynamic>> garments,  String climate,  String modestyPreference,  String budget,  List<String> exclusions)?  $default,) {final _that = this;
switch (_that) {
case _MakeoverIntent() when $default != null:
return $default(_that.occasion,_that.desiredFeeling,_that.hairPrompt,_that.garments,_that.climate,_that.modestyPreference,_that.budget,_that.exclusions);case _:
  return null;

}
}

}

/// @nodoc


class _MakeoverIntent extends MakeoverIntent {
  const _MakeoverIntent({this.occasion = '', this.desiredFeeling = '', this.hairPrompt = '',  List<Map<String, dynamic>> garments = const [], this.climate = '', this.modestyPreference = '', this.budget = '',  List<String> exclusions = const []}): _garments = garments,_exclusions = exclusions,super._();
  

@override@JsonKey() final  String occasion;
@override@JsonKey() final  String desiredFeeling;
/// Hair instruction. Empty means hair is left alone.
@override@JsonKey() final  String hairPrompt;
/// Catalogue products to try on. Empty means clothing is left alone.
 final  List<Map<String, dynamic>> _garments;
/// Catalogue products to try on. Empty means clothing is left alone.
@override@JsonKey() List<Map<String, dynamic>> get garments {
  if (_garments is EqualUnmodifiableListView) return _garments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_garments);
}

@override@JsonKey() final  String climate;
@override@JsonKey() final  String modestyPreference;
@override@JsonKey() final  String budget;
 final  List<String> _exclusions;
@override@JsonKey() List<String> get exclusions {
  if (_exclusions is EqualUnmodifiableListView) return _exclusions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exclusions);
}


/// Create a copy of MakeoverIntent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MakeoverIntentCopyWith<_MakeoverIntent> get copyWith => __$MakeoverIntentCopyWithImpl<_MakeoverIntent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MakeoverIntent&&(identical(other.occasion, occasion) || other.occasion == occasion)&&(identical(other.desiredFeeling, desiredFeeling) || other.desiredFeeling == desiredFeeling)&&(identical(other.hairPrompt, hairPrompt) || other.hairPrompt == hairPrompt)&&const DeepCollectionEquality().equals(other.garments, _garments)&&(identical(other.climate, climate) || other.climate == climate)&&(identical(other.modestyPreference, modestyPreference) || other.modestyPreference == modestyPreference)&&(identical(other.budget, budget) || other.budget == budget)&&const DeepCollectionEquality().equals(other.exclusions, _exclusions));
}


@override
int get hashCode {
    return Object.hash(runtimeType,occasion,desiredFeeling,hairPrompt,const DeepCollectionEquality().hash(_garments),climate,modestyPreference,budget,const DeepCollectionEquality().hash(_exclusions));
}

@override
String toString() {
    return 'MakeoverIntent(occasion: $occasion, desiredFeeling: $desiredFeeling, hairPrompt: $hairPrompt, garments: $garments, climate: $climate, modestyPreference: $modestyPreference, budget: $budget, exclusions: $exclusions)';
}


}

/// @nodoc
abstract mixin class _$MakeoverIntentCopyWith<$Res> implements $MakeoverIntentCopyWith<$Res> {
  factory _$MakeoverIntentCopyWith(_MakeoverIntent value, $Res Function(_MakeoverIntent) _then) = __$MakeoverIntentCopyWithImpl;
@override @useResult
$Res call({
 String occasion, String desiredFeeling, String hairPrompt, List<Map<String, dynamic>> garments, String climate, String modestyPreference, String budget, List<String> exclusions
});




}
/// @nodoc
class __$MakeoverIntentCopyWithImpl<$Res>
    implements _$MakeoverIntentCopyWith<$Res> {
  __$MakeoverIntentCopyWithImpl(this._self, this._then);

  final _MakeoverIntent _self;
  final $Res Function(_MakeoverIntent) _then;

/// Create a copy of MakeoverIntent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? occasion = null,Object? desiredFeeling = null,Object? hairPrompt = null,Object? garments = null,Object? climate = null,Object? modestyPreference = null,Object? budget = null,Object? exclusions = null,}) {
  return _then(_MakeoverIntent(
occasion: null == occasion ? _self.occasion : occasion // ignore: cast_nullable_to_non_nullable
as String,desiredFeeling: null == desiredFeeling ? _self.desiredFeeling : desiredFeeling // ignore: cast_nullable_to_non_nullable
as String,hairPrompt: null == hairPrompt ? _self.hairPrompt : hairPrompt // ignore: cast_nullable_to_non_nullable
as String,garments: null == garments ? _self._garments : garments // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,climate: null == climate ? _self.climate : climate // ignore: cast_nullable_to_non_nullable
as String,modestyPreference: null == modestyPreference ? _self.modestyPreference : modestyPreference // ignore: cast_nullable_to_non_nullable
as String,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as String,exclusions: null == exclusions ? _self._exclusions : exclusions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$MakeoverAlternative {

 int get index; String get imageUrl;/// Domains that contributed to this image, so the compare screen can say
/// what actually changed.
 List<MakeoverDomain> get appliedDomains;
/// Create a copy of MakeoverAlternative
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MakeoverAlternativeCopyWith<MakeoverAlternative> get copyWith => _$MakeoverAlternativeCopyWithImpl<MakeoverAlternative>(this as MakeoverAlternative, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MakeoverAlternative;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MakeoverAlternative&&(identical(other.index, _this.index) || other.index == _this.index)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&const DeepCollectionEquality().equals(other.appliedDomains, _this.appliedDomains));
}


@override
int get hashCode {
  final _this = this as MakeoverAlternative;
  return Object.hash(runtimeType,_this.index,_this.imageUrl,const DeepCollectionEquality().hash(_this.appliedDomains));
}

@override
String toString() {
  final _this = this as MakeoverAlternative;
  return 'MakeoverAlternative(index: ${_this.index}, imageUrl: ${_this.imageUrl}, appliedDomains: ${_this.appliedDomains})';
}


}

/// @nodoc
abstract mixin class $MakeoverAlternativeCopyWith<$Res>  {
  factory $MakeoverAlternativeCopyWith(MakeoverAlternative value, $Res Function(MakeoverAlternative) _then) = _$MakeoverAlternativeCopyWithImpl;
@useResult
$Res call({
 int index, String imageUrl, List<MakeoverDomain> appliedDomains
});




}
/// @nodoc
class _$MakeoverAlternativeCopyWithImpl<$Res>
    implements $MakeoverAlternativeCopyWith<$Res> {
  _$MakeoverAlternativeCopyWithImpl(this._self, this._then);

  final MakeoverAlternative _self;
  final $Res Function(MakeoverAlternative) _then;

/// Create a copy of MakeoverAlternative
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? imageUrl = null,Object? appliedDomains = null,}) {
  return _then(MakeoverAlternative(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,appliedDomains: null == appliedDomains ? _self.appliedDomains : appliedDomains // ignore: cast_nullable_to_non_nullable
as List<MakeoverDomain>,
  ));
}

}


/// Adds pattern-matching-related methods to [MakeoverAlternative].
extension MakeoverAlternativePatterns on MakeoverAlternative {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MakeoverAlternative value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MakeoverAlternative() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MakeoverAlternative value)  $default,){
final _that = this;
switch (_that) {
case _MakeoverAlternative():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MakeoverAlternative value)?  $default,){
final _that = this;
switch (_that) {
case _MakeoverAlternative() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String imageUrl,  List<MakeoverDomain> appliedDomains)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MakeoverAlternative() when $default != null:
return $default(_that.index,_that.imageUrl,_that.appliedDomains);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String imageUrl,  List<MakeoverDomain> appliedDomains)  $default,) {final _that = this;
switch (_that) {
case _MakeoverAlternative():
return $default(_that.index,_that.imageUrl,_that.appliedDomains);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String imageUrl,  List<MakeoverDomain> appliedDomains)?  $default,) {final _that = this;
switch (_that) {
case _MakeoverAlternative() when $default != null:
return $default(_that.index,_that.imageUrl,_that.appliedDomains);case _:
  return null;

}
}

}

/// @nodoc


class _MakeoverAlternative extends MakeoverAlternative {
  const _MakeoverAlternative({required this.index, required this.imageUrl,  List<MakeoverDomain> appliedDomains = const []}): _appliedDomains = appliedDomains,super._();
  

@override final  int index;
@override final  String imageUrl;
/// Domains that contributed to this image, so the compare screen can say
/// what actually changed.
 final  List<MakeoverDomain> _appliedDomains;
/// Domains that contributed to this image, so the compare screen can say
/// what actually changed.
@override@JsonKey() List<MakeoverDomain> get appliedDomains {
  if (_appliedDomains is EqualUnmodifiableListView) return _appliedDomains;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_appliedDomains);
}


/// Create a copy of MakeoverAlternative
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MakeoverAlternativeCopyWith<_MakeoverAlternative> get copyWith => __$MakeoverAlternativeCopyWithImpl<_MakeoverAlternative>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MakeoverAlternative&&(identical(other.index, index) || other.index == index)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other.appliedDomains, _appliedDomains));
}


@override
int get hashCode {
    return Object.hash(runtimeType,index,imageUrl,const DeepCollectionEquality().hash(_appliedDomains));
}

@override
String toString() {
    return 'MakeoverAlternative(index: $index, imageUrl: $imageUrl, appliedDomains: $appliedDomains)';
}


}

/// @nodoc
abstract mixin class _$MakeoverAlternativeCopyWith<$Res> implements $MakeoverAlternativeCopyWith<$Res> {
  factory _$MakeoverAlternativeCopyWith(_MakeoverAlternative value, $Res Function(_MakeoverAlternative) _then) = __$MakeoverAlternativeCopyWithImpl;
@override @useResult
$Res call({
 int index, String imageUrl, List<MakeoverDomain> appliedDomains
});




}
/// @nodoc
class __$MakeoverAlternativeCopyWithImpl<$Res>
    implements _$MakeoverAlternativeCopyWith<$Res> {
  __$MakeoverAlternativeCopyWithImpl(this._self, this._then);

  final _MakeoverAlternative _self;
  final $Res Function(_MakeoverAlternative) _then;

/// Create a copy of MakeoverAlternative
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? imageUrl = null,Object? appliedDomains = null,}) {
  return _then(_MakeoverAlternative(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,appliedDomains: null == appliedDomains ? _self._appliedDomains : appliedDomains // ignore: cast_nullable_to_non_nullable
as List<MakeoverDomain>,
  ));
}


}

/// @nodoc
mixin _$MakeoverJob {

 String get id; String get userId;/// The user's own photo. Preserved unmodified for the before/after view.
 String get sourceImageUrl; MakeoverIntent get intent; Map<MakeoverDomain, MakeoverStage> get stages; List<MakeoverAlternative> get alternatives; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of MakeoverJob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MakeoverJobCopyWith<MakeoverJob> get copyWith => _$MakeoverJobCopyWithImpl<MakeoverJob>(this as MakeoverJob, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MakeoverJob;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MakeoverJob&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.sourceImageUrl, _this.sourceImageUrl) || other.sourceImageUrl == _this.sourceImageUrl)&&(identical(other.intent, _this.intent) || other.intent == _this.intent)&&const DeepCollectionEquality().equals(other.stages, _this.stages)&&const DeepCollectionEquality().equals(other.alternatives, _this.alternatives)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as MakeoverJob;
  return Object.hash(runtimeType,_this.id,_this.userId,_this.sourceImageUrl,_this.intent,const DeepCollectionEquality().hash(_this.stages),const DeepCollectionEquality().hash(_this.alternatives),_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as MakeoverJob;
  return 'MakeoverJob(id: ${_this.id}, userId: ${_this.userId}, sourceImageUrl: ${_this.sourceImageUrl}, intent: ${_this.intent}, stages: ${_this.stages}, alternatives: ${_this.alternatives}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $MakeoverJobCopyWith<$Res>  {
  factory $MakeoverJobCopyWith(MakeoverJob value, $Res Function(MakeoverJob) _then) = _$MakeoverJobCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String sourceImageUrl, MakeoverIntent intent, Map<MakeoverDomain, MakeoverStage> stages, List<MakeoverAlternative> alternatives, DateTime? createdAt, DateTime? updatedAt
});


$MakeoverIntentCopyWith<$Res> get intent;

}
/// @nodoc
class _$MakeoverJobCopyWithImpl<$Res>
    implements $MakeoverJobCopyWith<$Res> {
  _$MakeoverJobCopyWithImpl(this._self, this._then);

  final MakeoverJob _self;
  final $Res Function(MakeoverJob) _then;

/// Create a copy of MakeoverJob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? sourceImageUrl = null,Object? intent = null,Object? stages = null,Object? alternatives = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(MakeoverJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,sourceImageUrl: null == sourceImageUrl ? _self.sourceImageUrl : sourceImageUrl // ignore: cast_nullable_to_non_nullable
as String,intent: null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as MakeoverIntent,stages: null == stages ? _self.stages : stages // ignore: cast_nullable_to_non_nullable
as Map<MakeoverDomain, MakeoverStage>,alternatives: null == alternatives ? _self.alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<MakeoverAlternative>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of MakeoverJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MakeoverIntentCopyWith<$Res> get intent {
  
  return $MakeoverIntentCopyWith<$Res>(_self.intent, (value) {
    return _then(_self.copyWith(intent: value));
  });
}
}


/// Adds pattern-matching-related methods to [MakeoverJob].
extension MakeoverJobPatterns on MakeoverJob {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MakeoverJob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MakeoverJob() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MakeoverJob value)  $default,){
final _that = this;
switch (_that) {
case _MakeoverJob():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MakeoverJob value)?  $default,){
final _that = this;
switch (_that) {
case _MakeoverJob() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String sourceImageUrl,  MakeoverIntent intent,  Map<MakeoverDomain, MakeoverStage> stages,  List<MakeoverAlternative> alternatives,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MakeoverJob() when $default != null:
return $default(_that.id,_that.userId,_that.sourceImageUrl,_that.intent,_that.stages,_that.alternatives,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String sourceImageUrl,  MakeoverIntent intent,  Map<MakeoverDomain, MakeoverStage> stages,  List<MakeoverAlternative> alternatives,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MakeoverJob():
return $default(_that.id,_that.userId,_that.sourceImageUrl,_that.intent,_that.stages,_that.alternatives,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String sourceImageUrl,  MakeoverIntent intent,  Map<MakeoverDomain, MakeoverStage> stages,  List<MakeoverAlternative> alternatives,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MakeoverJob() when $default != null:
return $default(_that.id,_that.userId,_that.sourceImageUrl,_that.intent,_that.stages,_that.alternatives,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _MakeoverJob extends MakeoverJob {
  const _MakeoverJob({required this.id, required this.userId, required this.sourceImageUrl, required this.intent, required  Map<MakeoverDomain, MakeoverStage> stages,  List<MakeoverAlternative> alternatives = const [], this.createdAt, this.updatedAt}): _stages = stages,_alternatives = alternatives,super._();
  

@override final  String id;
@override final  String userId;
/// The user's own photo. Preserved unmodified for the before/after view.
@override final  String sourceImageUrl;
@override final  MakeoverIntent intent;
 final  Map<MakeoverDomain, MakeoverStage> _stages;
@override Map<MakeoverDomain, MakeoverStage> get stages {
  if (_stages is EqualUnmodifiableMapView) return _stages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_stages);
}

 final  List<MakeoverAlternative> _alternatives;
@override@JsonKey() List<MakeoverAlternative> get alternatives {
  if (_alternatives is EqualUnmodifiableListView) return _alternatives;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alternatives);
}

@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of MakeoverJob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MakeoverJobCopyWith<_MakeoverJob> get copyWith => __$MakeoverJobCopyWithImpl<_MakeoverJob>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MakeoverJob&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sourceImageUrl, sourceImageUrl) || other.sourceImageUrl == sourceImageUrl)&&(identical(other.intent, intent) || other.intent == intent)&&const DeepCollectionEquality().equals(other.stages, _stages)&&const DeepCollectionEquality().equals(other.alternatives, _alternatives)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,userId,sourceImageUrl,intent,const DeepCollectionEquality().hash(_stages),const DeepCollectionEquality().hash(_alternatives),createdAt,updatedAt);
}

@override
String toString() {
    return 'MakeoverJob(id: $id, userId: $userId, sourceImageUrl: $sourceImageUrl, intent: $intent, stages: $stages, alternatives: $alternatives, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MakeoverJobCopyWith<$Res> implements $MakeoverJobCopyWith<$Res> {
  factory _$MakeoverJobCopyWith(_MakeoverJob value, $Res Function(_MakeoverJob) _then) = __$MakeoverJobCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String sourceImageUrl, MakeoverIntent intent, Map<MakeoverDomain, MakeoverStage> stages, List<MakeoverAlternative> alternatives, DateTime? createdAt, DateTime? updatedAt
});


@override $MakeoverIntentCopyWith<$Res> get intent;

}
/// @nodoc
class __$MakeoverJobCopyWithImpl<$Res>
    implements _$MakeoverJobCopyWith<$Res> {
  __$MakeoverJobCopyWithImpl(this._self, this._then);

  final _MakeoverJob _self;
  final $Res Function(_MakeoverJob) _then;

/// Create a copy of MakeoverJob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? sourceImageUrl = null,Object? intent = null,Object? stages = null,Object? alternatives = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_MakeoverJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,sourceImageUrl: null == sourceImageUrl ? _self.sourceImageUrl : sourceImageUrl // ignore: cast_nullable_to_non_nullable
as String,intent: null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as MakeoverIntent,stages: null == stages ? _self._stages : stages // ignore: cast_nullable_to_non_nullable
as Map<MakeoverDomain, MakeoverStage>,alternatives: null == alternatives ? _self._alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<MakeoverAlternative>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of MakeoverJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MakeoverIntentCopyWith<$Res> get intent {
  
  return $MakeoverIntentCopyWith<$Res>(_self.intent, (value) {
    return _then(_self.copyWith(intent: value));
  });
}
}

// dart format on
