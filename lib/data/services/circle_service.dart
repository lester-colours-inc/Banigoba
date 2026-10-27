// My Circle: the salons, shops and designers a user has added as their own,
// so they come first whenever a look is sent (October 2026 review, P-6 and
// P-7). Stored privately under users/{uid}/circle/{memberId}; only the owner
// can read or change it (the users/{uid} private catch-all rule).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// What a Circle member is to the user.
enum CircleKind {
  salon('salon', 'Hair salons'),
  shop('shop', 'Shops'),
  designer('designer', 'Designers');

  const CircleKind(this.value, this.title);

  final String value;
  final String title;

  static CircleKind? fromValue(Object? value) {
    for (final kind in values) {
      if (kind.value == value) return kind;
    }
    return null;
  }
}

@immutable
class CircleMember {
  const CircleMember({
    required this.id,
    required this.kind,
    required this.name,
    this.avatarUrl = '',
    this.detail = '',
  });

  final String id;
  final CircleKind kind;
  final String name;
  final String avatarUrl;
  final String detail;

  static CircleMember? fromMap(String id, Map<String, dynamic> data) {
    final kind = CircleKind.fromValue(data['kind']);
    if (kind == null) return null;
    return CircleMember(
      id: id,
      kind: kind,
      name: (data['name'] ?? '').toString(),
      avatarUrl: (data['avatarUrl'] ?? '').toString(),
      detail: (data['detail'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'kind': kind.value,
    'name': name,
    'avatarUrl': avatarUrl,
    'detail': detail,
    'addedAt': FieldValue.serverTimestamp(),
  };
}

class CircleService {
  CircleService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _circle(String userId) =>
      _db.collection('users').doc(userId).collection('circle');

  /// Everyone in the user's Circle, A to Z.
  Stream<List<CircleMember>> watch(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return _circle(userId).snapshots().map((snapshot) {
      final members = [
        for (final doc in snapshot.docs)
          if (CircleMember.fromMap(doc.id, doc.data()) case final member?)
            member,
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return List.unmodifiable(members);
    });
  }

  Future<void> add(String userId, CircleMember member) =>
      _circle(userId).doc(member.id).set(member.toMap());

  Future<void> remove(String userId, String memberId) =>
      _circle(userId).doc(memberId).delete();
}
