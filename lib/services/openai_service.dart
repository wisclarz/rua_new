import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/openai_config.dart';

class OpenAIService {
  // API key'i config dosyasından al
  static String get _apiKey => OpenAIConfig.apiKey;
  static const String _transcriptionEndpoint = 'https://api.openai.com/v1/audio/transcriptions';
  
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: OpenAIConfig.connectTimeout),
      receiveTimeout: Duration(seconds: OpenAIConfig.receiveTimeout),
      sendTimeout: Duration(seconds: OpenAIConfig.sendTimeout),
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
    String? language,
    String? model,
  }) async {
    try {
      final lang = language ?? OpenAIConfig.defaultLanguage;
      final mdl = model ?? OpenAIConfig.whisperModel;
      
      debugPrint('🎙️ Starting OpenAI transcription...');
      debugPrint('📁 File: ${audioFile.path}');
      debugPrint('🌍 Language: $lang');
      debugPrint('🤖 Model: $mdl');

      // Dosya kontrolü
      if (!audioFile.existsSync()) {
        debugPrint('❌ Audio file does not exist');
        return null;
      }

      final fileSize = audioFile.lengthSync();
      debugPrint('📊 File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // API key kontrolü
      if (!OpenAIConfig.isConfigured()) {
        debugPrint('❌ OpenAI API key not configured');
        return null;
      }

      debugPrint('🔑 Using API key: ${OpenAIConfig.getMaskedKey()}');

      // Multipart form data oluştur
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
        'model': mdl,
        'language': lang,
        'response_format': OpenAIConfig.responseFormat,
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

  /// API key'in yapılandırılıp yapılandırılmadığını kontrol eder
  bool isConfigured() {
    return OpenAIConfig.isConfigured();
  }
}
