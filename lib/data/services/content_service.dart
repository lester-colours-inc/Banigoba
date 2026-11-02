import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';
import '../models/content_item.dart';
import '../supabase/rows.dart';

/// What the screens need; the real one reads the database, tests use a fake.
abstract interface class ContentSource {
  Future<List<ContentItem>> latest({int limit});
}

class ContentService implements ContentSource {
  /// The newest stories first. Empty when none exist or they cannot be read:
  /// the sections simply stay hidden then.
  @override
  Future<List<ContentItem>> latest({int limit = 60}) async {
    try {
      final rows = await supabase
          .from('content_items')
          .select()
          .order('published_at', ascending: false)
          .limit(limit);
      return [
        for (final row in rows)
          if (ContentItem.fromMap(row['id'].toString(), camelizeRow(row))
              case final item
              when item.title.isNotEmpty && item.opensSafely)
            item,
      ];
    } on PostgrestException {
      return const [];
    }
  }
}
