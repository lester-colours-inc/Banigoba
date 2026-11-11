import 'package:banigoba/modules/home/models/geo_cell.dart';
import 'package:banigoba/modules/home/services/area_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _Source implements PositionSource {
  _Source({this.status = PositionStatus.granted, this.fails = false});

  // Central Harare.
  static const double latitude = -17.8292;
  static const double longitude = 31.0522;

  PositionStatus status;
  final bool fails;
  final List<bool> asked = [];
  int reads = 0;

  @override
  Future<PositionStatus> permission({required bool ask}) async {
    asked.add(ask);
    return status;
  }

  @override
  Future<({double latitude, double longitude})?> current() async {
    reads += 1;
    if (fails) throw Exception('no fix');
    return (latitude: _Source.latitude, longitude: _Source.longitude);
  }
}

class _Store implements AreaStore {
  AreaRecord? record;
  int writes = 0;

  @override
  Future<AreaRecord?> read(String userId) async => record;

  @override
  Future<void> write(String userId, GeoCell cell, DateTime at) async {
    writes += 1;
    record = AreaRecord(enabled: true, cell: cell, updatedAt: at);
  }

  @override
  Future<void> clear(String userId) async {
    record = const AreaRecord(enabled: false);
  }
}

final _now = DateTime(2026, 10, 28, 12);

AreaService _service(_Source source, _Store store) =>
    AreaService(source: source, store: store, clock: () => _now);

void main() {
  group('enable', () {
    test('saves only the coarse cell, never the coordinates', () async {
      final store = _Store();

      final result = await _service(_Source(), store).enable('me');

      expect(result, AreaResult.enabled);
      expect(store.record?.cell, GeoCell.fromLatLng(-17.8292, 31.0522));
      expect(store.record?.enabled, isTrue);
      expect(store.record?.updatedAt, _now);
    });

    test('asks the phone for permission', () async {
      final source = _Source();

      await _service(source, _Store()).enable('me');

      expect(source.asked, [true]);
    });

    test('saves nothing when location is switched off on the phone', () async {
      final store = _Store();

      final result = await _service(
        _Source(status: PositionStatus.serviceOff),
        store,
      ).enable('me');

      expect(result, AreaResult.serviceOff);
      expect(store.writes, 0);
    });

    test('saves nothing when permission is refused', () async {
      final store = _Store();

      expect(
        await _service(
          _Source(status: PositionStatus.denied),
          store,
        ).enable('me'),
        AreaResult.denied,
      );
      expect(
        await _service(
          _Source(status: PositionStatus.deniedForever),
          store,
        ).enable('me'),
        AreaResult.deniedForever,
      );
      expect(store.writes, 0);
    });

    test('reports a failed fix instead of throwing', () async {
      final store = _Store();

      final result = await _service(_Source(fails: true), store).enable('me');

      expect(result, AreaResult.failed);
      expect(store.writes, 0);
    });
  });

  group('disable', () {
    test('forgets the area', () async {
      final store = _Store()
        ..record = AreaRecord(
          enabled: true,
          cell: const GeoCell(1, 2),
          updatedAt: _now,
        );

      await _service(_Source(), store).disable('me');

      expect(store.record?.enabled, isFalse);
      expect(store.record?.cell, isNull);
    });
  });

  group('refreshIfDue', () {
    AreaRecord record(Duration age, {bool enabled = true}) => AreaRecord(
      enabled: enabled,
      cell: const GeoCell(1, 2),
      updatedAt: _now.subtract(age),
    );

    test('updates a day-old area, quietly', () async {
      final source = _Source();
      final store = _Store()..record = record(const Duration(hours: 30));

      await _service(source, store).refreshIfDue('me');

      expect(store.writes, 1);
      expect(source.asked, [false], reason: 'never prompts on its own');
      expect(store.record?.cell, GeoCell.fromLatLng(-17.8292, 31.0522));
    });

    test('leaves a fresh area alone and does not touch GPS', () async {
      final source = _Source();
      final store = _Store()..record = record(const Duration(hours: 2));

      await _service(source, store).refreshIfDue('me');

      expect(store.writes, 0);
      expect(source.reads, 0);
    });

    test('does nothing when the person has not turned it on', () async {
      final source = _Source();
      final store = _Store()
        ..record = record(const Duration(days: 9), enabled: false);

      await _service(source, store).refreshIfDue('me');

      expect(store.writes, 0);
      expect(source.asked, isEmpty);
    });

    test('does nothing for someone who never set it up', () async {
      final source = _Source();

      await _service(source, _Store()).refreshIfDue('me');

      expect(source.asked, isEmpty);
    });

    test(
      'keeps the old area when permission has since been taken away',
      () async {
        final store = _Store()..record = record(const Duration(days: 3));

        await _service(
          _Source(status: PositionStatus.denied),
          store,
        ).refreshIfDue('me');

        expect(store.writes, 0);
        expect(store.record?.cell, const GeoCell(1, 2));
      },
    );

    test('a failed fix never throws', () async {
      final store = _Store()..record = record(const Duration(days: 3));

      await _service(_Source(fails: true), store).refreshIfDue('me');

      expect(store.writes, 0);
    });
  });
}
