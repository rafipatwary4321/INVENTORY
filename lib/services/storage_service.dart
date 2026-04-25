import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads product images to Firebase Storage under `products/{productId}/...`.
class StorageService {
  StorageService({
    required FirebaseStorage? storage,
    required bool firebaseEnabled,
  })  : _storage = storage,
        _firebaseEnabled = firebaseEnabled;

  final FirebaseStorage? _storage;
  final bool _firebaseEnabled;

  /// Returns download URL or null if [file] is null (no new image).
  Future<String?> uploadProductImage({
    required String productId,
    required File file,
  }) async {
    if (!_firebaseEnabled || _storage == null) {
      throw StateError('Image upload is unavailable in demo mode.');
    }
    final path = 'products/$productId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(path);
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
