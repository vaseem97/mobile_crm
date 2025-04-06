import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Uint8List?> _compressImage(File file) async {
    try {
      // Compress the image
      final Uint8List? result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 1080, // Adjust width as needed
        minHeight: 1920, // Adjust height as needed
        quality: 75, // Adjust quality (0-100)
      );
      return result;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  Future<String?> uploadImage(
      File imageFile, String repairId, int imageIndex) async {
    try {
      // Compress the image first
      final Uint8List? compressedData = await _compressImage(imageFile);
      if (compressedData == null) {
        print('Image compression failed for ${imageFile.path}');
        return null; // Skip upload if compression failed
      }

      // Create a unique filename
      final String fileExtension = p.extension(imageFile.path);
      final String fileName =
          'repair_${repairId}_image_$imageIndex$fileExtension';
      final String filePath = 'repair_images/$repairId/$fileName';

      // Create reference
      final Reference ref = _storage.ref().child(filePath);

      // Upload the compressed data
      print('Uploading compressed image $imageIndex for repair $repairId...');
      final UploadTask uploadTask = ref.putData(
          compressedData,
          SettableMetadata(
              contentType:
                  'image/${fileExtension.replaceAll('.', '')}') // Set content type
          );

      // Await completion
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Uploaded image $imageIndex for repair $repairId: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      print(
          'Error uploading image to Firebase Storage: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('An unexpected error occurred during image upload: $e');
      return null;
    }
  }

  Future<List<String>> uploadRepairImages(
      List<File> images, String repairId) async {
    final List<String> uploadedUrls = [];
    if (images.isEmpty) {
      return uploadedUrls;
    }

    print('Starting image upload for repair $repairId...');
    // Use Future.wait for potentially faster parallel uploads
    final List<Future<String?>> uploadFutures = [];
    for (int i = 0; i < images.length; i++) {
      uploadFutures.add(uploadImage(images[i], repairId, i + 1));
    }

    final List<String?> results = await Future.wait(uploadFutures);

    for (int i = 0; i < results.length; i++) {
      final url = results[i];
      if (url != null) {
        uploadedUrls.add(url);
      } else {
        print('Failed to upload image ${i + 1} for repair $repairId');
        // Optionally, rethrow an error or notify the user if an upload fails
      }
    }

    print(
        'Finished uploading ${uploadedUrls.length}/${images.length} images for repair $repairId.');
    return uploadedUrls;
  }
}

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
