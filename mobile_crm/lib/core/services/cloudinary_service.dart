import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'connectivity_mixin.dart';

class CloudinaryService with ConnectivityAware {
  late final Cloudinary _cloudinary;

  // Singleton pattern
  static final CloudinaryService _instance = CloudinaryService._internal();

  factory CloudinaryService() {
    return _instance;
  }

  CloudinaryService._internal() {
    _cloudinary = Cloudinary.signedConfig(
      apiKey: AppConstants.cloudinaryApiKey,
      apiSecret: AppConstants.cloudinaryApiSecret,
      cloudName: AppConstants.cloudinaryCloudName,
    );
  }

  /// Upload a single image to Cloudinary
  /// Returns the URL of the uploaded image
  Future<String> uploadImage(File imageFile) async {
    return executeWithConnectivity(() async {
      try {
        final response = await _cloudinary.upload(
          file: imageFile.path,
          folder: 'repair_images',
          resourceType: CloudinaryResourceType.image,
        );

        if (response.isSuccessful) {
          return response.secureUrl ?? '';
        } else {
          throw Exception('Failed to upload image: ${response.error}');
        }
      } catch (e) {
        debugPrint('Error uploading to Cloudinary: $e');
        throw Exception('Failed to upload image: $e');
      }
    });
  }

  /// Upload multiple images to Cloudinary
  /// Returns a list of URLs of the uploaded images
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    return executeWithConnectivity(() async {
      try {
        final List<String> imageUrls = [];

        for (final file in imageFiles) {
          // Note: We don't need to wrap the individual uploadImage call with connectivity check
          // since it already has its own check, and we're already checking at this level
          final url = await uploadImage(file);
          imageUrls.add(url);
        }

        return imageUrls;
      } catch (e) {
        debugPrint('Error uploading multiple images: $e');
        throw Exception('Failed to upload images: $e');
      }
    });
  }

  /// Upload multiple images to Cloudinary with progress callback
  /// Returns a list of URLs of the uploaded images
  Future<List<String>> uploadImagesWithProgress(
    List<File> images,
    Function(int, double) onProgress,
  ) async {
    List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      File image = images[i];

      // Start progress
      onProgress(i, 0.0);

      try {
        // Simulate upload progress updates (replace with actual Cloudinary SDK implementation)
        // In a real implementation, you would use the Cloudinary SDK's progress callback

        // Simulate 50% progress
        await Future.delayed(const Duration(milliseconds: 500));
        onProgress(i, 0.5);

        // Simulate 80% progress
        await Future.delayed(const Duration(milliseconds: 500));
        onProgress(i, 0.8);

        // Perform the actual upload (reuse existing upload logic)
        final String url = await uploadImage(image);
        urls.add(url);

        // Complete progress
        onProgress(i, 1.0);
      } catch (e) {
        // Handle upload error
        print('Error uploading image: $e');
        // Still mark as complete even if failed
        onProgress(i, 1.0);
      }
    }

    return urls;
  }
}
