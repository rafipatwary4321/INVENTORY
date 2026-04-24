import 'package:cloud_firestore/cloud_firestore.dart';

/// User roles: admin can manage products/settings; staff can sell/stock.
enum UserRole {
  admin,
  staff;

  static UserRole fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.staff;
    }
  }

  String get firestoreValue => name;
}

/// App user profile stored in `users/{uid}`.
class AppUser {
  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.displayName,
  });

  final String uid;
  final String email;
  final UserRole role;
  final String displayName;

  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      email: d['email'] as String? ?? '',
      role: UserRole.fromString(d['role'] as String?),
      displayName: d['displayName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'role': role.firestoreValue,
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
