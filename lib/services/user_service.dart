import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/business_profile.dart';

class UserMembership {
  const UserMembership({
    required this.businessId,
    required this.user,
  });

  final String businessId;
  final AppUser user;
}

/// Multitenant user/business operations.
class UserService {
  UserService(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> businessRef(String businessId) => _db
      .collection(AppConstants.businessesCollection)
      .doc(businessId);

  CollectionReference<Map<String, dynamic>> usersCol(String businessId) =>
      businessRef(businessId).collection(AppConstants.usersCollection);

  DocumentReference<Map<String, dynamic>> userRef(String businessId, String uid) =>
      usersCol(businessId).doc(uid);

  DocumentReference<Map<String, dynamic>> legacyUserRef(String uid) =>
      _db.collection(AppConstants.usersCollection).doc(uid);

  Future<void> ensureBusinessDefaults({
    required String businessId,
    required String ownerId,
    String businessName = 'My Business',
  }) async {
    final ref = businessRef(businessId);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'businessName': businessName,
      'ownerId': ownerId,
      'address': '',
      'phone': '',
      'currency': AppConstants.defaultCurrency,
      'subscriptionPlan': 'free',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Creates or updates user profile (role should be set in Firestore for staff).
  Future<void> ensureUserMembership({
    required String businessId,
    required String uid,
    required String email,
    required String displayName,
    String role = 'staff',
    bool isActive = true,
  }) async {
    final ref = userRef(businessId, uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': uid,
        'businessId': businessId,
        'email': email,
        'displayName': displayName,
        'role': role,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({
        'uid': uid,
        'businessId': businessId,
        'email': email,
        'displayName': displayName,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<AppUser?> userStream(String businessId, String uid) {
    return userRef(businessId, uid).snapshots().map((d) {
      if (!d.exists) return null;
      return AppUser.fromFirestore(d, businessIdOverride: businessId);
    });
  }

  Future<UserMembership?> findMembership(String uid) async {
    final q = await _db
        .collectionGroup(AppConstants.usersCollection)
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
      final doc = q.docs.first;
      final businessId = doc.reference.parent.parent?.id ?? '';
      if (businessId.isEmpty) return null;
      return UserMembership(
        businessId: businessId,
        user: AppUser.fromFirestore(
          doc,
          businessIdOverride: businessId,
        ),
      );
    }

    // Backward-compat fallback from legacy single-tenant users/{uid}.
    final legacy = await legacyUserRef(uid).get();
    if (!legacy.exists) return null;
    final oldUser = AppUser.fromFirestore(
      legacy,
      businessIdOverride: 'biz_$uid',
    );
    final businessId = oldUser.businessId;
    await ensureBusinessDefaults(
      businessId: businessId,
      ownerId: uid,
      businessName: 'My Business',
    );
    await ensureUserMembership(
      businessId: businessId,
      uid: uid,
      email: oldUser.email,
      displayName: oldUser.displayName,
      role: oldUser.role.firestoreValue,
      isActive: true,
    );
    return UserMembership(
      businessId: businessId,
      user: AppUser(
        uid: uid,
        email: oldUser.email,
        role: oldUser.role,
        displayName: oldUser.displayName,
        businessId: businessId,
      ),
    );
  }

  Stream<List<AppUser>> teamStream(String businessId) {
    return usersCol(businessId)
        .orderBy('displayName')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppUser.fromFirestore(d, businessIdOverride: businessId))
            .toList());
  }

  Future<void> upsertTeamMember({
    required String businessId,
    required String uid,
    required String email,
    required String displayName,
    required UserRole role,
    required bool isActive,
  }) async {
    await userRef(businessId, uid).set({
      'uid': uid,
      'businessId': businessId,
      'email': email,
      'displayName': displayName,
      'role': role.firestoreValue,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<BusinessProfile?> fetchBusiness(String businessId) async {
    final d = await businessRef(businessId).get();
    if (!d.exists) return null;
    return BusinessProfile.fromFirestore(d);
  }
}
