// The @username: a unique public handle, separate from the display name
// (which need not be unique) and from the email (which stays private).
// October 2026 review, U-4 and U-5.
//
// Rules, like Instagram's: 3 to 20 characters; lowercase letters, numbers,
// dots and underscores; no dot at the start or end, and no two dots in a row.

const int kUsernameMinLength = 3;
const int kUsernameMaxLength = 20;

final RegExp _allowed = RegExp(r'^[a-z0-9._]+$');

/// Names that would confuse people or impersonate the app.
const Set<String> kReservedUsernames = {
  'admin',
  'administrator',
  'banigoba',
  'curator',
  'help',
  'moderator',
  'official',
  'support',
};

/// Lower-cases [input] and drops a leading "@" and surrounding spaces.
String normalizeUsername(String input) {
  final trimmed = input.trim().toLowerCase();
  return trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
}

/// Why [input] cannot be a username, in plain words, or null if it can.
String? usernameProblem(String input) {
  final name = normalizeUsername(input);
  if (name.length < kUsernameMinLength) {
    return 'Use at least $kUsernameMinLength characters.';
  }
  if (name.length > kUsernameMaxLength) {
    return 'Use $kUsernameMaxLength characters or fewer.';
  }
  if (!_allowed.hasMatch(name)) {
    return 'Use only letters, numbers, dots and underscores.';
  }
  if (name.startsWith('.') || name.endsWith('.')) {
    return "A username can't start or end with a dot.";
  }
  if (name.contains('..')) {
    return "A username can't have two dots in a row.";
  }
  if (kReservedUsernames.contains(name)) {
    return 'That username is reserved. Try another.';
  }
  return null;
}

/// A valid username built from a display name, e.g. "Tariro Muzaya" →
/// "tariro.muzaya". Falls back to [fallback] when the name has no usable
/// letters.
String usernameFromName(String displayName, {String fallback = 'user'}) {
  final words = displayName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s._]'), '')
      .split(RegExp(r'[\s._]+'))
      .where((word) => word.isNotEmpty)
      .toList();
  var base = words.join('.');
  if (base.length > kUsernameMaxLength) {
    base = base
        .substring(0, kUsernameMaxLength)
        .replaceAll(RegExp(r'\.+$'), '');
  }
  if (usernameProblem(base) != null) base = fallback;
  return base;
}

/// Candidates to offer, best first: the name itself, then with numbers.
/// Every candidate is valid; availability is checked by the caller.
List<String> usernameSuggestions(String displayName, {int count = 6}) {
  final base = usernameFromName(displayName);
  final room = kUsernameMaxLength - 2;
  final stem = base.length > room ? base.substring(0, room) : base;
  return List.unmodifiable([
    base,
    for (var i = 1; i < count; i++) '$stem${i + 1}',
  ]);
}
