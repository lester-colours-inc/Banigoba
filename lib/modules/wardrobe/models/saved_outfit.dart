// A saved outfit document, as the wardrobe calendar lists it.
import 'package:banigoba/core/supabase/rows.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_outfit.freezed.dart';

@freezed
abstract class SavedOutfit with _$SavedOutfit {
  const SavedOutfit._();

  const factory SavedOutfit(String id, Map<String, dynamic> data) =
      _SavedOutfit;

  String get name => (data['name'] ?? 'Completed Look').toString();

  DateTime get createdAt => asDateTime(data['createdAt']) ?? DateTime(1970);
}
