// "Near me" from the phone's location (review items P-5, A-4).
//
// Only a coarse cell about 22 km wide is ever saved (see geo_cell.dart), on
// the person's profile as `area_cell`; coordinates are read, turned into a
// cell and dropped. It is off until the person turns it on, refreshes at most
// once a day, and a refresh never shows a permission prompt: if permission
// has been taken away the old cell just stays until they turn it off.
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/geo_cell.dart';
import '../supabase/rows.dart';
import 'profile_service.dart';

/// What the person is told before "Near me" uses their location.
const List<String> kLocationConsentText = [
  'Near me uses your phone\'s location to show looks from people close to '
      'you.',
  'We save only a rough area about 22 km wide, never your exact position and '
      'never a map pin. Other people can only tell that you are nearby.',
  'Your location is read when you open Banigoba, at most once a day.',
  'You can turn this off any time in Settings, and your area is deleted.',
];

/// How often the saved cell is refreshed.
const Duration kAreaRefreshAfter = Duration(hours: 24);

enum PositionStatus { granted, denied, deniedForever, serviceOff }

enum AreaResult { enabled, denied, deniedForever, serviceOff, failed }

/// Where the phone's position comes from; a fake in tests.
abstract interface class PositionSource {
  /// Permission to read the location. With [ask] true the phone may show its
  /// prompt; with false it only reports the current state.
  Future<PositionStatus> permission({required bool ask});

  /// A rough current position, or null when there is none.
  Future<({double latitude, double longitude})?> current();
}

class GeolocatorPositionSource implements PositionSource {
  const GeolocatorPositionSource();

  @override
  Future<PositionStatus> permission({required bool ask}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return PositionStatus.serviceOff;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && ask) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => PositionStatus.granted,
      LocationPermission.deniedForever => PositionStatus.deniedForever,
      _ => PositionStatus.denied,
    };
  }

  @override
  Future<({double latitude, double longitude})?> current() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return (latitude: position.latitude, longitude: position.longitude);
  }
}

/// What is saved about a person's area.
@immutable
class AreaRecord {
  const AreaRecord({required this.enabled, this.cell, this.updatedAt});

  final bool enabled;
  final GeoCell? cell;
  final DateTime? updatedAt;
}

abstract interface class AreaStore {
  Future<AreaRecord?> read(String userId);
  Future<void> write(String userId, GeoCell cell, DateTime at);
  Future<void> clear(String userId);
}

class ProfileAreaStore implements AreaStore {
  ProfileAreaStore({ProfileService? profiles})
    : _profiles = profiles ?? ProfileService();

  final ProfileService _profiles;

  @override
  Future<AreaRecord?> read(String userId) async {
    final data = await _profiles.get(userId);
    if (data.isEmpty) return null;
    return AreaRecord(
      enabled: data['areaEnabled'] == true,
      cell: GeoCell.tryParse(data['areaCell']?.toString()),
      updatedAt: asDateTime(data['areaUpdatedAt']),
    );
  }

  @override
  Future<void> write(String userId, GeoCell cell, DateTime at) =>
      _profiles.update(userId, {
        'areaEnabled': true,
        'areaCell': cell.key,
        'areaUpdatedAt': at.toUtc().toIso8601String(),
      });

  @override
  Future<void> clear(String userId) => _profiles.update(userId, {
    'areaEnabled': false,
    'areaCell': null,
    'areaUpdatedAt': null,
  });
}

class AreaService {
  AreaService({
    PositionSource? source,
    AreaStore? store,
    DateTime Function()? clock,
  }) : _source = source ?? const GeolocatorPositionSource(),
       _store = store ?? ProfileAreaStore(),
       _clock = clock ?? DateTime.now;

  final PositionSource _source;
  final AreaStore _store;
  final DateTime Function() _clock;

  Future<GeoCell?> _cellNow() async {
    final position = await _source.current();
    return position == null
        ? null
        : GeoCell.fromLatLng(position.latitude, position.longitude);
  }

  /// Turns "Near me" on: asks the phone, reads a rough position and saves
  /// its cell.
  Future<AreaResult> enable(String userId) async {
    switch (await _source.permission(ask: true)) {
      case PositionStatus.serviceOff:
        return AreaResult.serviceOff;
      case PositionStatus.denied:
        return AreaResult.denied;
      case PositionStatus.deniedForever:
        return AreaResult.deniedForever;
      case PositionStatus.granted:
        break;
    }
    try {
      final cell = await _cellNow();
      if (cell == null) return AreaResult.failed;
      await _store.write(userId, cell, _clock());
      return AreaResult.enabled;
    } on Exception catch (error) {
      debugPrint('Could not read the area: $error');
      return AreaResult.failed;
    }
  }

  /// Turns it off and forgets the saved cell.
  Future<void> disable(String userId) => _store.clear(userId);

  /// The saved area, or null when none.
  Future<AreaRecord?> load(String userId) async {
    try {
      return await _store.read(userId);
    } on Object {
      return null;
    }
  }

  /// Refreshes a stale cell, quietly. Does nothing unless the person turned
  /// it on, never prompts, and never throws.
  Future<void> refreshIfDue(String userId) async {
    try {
      final record = await _store.read(userId);
      if (record == null || !record.enabled) return;
      final updated = record.updatedAt;
      if (updated != null && _clock().difference(updated) < kAreaRefreshAfter) {
        return;
      }
      if (await _source.permission(ask: false) != PositionStatus.granted) {
        return;
      }
      final cell = await _cellNow();
      if (cell != null) await _store.write(userId, cell, _clock());
    } on Object catch (error) {
      debugPrint('Could not refresh the area: $error');
    }
  }
}
