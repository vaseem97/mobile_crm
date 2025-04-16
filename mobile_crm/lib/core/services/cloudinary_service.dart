import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class CloudinaryService {
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
  }

  /// Upload multiple images to Cloudinary
  /// Returns a list of URLs of the uploaded images
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    try {
      final List<String> imageUrls = [];

      for (final file in imageFiles) {
        final url = await uploadImage(file);
        imageUrls.add(url);
      }

      return imageUrls;
    } catch (e) {
      debugPrint('Error uploading multiple images: $e');
      throw Exception('Failed to upload images: $e');
    }
  }
}
