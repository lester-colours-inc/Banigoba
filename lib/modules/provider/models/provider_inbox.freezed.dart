// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'provider_inbox.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InboxItem implements DiagnosticableTreeMixin {

 InboxKind get kind; String get id; String get customerId; String get customerName; String get title; String get detail; String get status; DateTime? get createdAt;/// The stored document, for the detail view.
 Map<String, dynamic> get data;
/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboxItemCopyWith<InboxItem> get copyWith => _$InboxItemCopyWithImpl<InboxItem>(this as InboxItem, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as InboxItem;
  properties
    ..add(DiagnosticsProperty('type', 'InboxItem'))
    ..add(DiagnosticsProperty('kind', _this.kind))..add(DiagnosticsProperty('id', _this.id))..add(DiagnosticsProperty('customerId', _this.customerId))..add(DiagnosticsProperty('customerName', _this.customerName))..add(DiagnosticsProperty('title', _this.title))..add(DiagnosticsProperty('detail', _this.detail))..add(DiagnosticsProperty('status', _this.status))..add(DiagnosticsProperty('createdAt', _this.createdAt))..add(DiagnosticsProperty('data', _this.data));
}

@override
bool operator ==(Object other) {
  final _this = this as InboxItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxItem&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.customerId, _this.customerId) || other.customerId == _this.customerId)&&(identical(other.customerName, _this.customerName) || other.customerName == _this.customerName)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.detail, _this.detail) || other.detail == _this.detail)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&const DeepCollectionEquality().equals(other.data, _this.data));
}


@override
int get hashCode {
  final _this = this as InboxItem;
  return Object.hash(runtimeType,_this.kind,_this.id,_this.customerId,_this.customerName,_this.title,_this.detail,_this.status,_this.createdAt,const DeepCollectionEquality().hash(_this.data));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as InboxItem;
  return 'InboxItem(kind: ${_this.kind}, id: ${_this.id}, customerId: ${_this.customerId}, customerName: ${_this.customerName}, title: ${_this.title}, detail: ${_this.detail}, status: ${_this.status}, createdAt: ${_this.createdAt}, data: ${_this.data})';
}


}

/// @nodoc
abstract mixin class $InboxItemCopyWith<$Res>  {
  factory $InboxItemCopyWith(InboxItem value, $Res Function(InboxItem) _then) = _$InboxItemCopyWithImpl;
@useResult
$Res call({
 InboxKind kind, String id, String customerId, String customerName, String title, String detail, String status, DateTime? createdAt, Map<String, dynamic> data
});




}
/// @nodoc
class _$InboxItemCopyWithImpl<$Res>
    implements $InboxItemCopyWith<$Res> {
  _$InboxItemCopyWithImpl(this._self, this._then);

  final InboxItem _self;
  final $Res Function(InboxItem) _then;

/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? id = null,Object? customerId = null,Object? customerName = null,Object? title = null,Object? detail = null,Object? status = null,Object? createdAt = freezed,Object? data = null,}) {
  return _then(InboxItem(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as InboxKind,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [InboxItem].
extension InboxItemPatterns on InboxItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InboxItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InboxItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InboxItem value)  $default,){
final _that = this;
switch (_that) {
case _InboxItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InboxItem value)?  $default,){
final _that = this;
switch (_that) {
case _InboxItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InboxKind kind,  String id,  String customerId,  String customerName,  String title,  String detail,  String status,  DateTime? createdAt,  Map<String, dynamic> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InboxItem() when $default != null:
return $default(_that.kind,_that.id,_that.customerId,_that.customerName,_that.title,_that.detail,_that.status,_that.createdAt,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InboxKind kind,  String id,  String customerId,  String customerName,  String title,  String detail,  String status,  DateTime? createdAt,  Map<String, dynamic> data)  $default,) {final _that = this;
switch (_that) {
case _InboxItem():
return $default(_that.kind,_that.id,_that.customerId,_that.customerName,_that.title,_that.detail,_that.status,_that.createdAt,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InboxKind kind,  String id,  String customerId,  String customerName,  String title,  String detail,  String status,  DateTime? createdAt,  Map<String, dynamic> data)?  $default,) {final _that = this;
switch (_that) {
case _InboxItem() when $default != null:
return $default(_that.kind,_that.id,_that.customerId,_that.customerName,_that.title,_that.detail,_that.status,_that.createdAt,_that.data);case _:
  return null;

}
}

}

/// @nodoc


class _InboxItem extends InboxItem with DiagnosticableTreeMixin {
  const _InboxItem({required this.kind, required this.id, required this.customerId, required this.customerName, required this.title, required this.detail, required this.status, required this.createdAt,  Map<String, dynamic> data = const {}}): _data = data,super._();
  

@override final  InboxKind kind;
@override final  String id;
@override final  String customerId;
@override final  String customerName;
@override final  String title;
@override final  String detail;
@override final  String status;
@override final  DateTime? createdAt;
/// The stored document, for the detail view.
 final  Map<String, dynamic> _data;
/// The stored document, for the detail view.
@override@JsonKey() Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}


/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InboxItemCopyWith<_InboxItem> get copyWith => __$InboxItemCopyWithImpl<_InboxItem>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'InboxItem'))
    ..add(DiagnosticsProperty('kind', kind))..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('customerId', customerId))..add(DiagnosticsProperty('customerName', customerName))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('detail', detail))..add(DiagnosticsProperty('status', status))..add(DiagnosticsProperty('createdAt', createdAt))..add(DiagnosticsProperty('data', data));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InboxItem&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.id, id) || other.id == id)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.title, title) || other.title == title)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.data, _data));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,id,customerId,customerName,title,detail,status,createdAt,const DeepCollectionEquality().hash(_data));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'InboxItem(kind: $kind, id: $id, customerId: $customerId, customerName: $customerName, title: $title, detail: $detail, status: $status, createdAt: $createdAt, data: $data)';
}


}

/// @nodoc
abstract mixin class _$InboxItemCopyWith<$Res> implements $InboxItemCopyWith<$Res> {
  factory _$InboxItemCopyWith(_InboxItem value, $Res Function(_InboxItem) _then) = __$InboxItemCopyWithImpl;
@override @useResult
$Res call({
 InboxKind kind, String id, String customerId, String customerName, String title, String detail, String status, DateTime? createdAt, Map<String, dynamic> data
});




}
/// @nodoc
class __$InboxItemCopyWithImpl<$Res>
    implements _$InboxItemCopyWith<$Res> {
  __$InboxItemCopyWithImpl(this._self, this._then);

  final _InboxItem _self;
  final $Res Function(_InboxItem) _then;

/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? id = null,Object? customerId = null,Object? customerName = null,Object? title = null,Object? detail = null,Object? status = null,Object? createdAt = freezed,Object? data = null,}) {
  return _then(_InboxItem(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as InboxKind,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
