// Helpers for turning database rows into the maps the models already read.
//
// Postgres columns are snake_case; the models were written against camelCase
// document fields, so [camelizeRow] bridges the two without touching every
// model's field names.

String _camel(String key) {
  if (!key.contains('_')) return key;
  final parts = key.split('_');
  final tail = parts
      .skip(1)
      .map(
        (part) =>
            part.isEmpty ? part : part[0].toUpperCase() + part.substring(1),
      );
  return parts.first + tail.join();
}

/// A row with its top-level keys converted from snake_case to camelCase.
/// jsonb columns keep their inner keys, which are already camelCase.
Map<String, dynamic> camelizeRow(Map<String, dynamic> row) => {
  for (final entry in row.entries) _camel(entry.key): entry.value,
};

/// camelCase to snake_case, for writing a field back to its column.
String snakeCase(String key) => key.replaceAllMapped(
  RegExp(r'[A-Z]'),
  (match) => '_${match.group(0)!.toLowerCase()}',
);

/// A timestamp column as a [DateTime]; accepts strings, DateTimes or null.
DateTime? asDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
