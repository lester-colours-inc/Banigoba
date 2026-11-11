// A saved outfit document, as the wardrobe calendar lists it.
import 'package:banigoba/core/supabase/rows.dart';

class SavedOutfit {
  const SavedOutfit(this.id, this.data);

  final String id;
  final Map<String, dynamic> data;

  String get name => (data['name'] ?? 'Completed Look').toString();

  DateTime get createdAt => asDateTime(data['createdAt']) ?? DateTime(1970);
}
