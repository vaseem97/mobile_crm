import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Check if bucket exists and is accessible
  Future<bool> checkBucket(String bucket) async {
    try {
      await _supabase.storage.from(bucket).list();
      return true;
    } catch (e) {
      print('Bucket $bucket is not accessible or does not exist: $e');
      return false;
    }
  }

  // Upload a file to specified bucket and path
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
    Map<String, String>? metadata,
  }) async {
    try {
      // Check if bucket exists
      final bucketExists = await checkBucket(bucket);
      if (!bucketExists) {
        throw Exception('Bucket $bucket does not exist or is not accessible');
      }

      await _supabase.storage.from(bucket).upload(
            path,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Get public URL
      final String downloadUrl =
          _supabase.storage.from(bucket).getPublicUrl(path);
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Upload binary data
  Future<String> uploadData({
    required String bucket,
    required String path,
    required Uint8List data,
    String? contentType,
  }) async {
    try {
      // Check if bucket exists
      final bucketExists = await checkBucket(bucket);
      if (!bucketExists) {
        throw Exception('Bucket $bucket does not exist or is not accessible');
      }

      await _supabase.storage.from(bucket).uploadBinary(
            path,
            data,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      // Get public URL
      final String downloadUrl =
          _supabase.storage.from(bucket).getPublicUrl(path);
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload data: $e');
    }
  }

  // Download a file
  Future<Uint8List> downloadFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final data = await _supabase.storage.from(bucket).download(path);
      return data;
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  // Get public URL
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  // Delete a file
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // List files in a directory
  Future<List<FileObject>> listFiles({
    required String bucket,
    required String path,
  }) async {
    try {
      final list = await _supabase.storage.from(bucket).list(path: path);
      return list;
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  // Create a signed URL (temporary access URL)
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresIn, // seconds
  }) async {
    try {
      final signedURL =
          await _supabase.storage.from(bucket).createSignedUrl(path, expiresIn);
      return signedURL;
    } catch (e) {
      throw Exception('Failed to create signed URL: $e');
    }
  }

  // Helper method to determine content type from file extension
  String _getContentType(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpeg':
      case '.jpg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
