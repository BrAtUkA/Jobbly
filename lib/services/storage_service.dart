import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

/// StorageService - Handles Supabase Storage operations for profile pictures and resumes
/// 
/// File structure: 
/// - avatars/{userId}/avatar.{ext}
/// - resumes/{seekerId}/resume.{ext}
/// All images are stored in the public 'avatars' bucket.
/// All resumes are stored in the public 'resumes' bucket.
class StorageService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'avatars';
  static const String _resumeBucketName = 'resumes';

  /// Pick an image from gallery or camera
  /// Returns the selected [XFile] or null if cancelled
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 800,
    int maxHeight = 800,
    int imageQuality = 85,
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Show a bottom sheet to choose between camera and gallery
  /// Returns the selected [XFile] or null if cancelled
  static Future<XFile?> showImageSourcePicker(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: Colors.blue.shade600),
                ),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_rounded, color: Colors.green.shade600),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing photo'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;
    return pickImage(source: source);
  }

  /// Upload a profile picture to Supabase Storage
  /// 
  /// [imageFile] - The image file to upload
  /// [userId] - The user's ID (used as folder name)
  /// 
  /// Returns the public URL of the uploaded image, or null on failure
  static Future<String?> uploadProfilePicture({
    required XFile imageFile,
    required String userId,
  }) async {
    try {
      final file = File(imageFile.path);
      final extension = imageFile.path.split('.').last.toLowerCase();
      final fileName = 'avatar.$extension';
      final filePath = '$userId/$fileName';

      // Delete old avatar first (if exists) - ignore errors
      await _deleteOldAvatars(userId);

      // Upload new avatar with upsert (overwrite if exists)
      await _supabase.storage
          .from(_bucketName)
          .upload(
            filePath,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _getContentType(extension),
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      // Add cache buster to force refresh
      final urlWithCacheBuster = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      
      return urlWithCacheBuster;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      rethrow;
    }
  }

  /// Delete old avatar files for a user
  static Future<void> _deleteOldAvatars(String userId) async {
    try {
      final files = await _supabase.storage
          .from(_bucketName)
          .list(path: userId);
      
      if (files.isNotEmpty) {
        final filesToDelete = files.map((f) => '$userId/${f.name}').toList();
        await _supabase.storage.from(_bucketName).remove(filesToDelete);
      }
    } catch (e) {
      // Ignore errors when deleting old files
      debugPrint('Note: Could not delete old avatars: $e');
    }
  }

  /// Delete a user's profile picture
  /// 
  /// [userId] - The user's ID
  /// [currentUrl] - The current profile picture URL (to extract filename)
  static Future<bool> deleteProfilePicture({
    required String userId,
  }) async {
    try {
      await _deleteOldAvatars(userId);
      return true;
    } catch (e) {
      debugPrint('Error deleting profile picture: $e');
      return false;
    }
  }

  /// Get content type based on file extension
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  // ============== RESUME METHODS ==============

  /// Pick a resume file (PDF, DOC, DOCX)
  /// Returns the selected [PlatformFile] or null if cancelled
  static Future<PlatformFile?> pickResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking resume: $e');
      return null;
    }
  }

  /// Upload a resume to Supabase Storage
  /// 
  /// [resumeFile] - The resume file to upload
  /// [seekerId] - The seeker's ID (used as folder name)
  /// 
  /// Returns the public URL of the uploaded resume, or null on failure
  static Future<String?> uploadResume({
    required PlatformFile resumeFile,
    required String seekerId,
  }) async {
    try {
      if (resumeFile.path == null) {
        throw Exception('File path is null');
      }
      
      final file = File(resumeFile.path!);
      final extension = resumeFile.extension?.toLowerCase() ?? 'pdf';
      final fileName = 'resume.$extension';
      final filePath = '$seekerId/$fileName';

      // Delete old resume first (if exists) - ignore errors
      await _deleteOldResumes(seekerId);

      // Upload new resume with upsert (overwrite if exists)
      await _supabase.storage
          .from(_resumeBucketName)
          .upload(
            filePath,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _getContentType(extension),
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(_resumeBucketName)
          .getPublicUrl(filePath);

      // Add cache buster to force refresh
      final urlWithCacheBuster = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      
      return urlWithCacheBuster;
    } catch (e) {
      debugPrint('Error uploading resume: $e');
      rethrow;
    }
  }

  /// Delete old resume files for a seeker
  static Future<void> _deleteOldResumes(String seekerId) async {
    try {
      final files = await _supabase.storage
          .from(_resumeBucketName)
          .list(path: seekerId);
      
      if (files.isNotEmpty) {
        final filesToDelete = files.map((f) => '$seekerId/${f.name}').toList();
        await _supabase.storage.from(_resumeBucketName).remove(filesToDelete);
      }
    } catch (e) {
      // Ignore errors when deleting old files
      debugPrint('Note: Could not delete old resumes: $e');
    }
  }

  /// Delete a seeker's resume
  /// 
  /// [seekerId] - The seeker's ID
  static Future<bool> deleteResume({
    required String seekerId,
  }) async {
    try {
      await _deleteOldResumes(seekerId);
      return true;
    } catch (e) {
      debugPrint('Error deleting resume: $e');
      return false;
    }
  }

  /// Get the filename from a resume URL
  static String getResumeFileName(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        // Get the last segment (filename) and remove query params
        final fileName = pathSegments.last.split('?').first;
        return fileName;
      }
    } catch (e) {
      debugPrint('Error parsing resume URL: $e');
    }
    return 'resume';
  }
}
