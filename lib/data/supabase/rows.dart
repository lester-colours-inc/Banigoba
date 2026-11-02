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

/// A row flattened for the screens: the free-form `data` column's keys sit
/// beside the camelCased columns, and the columns win on a clash.
Map<String, dynamic> flattenRow(Map<String, dynamic> row) {
  final extra = row['data'];
  final columns = camelizeRow({
    for (final entry in row.entries)
      if (entry.key != 'data') entry.key: entry.value,
  });
  return {if (extra is Map) ...Map<String, dynamic>.from(extra), ...columns};
}

/// Splits camelCase [fields] into a row to write: keys that are [columns]
/// (snake_case names) become columns, everything else goes into `data`.
/// [aliases] maps a field name to the column it is stored in, e.g.
/// `imageURL` → `image_url`. Null values are dropped.
Map<String, dynamic> toStoredRow(
  Map<String, dynamic> fields, {
  required Set<String> columns,
  Map<String, String> aliases = const {},
}) {
  final row = <String, dynamic>{};
  final extra = <String, dynamic>{};
  for (final entry in fields.entries) {
    if (entry.value == null) continue;
    final column = aliases[entry.key] ?? snakeCase(entry.key);
    if (columns.contains(column)) {
      row[column] = entry.value;
    } else {
      extra[entry.key] = entry.value;
    }
  }
  if (extra.isNotEmpty) row['data'] = extra;
  return row;
}

/// Put in an update to remove a free-form field (the old `FieldValue.delete`).
const Object kRemoveField = _RemoveField();

class _RemoveField {
  const _RemoveField();
  @override
  String toString() => 'kRemoveField';
}
