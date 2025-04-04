import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get a reference to storage
  Reference ref(String path) {
    return _storage.ref().child(path);
  }

  // Upload a file
  Future<String> uploadFile({
    required String path,
    required File file,
    Map<String, String>? metadata,
  }) async {
    try {
      final storageRef = _storage.ref().child(path);

      UploadTask uploadTask;

      if (metadata != null) {
        uploadTask = storageRef.putFile(
          file,
          SettableMetadata(customMetadata: metadata),
        );
      } else {
        uploadTask = storageRef.putFile(file);
      }

      // Wait for the upload to complete
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Upload data
  Future<String> uploadData({
    required String path,
    required List<int> data,
    String? contentType,
  }) async {
    try {
      final storageRef = _storage.ref().child(path);

      final uploadTask = storageRef.putData(
        Uint8List.fromList(data),
        SettableMetadata(contentType: contentType),
      );

      // Wait for the upload to complete
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload data: $e');
    }
  }

  // Download a file
  Future<Uint8List> downloadFile(String path) async {
    try {
      final storageRef = _storage.ref().child(path);
      final data = await storageRef.getData();

      if (data == null) {
        throw Exception('Failed to download file: No data found');
      }

      return data;
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  // Get download URL
  Future<String> getDownloadURL(String path) async {
    try {
      final storageRef = _storage.ref().child(path);
      return await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }

  // Delete a file
  Future<void> deleteFile(String path) async {
    try {
      final storageRef = _storage.ref().child(path);
      await storageRef.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // List files in a directory
  Future<ListResult> listFiles(String path) async {
    try {
      final storageRef = _storage.ref().child(path);
      return await storageRef.listAll();
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  // Get metadata
  Future<FullMetadata> getMetadata(String path) async {
    try {
      final storageRef = _storage.ref().child(path);
      return await storageRef.getMetadata();
    } catch (e) {
      throw Exception('Failed to get metadata: $e');
    }
  }

  // Update metadata
  Future<FullMetadata> updateMetadata({
    required String path,
    required Map<String, String> metadata,
  }) async {
    try {
      final storageRef = _storage.ref().child(path);
      return await storageRef.updateMetadata(
        SettableMetadata(customMetadata: metadata),
      );
    } catch (e) {
      throw Exception('Failed to update metadata: $e');
    }
  }
}
