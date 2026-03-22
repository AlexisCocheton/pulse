import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a profile photo and return the download URL.
  Future<String> uploadProfilePhoto(String userId, File file) async {
    try {
      final ref = _storage.ref().child('profiles/$userId/photo.jpg');
      final task = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Erreur upload (${e.code}): ${e.message}');
    }
  }

  /// Delete the profile photo from Storage.
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      await _storage.ref().child('profiles/$userId/photo.jpg').delete();
    } catch (_) {
      // Ignore if file doesn't exist
    }
  }
}
