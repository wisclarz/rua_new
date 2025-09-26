import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:rua_new/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
class N8nService {
  // N8N configuration - URL'leri düzelttik
  static const String _baseUrl = 'https://wisclarz.app.n8n.cloud'; 
  static const String _webhookUrl = 'https://wisclarz.app.n8n.cloud/webhook/dream-analysis'; // Ekran görüntüsünden tam URL
  static const String _completionWebhookUrl = '$_baseUrl/webhook/dream-completion';
  
  // Headers
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'DreamyApp/1.0.0',
  };

  // Trigger dream analysis via n8n webhook
  Future<bool> triggerDreamAnalysis(String dreamId, String audioUrl) async {
  try {
    debugPrint('🚀 Triggering N8N dream analysis for: $dreamId');
    debugPrint('📡 Webhook URL: $_webhookUrl');
    
    // 🔥 Firebase Authentication - ZORUNLU
    final user = FirebaseAuthService().currentUser;
    if (user == null) {
      debugPrint('❌ User not authenticated');
      return false;
    }
    
    // Firebase ID Token al
    final String idToken = await user.getIdTokenResult().then((value) => value.token ?? '');
    debugPrint('🔑 Got Firebase ID token for user: ${user.uid}');
    
    final Map<String, dynamic> payload = {
      'dreamId': dreamId,
      'audioUrl': audioUrl,
      'userId': user.uid,  // ✅ UserId eklendi
      'idToken': idToken,  // ✅ Firebase ID Token eklendi
      'timestamp': DateTime.now().toIso8601String(),
      'action': 'analyze_dream',
      'workflow': 'dream_analysis_v1',
      'version': '1.0.0',
      // OpenAI configuration
      'openai_config': {
        'model': 'whisper-1', // For speech-to-text
        'language': 'tr', // Turkish language for Whisper
        'gpt_model': 'gpt-4o-mini', // For dream analysis
        'max_tokens': 2000,
        'temperature': 0.7,
      },
      // Firebase config for callback
      'callback_config': {
        'firebase_project': 'dreamy-app-2025',
        'collection': 'dreams',
        'document_id': dreamId,
      },
      // Debug info
      'debug': {
        'client': 'flutter_app',
        'platform': defaultTargetPlatform.name,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'user_id': user.uid, // Debug için user ID
      }
    };

    debugPrint('📤 Payload keys: ${payload.keys.join(', ')}');
    // ID Token'ı log'a yazmayalım (güvenlik)
    debugPrint('📤 UserId: ${user.uid}');

    final response = await http.post(
      Uri.parse(_webhookUrl),
      headers: _headers,
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 30));

    debugPrint('📥 Response status: ${response.statusCode}');
    debugPrint('📥 Response headers: ${response.headers}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('✅ N8N webhook triggered successfully');
      try {
        final responseData = jsonDecode(response.body);
        debugPrint('📥 Response: $responseData');
      } catch (e) {
        debugPrint('📥 Response (raw): ${response.body}');
      }
      return true;
    } else {
      debugPrint('❌ N8N webhook failed: ${response.statusCode}');
      debugPrint('❌ Error body: ${response.body}');
      debugPrint('❌ Error headers: ${response.headers}');
      return false;
    }
  } catch (e) {
    debugPrint('💥 N8N webhook error: $e');
    debugPrint('💥 Stack trace: ${StackTrace.current}');
    return false;
  }
}

  Future<bool> triggerDreamAnalysisWithUser({
  required String dreamId,
  required String audioUrl,
  required firebase_auth.User user,
}) async {
  try {
    debugPrint('🚀 Triggering N8N dream analysis for: $dreamId');
    debugPrint('📡 Webhook URL: $_webhookUrl');
    debugPrint('👤 User ID: ${user.uid}');
    
    // ID Token al - user direkt geçildiği için hata olması daha az
    String idToken = '';
    try {
      idToken = await user.getIdTokenResult().then((result) => result.token ?? '');
      debugPrint('🔑 ID Token length: ${idToken.length} characters');
    } catch (tokenError) {
      debugPrint('⚠️ ID Token error: $tokenError - continuing without token');
    }
    
    final Map<String, dynamic> payload = {
      'dreamId': dreamId,
      'audioUrl': audioUrl,
      'userId': user.uid,        // Direkt user'dan
      'idToken': idToken,        // Token var veya boş
      'timestamp': DateTime.now().toIso8601String(),
      'action': 'analyze_dream',
      'workflow': 'dream_analysis_v1',
      'version': '1.0.0',
      // OpenAI configuration
      'openai_config': {
        'model': 'whisper-1',
        'language': 'tr',
        'gpt_model': 'gpt-4o-mini',
        'max_tokens': 2000,
        'temperature': 0.7,
      },
      // Firebase config for callback
      'callback_config': {
        'firebase_project': 'dreamy-app-2025',
        'collection': 'dreams',
        'document_id': dreamId,
      },
      // Debug info
      'debug': {
        'client': 'flutter_app',
        'platform': defaultTargetPlatform.name,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'user_id': user.uid,
      }
    };

    // Debug payload
    debugPrint('📤 Sending userId: ${payload['userId']}');
    debugPrint('📤 IdToken present: ${payload['idToken'].toString().isNotEmpty}');

    final response = await http.post(
      Uri.parse(_webhookUrl),
      headers: _headers,
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 30));

    debugPrint('📥 Response status: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('✅ N8N webhook triggered successfully');
      try {
        final responseData = jsonDecode(response.body);
        debugPrint('📥 Response: $responseData');
      } catch (e) {
        debugPrint('📥 Response (raw): ${response.body}');
      }
      return true;
    } else {
      debugPrint('❌ N8N webhook failed: ${response.statusCode}');
      debugPrint('❌ Error body: ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('💥 N8N webhook error: $e');
    return false;
  }
}
  // Alternative webhook endpoints for testing
  Future<bool> triggerDreamAnalysisAlternative(String dreamId, String audioUrl) async {
    try {
      // Production webhook URL'si
      const String prodWebhookUrl = '$_baseUrl/webhook-prod/dream-analysis';
      debugPrint('🚀 Trying production webhook: $prodWebhookUrl');
      
      final Map<String, dynamic> payload = {
        'dreamId': dreamId,
        'audioUrl': audioUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'analyze_dream',
        'environment': 'production',
      };

      final response = await http.post(
        Uri.parse(prodWebhookUrl),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Production webhook successful');
        return true;
      } else {
        debugPrint('❌ Production webhook failed: ${response.statusCode}');
        
        // Test webhook'u dene
        return await _tryTestWebhook(dreamId, audioUrl);
      }
    } catch (e) {
      debugPrint('💥 Alternative webhook error: $e');
      return await _tryTestWebhook(dreamId, audioUrl);
    }
  }

  // Test webhook deneme
  Future<bool> _tryTestWebhook(String dreamId, String audioUrl) async {
    try {
      const String testWebhookUrl = '$_baseUrl/webhook-test/dream-analysis';
      debugPrint('🧪 Trying test webhook: $testWebhookUrl');
      
      final Map<String, dynamic> payload = {
        'dreamId': dreamId,
        'audioUrl': audioUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'analyze_dream',
        'environment': 'test',
      };

      final response = await http.post(
        Uri.parse(testWebhookUrl),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      final success = response.statusCode == 200 || response.statusCode == 201;
      debugPrint(success ? '✅ Test webhook successful' : '❌ Test webhook failed: ${response.statusCode}');
      
      if (!success) {
        debugPrint('❌ Test webhook error body: ${response.body}');
      }
      
      return success;
    } catch (e) {
      debugPrint('💥 Test webhook error: $e');
      return false;
    }
  }

  // Test n8n webhook connection with multiple endpoints
  Future<Map<String, dynamic>?> testWebhookConnection() async {
    debugPrint('🧪 Testing N8N webhook connection...');
    
    final List<String> testUrls = [
      '$_baseUrl/webhook/dream-analysis',
      '$_baseUrl/webhook-prod/dream-analysis', 
      '$_baseUrl/webhook-test/dream-analysis',
      '$_baseUrl/webhook/test',
      '$_baseUrl/test',
    ];
    
    final Map<String, dynamic> testPayload = {
      'test': true,
      'message': 'Test connection from Flutter app',
      'timestamp': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
      'platform': defaultTargetPlatform.name,
    };

    for (String testUrl in testUrls) {
      try {
        debugPrint('🔍 Testing URL: $testUrl');
        
        final response = await http.post(
          Uri.parse(testUrl),
          headers: _headers,
          body: jsonEncode(testPayload),
        ).timeout(const Duration(seconds: 10));

        debugPrint('📊 $testUrl - Status: ${response.statusCode}');
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('✅ Webhook test successful for: $testUrl');
          try {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            return {
              'success': true,
              'working_url': testUrl,
              'status_code': response.statusCode,
              'response': responseData,
              'latency_ms': DateTime.now().millisecondsSinceEpoch,
            };
          } catch (e) {
            return {
              'success': true,
              'working_url': testUrl,
              'status_code': response.statusCode,
              'response': response.body,
              'latency_ms': DateTime.now().millisecondsSinceEpoch,
            };
          }
        } else {
          debugPrint('❌ $testUrl failed with status: ${response.statusCode}');
          debugPrint('❌ Response: ${response.body}');
        }
      } catch (e) {
        debugPrint('💥 Error testing $testUrl: $e');
        continue;
      }
    }
    
    return {
      'success': false,
      'error': 'Hiçbir webhook endpoint çalışmıyor',
      'tested_urls': testUrls,
    };
  }

  // Handle completion webhook (called by N8N when analysis is complete)
  Future<Map<String, dynamic>?> handleCompletionWebhook(Map<String, dynamic> data) async {
    try {
      debugPrint('🎯 Handling completion webhook: $data');
      
      // Validate required fields
      if (!data.containsKey('dreamId') || 
          !data.containsKey('dreamText') || 
          !data.containsKey('analysis')) {
        debugPrint('❌ Missing required fields in completion webhook');
        return null;
      }

      // Return processed data
      return {
        'dreamId': data['dreamId'],
        'dreamText': data['dreamText'],
        'analysis': data['analysis'],
        'mood': data['mood'] ?? 'Belirsiz',
        'title': data['title'] ?? _generateTitle(data['dreamText']),
        'confidence': data['confidence'] ?? 0.8,
        'processing_time': data['processing_time'] ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'completed',
      };
    } catch (e) {
      debugPrint('💥 Error handling completion webhook: $e');
      return null;
    }
  }

  // Send feedback about analysis quality
  Future<bool> sendAnalysisFeedback({
    required String dreamId,
    required bool isHelpful,
    String? feedback,
    int? rating,
  }) async {
    try {
      debugPrint('📝 Sending feedback for dream: $dreamId');
      
      final String feedbackUrl = '$_baseUrl/webhook/analysis-feedback';
      
      final Map<String, dynamic> payload = {
        'dreamId': dreamId,
        'isHelpful': isHelpful,
        'feedback': feedback,
        'rating': rating,
        'timestamp': DateTime.now().toIso8601String(),
        'user_agent': 'flutter_app_v1.0.0',
      };

      final response = await http.post(
        Uri.parse(feedbackUrl),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      final success = response.statusCode == 200 || response.statusCode == 201;
      debugPrint(success ? '✅ Feedback sent successfully' : '❌ Failed to send feedback: ${response.statusCode}');
      
      if (!success) {
        debugPrint('❌ Feedback error: ${response.body}');
      }
      
      return success;
    } catch (e) {
      debugPrint('💥 Send feedback error: $e');
      return false;
    }
  }

  // Get workflow status
  Future<Map<String, dynamic>?> getWorkflowStatus(String dreamId) async {
    try {
      final String statusUrl = '$_baseUrl/webhook/workflow-status?dreamId=$dreamId';
      debugPrint('📊 Getting workflow status from: $statusUrl');
      
      final response = await http.get(
        Uri.parse(statusUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Workflow status retrieved: $data');
        return data;
      } else {
        debugPrint('❌ Failed to get workflow status: ${response.statusCode}');
        debugPrint('❌ Status error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 Get workflow status error: $e');
      return null;
    }
  }

  // Retry failed analysis with exponential backoff
  Future<bool> retryAnalysis(String dreamId, String audioUrl, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 Retrying analysis for dream: $dreamId (attempt $attempt/$maxRetries)');
        
        final Map<String, dynamic> payload = {
          'dreamId': dreamId,
          'audioUrl': audioUrl,
          'timestamp': DateTime.now().toIso8601String(),
          'action': 'retry_analysis',
          'retry': true,
          'attempt': attempt,
          'max_attempts': maxRetries,
        };

        final response = await http.post(
          Uri.parse(_webhookUrl),
          headers: _headers,
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('✅ Retry successful on attempt $attempt');
          return true;
        } else {
          debugPrint('❌ Retry attempt $attempt failed: ${response.statusCode}');
          
          if (attempt < maxRetries) {
            // Exponential backoff
            final delaySeconds = attempt * 2;
            debugPrint('⏳ Waiting ${delaySeconds}s before next attempt...');
            await Future.delayed(Duration(seconds: delaySeconds));
          }
        }
      } catch (e) {
        debugPrint('💥 Retry attempt $attempt error: $e');
        
        if (attempt < maxRetries) {
          final delaySeconds = attempt * 2;
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }
    }
    
    debugPrint('❌ All retry attempts failed');
    return false;
  }

  // Private helper methods
  String _generateTitle(String dreamText) {
    if (dreamText.isEmpty) return 'Başlıksız Rüya';
    
    final words = dreamText.split(' ');
    if (words.length <= 5) return dreamText;
    
    return '${words.take(5).join(' ')}...';
  }
}