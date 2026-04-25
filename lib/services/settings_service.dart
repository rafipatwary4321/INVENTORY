import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/context/business_scope.dart';
import '../models/app_settings.dart';

/// Reads/writes `settings/business`.
class SettingsService {
  SettingsService(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _ref => _db
      .collection(AppConstants.businessesCollection)
      .doc(BusinessScope.businessId)
      .collection(AppConstants.settingsCollection)
      .doc(AppConstants.settingsDocId);

  Stream<AppSettings> settingsStream() {
    return Stream<AppSettings>.multi((multi) {
      StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? settingsSub;
      final businessSub = BusinessScope.changes.listen((_) {
        settingsSub?.cancel();
        settingsSub = _ref.snapshots().listen(
          (snap) => multi.add(AppSettings.fromMap(snap.data())),
          onError: multi.addError,
        );
      });
      multi.onCancel = () async {
        await settingsSub?.cancel();
        await businessSub.cancel();
      };
    });
  }

  Future<void> save(AppSettings s) => _ref.set(s.toMap(), SetOptions(merge: true));

  Future<void> ensureDefaults() async {
    final snap = await _ref.get();
    if (!snap.exists) {
      await _ref.set({
        'businessName': 'My Business',
        'currency': AppConstants.defaultCurrency,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
