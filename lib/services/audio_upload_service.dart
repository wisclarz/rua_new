import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Audio Upload Service
///
/// SOLID Principles:
/// - Single Responsibility: Sadece ses dosyası yükleme işlemlerini yönetir
/// - Dependency Injection: Firebase Storage inject edilir
/// - Open/Closed: Farklı storage provider'lar eklenebilir
///
/// Responsibilities:
/// - Upload audio files to Firebase Storage
/// - Generate download URLs
/// - Progress tracking
/// - Metadata management
class AudioUploadService {
  final FirebaseStorage _storage;

  AudioUploadService({
    FirebaseStorage? storage,
  }) : _storage = storage ?? FirebaseStorage.instance;

  /// Upload audio file to Firebase Storage
  ///
  /// [userId]: User ID for organizing files
  /// [audioFile]: The audio file to upload
  /// [fileName]: Optional custom file name
  /// [onProgress]: Optional callback for upload progress (0.0 to 1.0)
  ///
  /// Returns: Download URL of the uploaded file
  Future<String> uploadAudio({
    required String userId,
    required File audioFile,
    String? fileName,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Validate file
      if (!audioFile.existsSync()) {
        throw Exception('Ses dosyası bulunamadı');
      }

      final fileSize = audioFile.lengthSync();
      if (fileSize < 1000) {
        throw Exception('Ses dosyası çok kısa veya bozuk');
      }

      debugPrint('📤 Starting audio upload...');
      debugPrint('👤 User ID: $userId');
      debugPrint('📁 File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // Generate file name if not provided
      final actualFileName = fileName ??
          'dream_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Create storage reference
      final Reference storageRef = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('dreams')
          .child(actualFileName);

      debugPrint('📂 Storage path: users/$userId/dreams/$actualFileName');

      // Prepare metadata
      final metadata = _createMetadata(
        userId: userId,
        fileSize: fileSize,
      );

      // Start upload
      final UploadTask uploadTask = storageRef.putFile(audioFile, metadata);

      // Track progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          debugPrint('📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
          onProgress(progress);
        });
      } else {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          debugPrint('📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        });
      }

      // Wait for completion
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Upload completed successfully');
      debugPrint('🔗 Download URL: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase upload error: ${e.code} - ${e.message}');
      throw Exception('Firebase Storage yükleme hatası: ${e.message}');
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      throw Exception('Ses dosyası yüklenemedi: $e');
    }
  }

  /// Upload audio file with retry logic
  ///
  /// Automatically retries failed uploads up to [maxRetries] times
  Future<String> uploadAudioWithRetry({
    required String userId,
    required File audioFile,
    String? fileName,
    Function(double progress)? onProgress,
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < maxRetries) {
      try {
        debugPrint('🔄 Upload attempt ${attempt + 1}/$maxRetries');

        return await uploadAudio(
          userId: userId,
          audioFile: audioFile,
          fileName: fileName,
          onProgress: onProgress,
        );
      } catch (e) {
        lastError = e as Exception;
        attempt++;

        if (attempt < maxRetries) {
          debugPrint('⚠️ Upload failed, retrying in ${attempt * 2} seconds...');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    debugPrint('❌ Upload failed after $maxRetries attempts');
    throw lastError ?? Exception('Yükleme başarısız');
  }

  /// Delete audio file from Firebase Storage
  Future<void> deleteAudio({
    required String userId,
    required String fileName,
  }) async {
    try {
      debugPrint('🗑️ Deleting audio file...');
      debugPrint('👤 User ID: $userId');
      debugPrint('📁 File name: $fileName');

      final Reference storageRef = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('dreams')
          .child(fileName);

      await storageRef.delete();

      debugPrint('✅ Audio file deleted successfully');
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase delete error: ${e.code} - ${e.message}');
      throw Exception('Ses dosyası silinemedi: ${e.message}');
    } catch (e) {
      debugPrint('❌ Delete error: $e');
      throw Exception('Ses dosyası silinemedi: $e');
    }
  }

  /// Delete audio file by download URL
  Future<void> deleteAudioByUrl(String downloadUrl) async {
    try {
      debugPrint('🗑️ Deleting audio file by URL...');

      final Reference storageRef = _storage.refFromURL(downloadUrl);
      await storageRef.delete();

      debugPrint('✅ Audio file deleted successfully');
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase delete error: ${e.code} - ${e.message}');
      throw Exception('Ses dosyası silinemedi: ${e.message}');
    } catch (e) {
      debugPrint('❌ Delete error: $e');
      throw Exception('Ses dosyası silinemedi: $e');
    }
  }

  /// Get download URL for an existing file
  Future<String?> getDownloadUrl({
    required String userId,
    required String fileName,
  }) async {
    try {
      final Reference storageRef = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('dreams')
          .child(fileName);

      final String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase getDownloadURL error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ getDownloadURL error: $e');
      return null;
    }
  }

  /// Check if file exists in storage
  Future<bool> fileExists({
    required String userId,
    required String fileName,
  }) async {
    try {
      final Reference storageRef = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('dreams')
          .child(fileName);

      await storageRef.getDownloadURL();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// List all audio files for a user
  Future<List<Reference>> listUserAudioFiles({
    required String userId,
    int maxResults = 100,
  }) async {
    try {
      final Reference storageRef = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('dreams');

      final ListResult result = await storageRef.list(
        ListOptions(maxResults: maxResults),
      );

      debugPrint('📁 Found ${result.items.length} audio files');
      return result.items;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase list error: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ List error: $e');
      return [];
    }
  }

  /// Create metadata for uploaded file
  SettableMetadata _createMetadata({
    required String userId,
    required int fileSize,
  }) {
    return SettableMetadata(
      contentType: 'audio/mp4',
      customMetadata: {
        'uploadedBy': userId,
        'uploadedAt': DateTime.now().toIso8601String(),
        'fileSize': fileSize.toString(),
        'codec': 'aac',
        'version': '1.0',
      },
    );
  }
}

/// Upload progress callback type
typedef UploadProgressCallback = void Function(double progress);
