import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads product images to Firebase Storage under `products/{productId}/...`.
class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  /// Returns download URL or null if [file] is null (no new image).
  Future<String?> uploadProductImage({
    required String productId,
    required File file,
  }) async {
    final path = 'products/$productId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(path);
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
