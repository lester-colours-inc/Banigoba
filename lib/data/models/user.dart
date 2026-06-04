import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String stylePreference;
  final String role;
  final bool isAdmin;
  final DateTime? lastSeen;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.stylePreference = 'casual',
    this.role = 'user',
    this.isAdmin = false,
    this.lastSeen,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      stylePreference: data['stylePreference'] ?? data['style'] ?? 'casual',
      role: data['role'] ?? 'user',
      isAdmin: data['isAdmin'] ?? (data['role'] == 'admin'),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'stylePreference': stylePreference,
      'role': role,
      'isAdmin': isAdmin,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : FieldValue.serverTimestamp(),
    };
  }
}
