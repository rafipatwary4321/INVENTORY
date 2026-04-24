import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/app_user.dart';

/// Ensures `users/{uid}` exists and streams profile updates.
class UserService {
  UserService(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _db.collection(AppConstants.usersCollection).doc(uid);

  /// Creates or updates user profile (role should be set in Firestore for staff).
  Future<void> ensureUserDocument({
    required String uid,
    required String email,
    required String displayName,
    String role = 'staff',
  }) async {
    final ref = userRef(uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'email': email,
        'displayName': displayName,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({
        'email': email,
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<AppUser?> userStream(String uid) {
    return userRef(uid).snapshots().map((d) {
      if (!d.exists) return null;
      return AppUser.fromFirestore(d);
    });
  }

  Future<AppUser?> fetchUser(String uid) async {
    final d = await userRef(uid).get();
    if (!d.exists) return null;
    return AppUser.fromFirestore(d);
  }
}
