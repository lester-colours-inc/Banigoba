// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'body_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BodyProfile implements DiagnosticableTreeMixin {

 String get facePhotoUrl; String get fullBodyPhotoUrl; String get handPhotoUrl; String get clothingSize;/// UK size, e.g. "8" or "8.5".
 String get shoeSize; Map<BodyMeasurement, double> get measurements;/// "Any other" details, in the user's own words.
 String get notes;


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as BodyProfile;
  properties
    ..add(DiagnosticsProperty('type', 'BodyProfile'))
    ..add(DiagnosticsProperty('facePhotoUrl', _this.facePhotoUrl))..add(DiagnosticsProperty('fullBodyPhotoUrl', _this.fullBodyPhotoUrl))..add(DiagnosticsProperty('handPhotoUrl', _this.handPhotoUrl))..add(DiagnosticsProperty('clothingSize', _this.clothingSize))..add(DiagnosticsProperty('shoeSize', _this.shoeSize))..add(DiagnosticsProperty('measurements', _this.measurements))..add(DiagnosticsProperty('notes', _this.notes));
}

@override
bool operator ==(Object other) {
  final _this = this as BodyProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BodyProfile&&(identical(other.facePhotoUrl, _this.facePhotoUrl) || other.facePhotoUrl == _this.facePhotoUrl)&&(identical(other.fullBodyPhotoUrl, _this.fullBodyPhotoUrl) || other.fullBodyPhotoUrl == _this.fullBodyPhotoUrl)&&(identical(other.handPhotoUrl, _this.handPhotoUrl) || other.handPhotoUrl == _this.handPhotoUrl)&&(identical(other.clothingSize, _this.clothingSize) || other.clothingSize == _this.clothingSize)&&(identical(other.shoeSize, _this.shoeSize) || other.shoeSize == _this.shoeSize)&&const DeepCollectionEquality().equals(other.measurements, _this.measurements)&&(identical(other.notes, _this.notes) || other.notes == _this.notes));
}


@override
int get hashCode {
  final _this = this as BodyProfile;
  return Object.hash(runtimeType,_this.facePhotoUrl,_this.fullBodyPhotoUrl,_this.handPhotoUrl,_this.clothingSize,_this.shoeSize,const DeepCollectionEquality().hash(_this.measurements),_this.notes);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as BodyProfile;
  return 'BodyProfile(facePhotoUrl: ${_this.facePhotoUrl}, fullBodyPhotoUrl: ${_this.fullBodyPhotoUrl}, handPhotoUrl: ${_this.handPhotoUrl}, clothingSize: ${_this.clothingSize}, shoeSize: ${_this.shoeSize}, measurements: ${_this.measurements}, notes: ${_this.notes})';
}


}




/// Adds pattern-matching-related methods to [BodyProfile].
extension BodyProfilePatterns on BodyProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BodyProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BodyProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BodyProfile value)  $default,){
final _that = this;
switch (_that) {
case _BodyProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BodyProfile value)?  $default,){
final _that = this;
switch (_that) {
case _BodyProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String facePhotoUrl,  String fullBodyPhotoUrl,  String handPhotoUrl,  String clothingSize,  String shoeSize,  Map<BodyMeasurement, double> measurements,  String notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BodyProfile() when $default != null:
return $default(_that.facePhotoUrl,_that.fullBodyPhotoUrl,_that.handPhotoUrl,_that.clothingSize,_that.shoeSize,_that.measurements,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String facePhotoUrl,  String fullBodyPhotoUrl,  String handPhotoUrl,  String clothingSize,  String shoeSize,  Map<BodyMeasurement, double> measurements,  String notes)  $default,) {final _that = this;
switch (_that) {
case _BodyProfile():
return $default(_that.facePhotoUrl,_that.fullBodyPhotoUrl,_that.handPhotoUrl,_that.clothingSize,_that.shoeSize,_that.measurements,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String facePhotoUrl,  String fullBodyPhotoUrl,  String handPhotoUrl,  String clothingSize,  String shoeSize,  Map<BodyMeasurement, double> measurements,  String notes)?  $default,) {final _that = this;
switch (_that) {
case _BodyProfile() when $default != null:
return $default(_that.facePhotoUrl,_that.fullBodyPhotoUrl,_that.handPhotoUrl,_that.clothingSize,_that.shoeSize,_that.measurements,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _BodyProfile extends BodyProfile with DiagnosticableTreeMixin {
  const _BodyProfile({this.facePhotoUrl = '', this.fullBodyPhotoUrl = '', this.handPhotoUrl = '', this.clothingSize = '', this.shoeSize = '',  Map<BodyMeasurement, double> measurements = const {}, this.notes = ''}): _measurements = measurements,super._();
  

@override@JsonKey() final  String facePhotoUrl;
@override@JsonKey() final  String fullBodyPhotoUrl;
@override@JsonKey() final  String handPhotoUrl;
@override@JsonKey() final  String clothingSize;
/// UK size, e.g. "8" or "8.5".
@override@JsonKey() final  String shoeSize;
 final  Map<BodyMeasurement, double> _measurements;
@override@JsonKey() Map<BodyMeasurement, double> get measurements {
  if (_measurements is EqualUnmodifiableMapView) return _measurements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_measurements);
}

/// "Any other" details, in the user's own words.
@override@JsonKey() final  String notes;



@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'BodyProfile'))
    ..add(DiagnosticsProperty('facePhotoUrl', facePhotoUrl))..add(DiagnosticsProperty('fullBodyPhotoUrl', fullBodyPhotoUrl))..add(DiagnosticsProperty('handPhotoUrl', handPhotoUrl))..add(DiagnosticsProperty('clothingSize', clothingSize))..add(DiagnosticsProperty('shoeSize', shoeSize))..add(DiagnosticsProperty('measurements', measurements))..add(DiagnosticsProperty('notes', notes));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BodyProfile&&(identical(other.facePhotoUrl, facePhotoUrl) || other.facePhotoUrl == facePhotoUrl)&&(identical(other.fullBodyPhotoUrl, fullBodyPhotoUrl) || other.fullBodyPhotoUrl == fullBodyPhotoUrl)&&(identical(other.handPhotoUrl, handPhotoUrl) || other.handPhotoUrl == handPhotoUrl)&&(identical(other.clothingSize, clothingSize) || other.clothingSize == clothingSize)&&(identical(other.shoeSize, shoeSize) || other.shoeSize == shoeSize)&&const DeepCollectionEquality().equals(other.measurements, _measurements)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,facePhotoUrl,fullBodyPhotoUrl,handPhotoUrl,clothingSize,shoeSize,const DeepCollectionEquality().hash(_measurements),notes);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'BodyProfile(facePhotoUrl: $facePhotoUrl, fullBodyPhotoUrl: $fullBodyPhotoUrl, handPhotoUrl: $handPhotoUrl, clothingSize: $clothingSize, shoeSize: $shoeSize, measurements: $measurements, notes: $notes)';
}


}




// dart format on
