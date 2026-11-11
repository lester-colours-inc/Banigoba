// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'upcoming_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EventDraft {

 String get name; DateTimeRange<DateTime> get range;
/// Create a copy of EventDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventDraftCopyWith<EventDraft> get copyWith => _$EventDraftCopyWithImpl<EventDraft>(this as EventDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EventDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventDraft&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.range, _this.range) || other.range == _this.range));
}


@override
int get hashCode {
  final _this = this as EventDraft;
  return Object.hash(runtimeType,_this.name,_this.range);
}

@override
String toString() {
  final _this = this as EventDraft;
  return 'EventDraft(name: ${_this.name}, range: ${_this.range})';
}


}

/// @nodoc
abstract mixin class $EventDraftCopyWith<$Res>  {
  factory $EventDraftCopyWith(EventDraft value, $Res Function(EventDraft) _then) = _$EventDraftCopyWithImpl;
@useResult
$Res call({
 String name, DateTimeRange<DateTime> range
});




}
/// @nodoc
class _$EventDraftCopyWithImpl<$Res>
    implements $EventDraftCopyWith<$Res> {
  _$EventDraftCopyWithImpl(this._self, this._then);

  final EventDraft _self;
  final $Res Function(EventDraft) _then;

/// Create a copy of EventDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? range = null,}) {
  return _then(EventDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as DateTimeRange<DateTime>,
  ));
}

}


/// Adds pattern-matching-related methods to [EventDraft].
extension EventDraftPatterns on EventDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventDraft value)  $default,){
final _that = this;
switch (_that) {
case _EventDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventDraft value)?  $default,){
final _that = this;
switch (_that) {
case _EventDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  DateTimeRange<DateTime> range)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventDraft() when $default != null:
return $default(_that.name,_that.range);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  DateTimeRange<DateTime> range)  $default,) {final _that = this;
switch (_that) {
case _EventDraft():
return $default(_that.name,_that.range);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  DateTimeRange<DateTime> range)?  $default,) {final _that = this;
switch (_that) {
case _EventDraft() when $default != null:
return $default(_that.name,_that.range);case _:
  return null;

}
}

}

/// @nodoc


class _EventDraft extends EventDraft {
  const _EventDraft({required this.name, required this.range}): super._();
  

@override final  String name;
@override final  DateTimeRange<DateTime> range;

/// Create a copy of EventDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventDraftCopyWith<_EventDraft> get copyWith => __$EventDraftCopyWithImpl<_EventDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.range, range) || other.range == range));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,range);
}

@override
String toString() {
    return 'EventDraft(name: $name, range: $range)';
}


}

/// @nodoc
abstract mixin class _$EventDraftCopyWith<$Res> implements $EventDraftCopyWith<$Res> {
  factory _$EventDraftCopyWith(_EventDraft value, $Res Function(_EventDraft) _then) = __$EventDraftCopyWithImpl;
@override @useResult
$Res call({
 String name, DateTimeRange<DateTime> range
});




}
/// @nodoc
class __$EventDraftCopyWithImpl<$Res>
    implements _$EventDraftCopyWith<$Res> {
  __$EventDraftCopyWithImpl(this._self, this._then);

  final _EventDraft _self;
  final $Res Function(_EventDraft) _then;

/// Create a copy of EventDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? range = null,}) {
  return _then(_EventDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as DateTimeRange<DateTime>,
  ));
}


}

/// @nodoc
mixin _$UpcomingPlan {

 String get id; String get name; String get subtitle; bool get isEvent; DateTime get createdAt; DateTime? get startDate; DateTime? get endDate; List<Map<String, dynamic>> get packingItems;
/// Create a copy of UpcomingPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpcomingPlanCopyWith<UpcomingPlan> get copyWith => _$UpcomingPlanCopyWithImpl<UpcomingPlan>(this as UpcomingPlan, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UpcomingPlan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpcomingPlan&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.subtitle, _this.subtitle) || other.subtitle == _this.subtitle)&&(identical(other.isEvent, _this.isEvent) || other.isEvent == _this.isEvent)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&const DeepCollectionEquality().equals(other.packingItems, _this.packingItems));
}


@override
int get hashCode {
  final _this = this as UpcomingPlan;
  return Object.hash(runtimeType,_this.id,_this.name,_this.subtitle,_this.isEvent,_this.createdAt,_this.startDate,_this.endDate,const DeepCollectionEquality().hash(_this.packingItems));
}

@override
String toString() {
  final _this = this as UpcomingPlan;
  return 'UpcomingPlan(id: ${_this.id}, name: ${_this.name}, subtitle: ${_this.subtitle}, isEvent: ${_this.isEvent}, createdAt: ${_this.createdAt}, startDate: ${_this.startDate}, endDate: ${_this.endDate}, packingItems: ${_this.packingItems})';
}


}

/// @nodoc
abstract mixin class $UpcomingPlanCopyWith<$Res>  {
  factory $UpcomingPlanCopyWith(UpcomingPlan value, $Res Function(UpcomingPlan) _then) = _$UpcomingPlanCopyWithImpl;
@useResult
$Res call({
 String id, String name, String subtitle, bool isEvent, DateTime createdAt, DateTime? startDate, DateTime? endDate, List<Map<String, dynamic>> packingItems
});




}
/// @nodoc
class _$UpcomingPlanCopyWithImpl<$Res>
    implements $UpcomingPlanCopyWith<$Res> {
  _$UpcomingPlanCopyWithImpl(this._self, this._then);

  final UpcomingPlan _self;
  final $Res Function(UpcomingPlan) _then;

/// Create a copy of UpcomingPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? subtitle = null,Object? isEvent = null,Object? createdAt = null,Object? startDate = freezed,Object? endDate = freezed,Object? packingItems = null,}) {
  return _then(UpcomingPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,isEvent: null == isEvent ? _self.isEvent : isEvent // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,packingItems: null == packingItems ? _self.packingItems : packingItems // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}

}


/// Adds pattern-matching-related methods to [UpcomingPlan].
extension UpcomingPlanPatterns on UpcomingPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpcomingPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpcomingPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpcomingPlan value)  $default,){
final _that = this;
switch (_that) {
case _UpcomingPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpcomingPlan value)?  $default,){
final _that = this;
switch (_that) {
case _UpcomingPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String subtitle,  bool isEvent,  DateTime createdAt,  DateTime? startDate,  DateTime? endDate,  List<Map<String, dynamic>> packingItems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpcomingPlan() when $default != null:
return $default(_that.id,_that.name,_that.subtitle,_that.isEvent,_that.createdAt,_that.startDate,_that.endDate,_that.packingItems);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String subtitle,  bool isEvent,  DateTime createdAt,  DateTime? startDate,  DateTime? endDate,  List<Map<String, dynamic>> packingItems)  $default,) {final _that = this;
switch (_that) {
case _UpcomingPlan():
return $default(_that.id,_that.name,_that.subtitle,_that.isEvent,_that.createdAt,_that.startDate,_that.endDate,_that.packingItems);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String subtitle,  bool isEvent,  DateTime createdAt,  DateTime? startDate,  DateTime? endDate,  List<Map<String, dynamic>> packingItems)?  $default,) {final _that = this;
switch (_that) {
case _UpcomingPlan() when $default != null:
return $default(_that.id,_that.name,_that.subtitle,_that.isEvent,_that.createdAt,_that.startDate,_that.endDate,_that.packingItems);case _:
  return null;

}
}

}

/// @nodoc


class _UpcomingPlan extends UpcomingPlan {
  const _UpcomingPlan({required this.id, required this.name, required this.subtitle, required this.isEvent, required this.createdAt, this.startDate, this.endDate,  List<Map<String, dynamic>> packingItems = const []}): _packingItems = packingItems,super._();
  

@override final  String id;
@override final  String name;
@override final  String subtitle;
@override final  bool isEvent;
@override final  DateTime createdAt;
@override final  DateTime? startDate;
@override final  DateTime? endDate;
 final  List<Map<String, dynamic>> _packingItems;
@override@JsonKey() List<Map<String, dynamic>> get packingItems {
  if (_packingItems is EqualUnmodifiableListView) return _packingItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_packingItems);
}


/// Create a copy of UpcomingPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpcomingPlanCopyWith<_UpcomingPlan> get copyWith => __$UpcomingPlanCopyWithImpl<_UpcomingPlan>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpcomingPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.isEvent, isEvent) || other.isEvent == isEvent)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other.packingItems, _packingItems));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,subtitle,isEvent,createdAt,startDate,endDate,const DeepCollectionEquality().hash(_packingItems));
}

@override
String toString() {
    return 'UpcomingPlan(id: $id, name: $name, subtitle: $subtitle, isEvent: $isEvent, createdAt: $createdAt, startDate: $startDate, endDate: $endDate, packingItems: $packingItems)';
}


}

/// @nodoc
abstract mixin class _$UpcomingPlanCopyWith<$Res> implements $UpcomingPlanCopyWith<$Res> {
  factory _$UpcomingPlanCopyWith(_UpcomingPlan value, $Res Function(_UpcomingPlan) _then) = __$UpcomingPlanCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String subtitle, bool isEvent, DateTime createdAt, DateTime? startDate, DateTime? endDate, List<Map<String, dynamic>> packingItems
});




}
/// @nodoc
class __$UpcomingPlanCopyWithImpl<$Res>
    implements _$UpcomingPlanCopyWith<$Res> {
  __$UpcomingPlanCopyWithImpl(this._self, this._then);

  final _UpcomingPlan _self;
  final $Res Function(_UpcomingPlan) _then;

/// Create a copy of UpcomingPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? subtitle = null,Object? isEvent = null,Object? createdAt = null,Object? startDate = freezed,Object? endDate = freezed,Object? packingItems = null,}) {
  return _then(_UpcomingPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,isEvent: null == isEvent ? _self.isEvent : isEvent // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,packingItems: null == packingItems ? _self._packingItems : packingItems // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

// dart format on
