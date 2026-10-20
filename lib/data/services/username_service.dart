// Claims and changes @usernames. Uniqueness is kept by a lookup collection,
// usernames/{name} → {uid}: claiming creates that document in the same
// transaction that writes users/{uid}.username, so two people can never
// hold the same name (the security rules refuse a second create).
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/username.dart';

/// The name is taken or not allowed; [message] says why, in plain words.
class UsernameUnavailableException implements Exception {
  const UsernameUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UsernameService {
  UsernameService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _lookup(String name) =>
      _db.collection('usernames').doc(name);

  Future<bool> isAvailable(String input) async {
    final name = normalizeUsername(input);
    if (usernameProblem(name) != null) return false;
    final doc = await _lookup(name).get();
    return !doc.exists;
  }

  /// The first free suggestion for [displayName], or null if all are taken.
  Future<String?> firstAvailableSuggestion(String displayName) async {
    for (final candidate in usernameSuggestions(displayName)) {
      if (await isAvailable(candidate)) return candidate;
    }
    return null;
  }

  /// Gives [userId] the username [input], releasing their old one.
  /// Throws [UsernameUnavailableException] when it is invalid or taken.
  Future<String> claim({required String userId, required String input}) async {
    final name = normalizeUsername(input);
    if (usernameProblem(name) case final problem?) {
      throw UsernameUnavailableException(problem);
    }
    final userRef = _db.collection('users').doc(userId);
    await _db.runTransaction((transaction) async {
      final wanted = await transaction.get(_lookup(name));
      final owner = wanted.data()?['uid'];
      if (wanted.exists && owner != userId) {
        throw const UsernameUnavailableException(
          'That username is taken. Try another.',
        );
      }
      final user = await transaction.get(userRef);
      final previous = (user.data()?['username'] ?? '').toString();
      if (previous == name) return;
      if (previous.isNotEmpty) transaction.delete(_lookup(previous));
      transaction.set(_lookup(name), {
        'uid': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(userRef, {
        'username': name,
        'usernameUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    return name;
  }
}
