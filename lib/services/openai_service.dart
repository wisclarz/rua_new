import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class OpenAIService {
  // API key'i environment variable'dan veya Firebase Remote Config'den alın
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String _transcriptionEndpoint = 'https://api.openai.com/v1/audio/transcriptions';
  
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ),
  );

  /// Ses dosyasını OpenAI Whisper API ile metne çevirir
  /// 
  /// [audioFile]: Transkribe edilecek ses dosyası
  /// [language]: Ses dosyasının dili (default: 'tr' - Türkçe)
  /// [model]: Kullanılacak model (default: 'whisper-1')
  /// 
  /// Returns: Transkribe edilmiş metin veya null (hata durumunda)
  Future<String?> transcribeAudio({
    required File audioFile,
    String language = 'tr',
    String model = 'whisper-1',
  }) async {
    try {
      debugPrint('🎙️ Starting OpenAI transcription...');
      debugPrint('📁 File: ${audioFile.path}');
      debugPrint('🌍 Language: $language');
      debugPrint('🤖 Model: $model');

      // Dosya kontrolü
      if (!audioFile.existsSync()) {
        debugPrint('❌ Audio file does not exist');
        return null;
      }

      final fileSize = audioFile.lengthSync();
      debugPrint('📊 File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // API key kontrolü (placeholder kontrolü kaldırıldı - artık gerçek key var)

      // Multipart form data oluştur
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
        'model': model,
        'language': language,
        'response_format': 'text', // Sadece metin dönsün
      });

      debugPrint('📤 Sending request to OpenAI...');

      // OpenAI API'ye istek gönder
      final response = await _dio.post(
        _transcriptionEndpoint,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
        ),
      );

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final transcription = response.data.toString().trim();
        
        if (transcription.isNotEmpty) {
          debugPrint('✅ Transcription successful!');
          debugPrint('📝 Preview: ${transcription.substring(0, transcription.length > 100 ? 100 : transcription.length)}...');
          return transcription;
        } else {
          debugPrint('❌ Empty transcription received');
          return null;
        }
      } else {
        debugPrint('❌ Unexpected status code: ${response.statusCode}');
        debugPrint('❌ Response: ${response.data}');
        return null;
      }
    } on DioException catch (e) {
      debugPrint('❌ DioException during transcription: ${e.type}');
      debugPrint('❌ Message: ${e.message}');
      debugPrint('❌ Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        debugPrint('❌ Authentication failed. Check your API key.');
      } else if (e.response?.statusCode == 429) {
        debugPrint('❌ Rate limit exceeded. Please try again later.');
      }
      
      return null;
    } catch (e) {
      debugPrint('💥 Unexpected error during transcription: $e');
      return null;
    }
  }

  /// Ses dosyasını URL'den indirip transkribe eder
  /// 
  /// [audioUrl]: İndirilecek ses dosyasının URL'i
  /// [language]: Ses dosyasının dili (default: 'tr' - Türkçe)
  /// 
  /// Returns: Transkribe edilmiş metin veya null (hata durumunda)
  Future<String?> transcribeAudioFromUrl({
    required String audioUrl,
    String language = 'tr',
  }) async {
    try {
      debugPrint('🌐 Downloading audio from URL: $audioUrl');

      // Geçici dosya oluştur
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.m4a');

      // Ses dosyasını indir
      await _dio.download(audioUrl, tempFile.path);
      debugPrint('✅ Audio downloaded to: ${tempFile.path}');

      // Transkribe et
      final transcription = await transcribeAudio(
        audioFile: tempFile,
        language: language,
      );

      // Geçici dosyayı sil
      try {
        await tempFile.delete();
        debugPrint('🗑️ Temporary file deleted');
      } catch (e) {
        debugPrint('⚠️ Could not delete temp file: $e');
      }

      return transcription;
    } catch (e) {
      debugPrint('💥 Error transcribing from URL: $e');
      return null;
    }
  }

  /// API key'in yapılandırılıp yapılandırılmadığını kontrol eder
  bool isConfigured() {
    return _apiKey != 'YOUR_OPENAI_API_KEY_HERE' && _apiKey.isNotEmpty;
  }
}

