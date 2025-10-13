import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../services/openai_service.dart';
import '../services/cache_service.dart';

/// Transcription Service
///
/// SOLID Principles:
/// - Single Responsibility: Sadece ses-metin dönüşümünü yönetir
/// - Dependency Injection: OpenAI servisi inject edilir
/// - Open/Closed: Farklı transcription provider'lar eklenebilir
///
/// Features:
/// - Audio to text conversion using OpenAI Whisper
/// - Automatic caching of transcriptions
/// - Cache key based on file hash
/// - Support for multiple languages
class TranscriptionService {
  final OpenAIService _openAIService;
  final CacheService _cacheService;

  TranscriptionService({
    OpenAIService? openAIService,
    CacheService? cacheService,
  })  : _openAIService = openAIService ?? OpenAIService(),
        _cacheService = cacheService ?? CacheService.instance;

  /// Transcribe audio file to text
  ///
  /// [audioFile]: The audio file to transcribe
  /// [language]: Language code (default: 'tr' for Turkish)
  /// [useCache]: Whether to use cached transcription (default: true)
  ///
  /// Returns: Transcribed text or null if failed
  Future<String?> transcribe({
    required File audioFile,
    String language = 'tr',
    bool useCache = true,
  }) async {
    try {
      // Validate file
      if (!audioFile.existsSync()) {
        debugPrint('❌ Audio file does not exist');
        throw Exception('Ses dosyası bulunamadı');
      }

      final fileSize = audioFile.lengthSync();
      if (fileSize < 1000) {
        debugPrint('❌ Audio file too small: $fileSize bytes');
        throw Exception('Ses dosyası çok kısa veya bozuk');
      }

      debugPrint('🎙️ Starting transcription...');
      debugPrint('📁 File: ${audioFile.path}');
      debugPrint('📊 Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      debugPrint('🌍 Language: $language');

      // Check cache first
      if (useCache) {
        final cacheKey = await _generateCacheKey(audioFile);
        final cachedTranscription = await _cacheService.get<String>(cacheKey);

        if (cachedTranscription != null) {
          debugPrint('✅ Using cached transcription');
          return cachedTranscription;
        }
      }

      // Transcribe with OpenAI
      final transcription = await _openAIService.transcribeAudio(
        audioFile: audioFile,
        language: language,
      );

      if (transcription == null || transcription.isEmpty) {
        debugPrint('❌ Transcription failed');
        throw Exception('Ses dosyası metne çevrilemedi');
      }

      debugPrint('✅ Transcription successful');
      debugPrint('📝 Length: ${transcription.length} characters');

      // Cache the transcription
      if (useCache) {
        final cacheKey = await _generateCacheKey(audioFile);
        await _cacheService.put(
          cacheKey,
          transcription,
          ttl: const Duration(days: 7), // Cache for 7 days
        );
      }

      return transcription;
    } catch (e) {
      debugPrint('❌ Transcription error: $e');
      rethrow;
    }
  }

  /// Transcribe audio and provide real-time callback
  ///
  /// Useful for showing loading states
  Future<String?> transcribeWithCallback({
    required File audioFile,
    required Function(TranscriptionStatus status, String? data) onStatusChange,
    String language = 'tr',
    bool useCache = true,
  }) async {
    try {
      onStatusChange(TranscriptionStatus.validating, null);

      // Validate file
      if (!audioFile.existsSync()) {
        onStatusChange(TranscriptionStatus.failed, 'Ses dosyası bulunamadı');
        throw Exception('Ses dosyası bulunamadı');
      }

      final fileSize = audioFile.lengthSync();
      if (fileSize < 1000) {
        onStatusChange(TranscriptionStatus.failed, 'Ses dosyası çok kısa');
        throw Exception('Ses dosyası çok kısa veya bozuk');
      }

      // Check cache
      if (useCache) {
        onStatusChange(TranscriptionStatus.checkingCache, null);

        final cacheKey = await _generateCacheKey(audioFile);
        final cachedTranscription = await _cacheService.get<String>(cacheKey);

        if (cachedTranscription != null) {
          onStatusChange(TranscriptionStatus.completed, cachedTranscription);
          return cachedTranscription;
        }
      }

      // Transcribe
      onStatusChange(TranscriptionStatus.transcribing, null);

      final transcription = await _openAIService.transcribeAudio(
        audioFile: audioFile,
        language: language,
      );

      if (transcription == null || transcription.isEmpty) {
        onStatusChange(TranscriptionStatus.failed, 'Transkripsiyon başarısız');
        throw Exception('Ses dosyası metne çevrilemedi');
      }

      // Cache
      if (useCache) {
        final cacheKey = await _generateCacheKey(audioFile);
        await _cacheService.put(
          cacheKey,
          transcription,
          ttl: const Duration(days: 7),
        );
      }

      onStatusChange(TranscriptionStatus.completed, transcription);
      return transcription;
    } catch (e) {
      onStatusChange(TranscriptionStatus.failed, e.toString());
      rethrow;
    }
  }

  /// Validate audio file format
  Future<bool> validateAudioFile(File audioFile) async {
    try {
      if (!audioFile.existsSync()) {
        return false;
      }

      final bytes = await audioFile.readAsBytes();

      if (bytes.length < 100) {
        debugPrint('❌ File too small to be valid audio');
        return false;
      }

      // Check M4A/AAC signature
      if (bytes.length >= 8) {
        final signature = String.fromCharCodes(bytes.sublist(4, 8));
        if (signature == 'ftyp') {
          debugPrint('✅ Valid M4A/AAC file format');
          return true;
        }
      }

      // Check WAV signature
      if (bytes.length >= 4) {
        final signature = String.fromCharCodes(bytes.sublist(0, 4));
        if (signature == 'RIFF') {
          debugPrint('✅ Valid WAV file format');
          return true;
        }
      }

      debugPrint('⚠️ Could not verify file format, but size seems ok');
      return true;
    } catch (e) {
      debugPrint('❌ Audio validation error: $e');
      return false;
    }
  }

  /// Generate cache key based on file content hash
  Future<String> _generateCacheKey(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes);
      return 'transcription_${hash.toString()}';
    } catch (e) {
      debugPrint('❌ Cache key generation error: $e');
      // Fallback to file path hash
      final hash = sha256.convert(utf8.encode(file.path));
      return 'transcription_${hash.toString()}';
    }
  }

  /// Clear all transcription cache
  Future<void> clearCache() async {
    debugPrint('🗑️ Clearing transcription cache...');
    // This will clear all cache, including transcriptions
    // In a more advanced implementation, we could have a prefix-based clear
    await _cacheService.clearExpired();
  }
}

/// Transcription status for callbacks
enum TranscriptionStatus {
  validating,
  checkingCache,
  transcribing,
  completed,
  failed,
}

/// Extension for user-friendly status messages
extension TranscriptionStatusMessage on TranscriptionStatus {
  String get message {
    switch (this) {
      case TranscriptionStatus.validating:
        return 'Ses dosyası kontrol ediliyor...';
      case TranscriptionStatus.checkingCache:
        return 'Önbellek kontrol ediliyor...';
      case TranscriptionStatus.transcribing:
        return 'Ses metne çevriliyor...';
      case TranscriptionStatus.completed:
        return 'Tamamlandı!';
      case TranscriptionStatus.failed:
        return 'Hata oluştu';
    }
  }
}
