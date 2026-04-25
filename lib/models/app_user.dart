import 'package:cloud_firestore/cloud_firestore.dart';

/// User roles: admin can manage products/settings; staff can sell/stock.
enum UserRole {
  owner,
  admin,
  staff;

  static UserRole fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
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
    required this.businessId,
    this.isActive = true,
  });

  final String uid;
  final String email;
  final UserRole role;
  final String displayName;
  final String businessId;
  final bool isActive;

  bool get isOwner => role == UserRole.owner;
  bool get isAdmin => role == UserRole.owner || role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;

  factory AppUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? businessIdOverride,
  }) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      businessId: businessIdOverride ?? d['businessId'] as String? ?? '',
      email: d['email'] as String? ?? '',
      role: UserRole.fromString(d['role'] as String?),
      displayName: d['displayName'] as String? ?? '',
      isActive: d['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'businessId': businessId,
        'role': role.firestoreValue,
        'displayName': displayName,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
