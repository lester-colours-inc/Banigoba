// The city each post author chose (a public field on their profile),
// loaded once per author and kept, so the feeds can rank and filter by "near
// me" (A-5, P-5). An author with no city is remembered as '' so they are not
// asked for again.
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:banigoba/core/supabase/supabase_config.dart';

import 'package:banigoba/modules/home/models/geo_cell.dart';
import 'package:banigoba/modules/home/services/feed_matches_service.dart'
    show batchesOf;

class AuthorCities {
  final Map<String, String> _cities = {};
  final Map<String, GeoCell> _cells = {};

  /// Every city known so far, by author id.
  Map<String, String> get known => Map.unmodifiable(_cities);

  /// The coarse area of every author who shares one, by author id.
  Map<String, GeoCell> get knownCells => Map.unmodifiable(_cells);

  /// Loads the cities of authors not seen before. True when something new
  /// was learned, so the caller knows to rebuild.
  Future<bool> ensure(Iterable<String> authorIds) async {
    final missing = {
      for (final id in authorIds)
        if (id.isNotEmpty && !_cities.containsKey(id)) id,
    };
    if (missing.isEmpty) return false;
    for (final id in missing) {
      _cities[id] = '';
    }
    for (final batch in batchesOf(missing)) {
      try {
        final rows = await supabase
            .from('profiles')
            .select('id, city, area_cell')
            .inFilter('id', batch);
        for (final row in rows) {
          final id = row['id'].toString();
          _cities[id] = (row['city'] ?? '').toString();
          if (GeoCell.tryParse(row['area_cell']?.toString()) case final cell?) {
            _cells[id] = cell;
          }
        }
      } on PostgrestException {
        // Leave them as unknown; the feed still works, just without "near".
      }
    }
    return true;
  }

  /// The signed-in person's own city, '' when none is set.
  Future<String> cityOf(String userId) async {
    try {
      final profile = await supabase
          .from('profiles')
          .select('city')
          .eq('id', userId)
          .maybeSingle();
      final city = (profile?['city'] ?? '').toString();
      if (city.isNotEmpty) return city;
      final account = await supabase
          .from('private_account')
          .select('address')
          .eq('id', userId)
          .maybeSingle();
      final address = account?['address'];
      return address is Map ? (address['city'] ?? '').toString() : '';
    } on PostgrestException {
      return '';
    }
  }
}
