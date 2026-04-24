import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/app_settings.dart';

/// Reads/writes `settings/business`.
class SettingsService {
  SettingsService(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _ref =>
      _db.collection(AppConstants.settingsCollection).doc(AppConstants.settingsDocId);

  Stream<AppSettings> settingsStream() {
    return _ref.snapshots().map((snap) {
      return AppSettings.fromMap(snap.data());
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
