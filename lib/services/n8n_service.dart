import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class N8nService {
  // TODO: Bu URL'leri gerçek n8n instance URL'niz ile değiştirin
  static const String _baseUrl = 'https://wisclarz.app.n8n.cloud/'; // N8N sunucunuzun URL'si
  static const String _webhookUrl = 'https://wisclarz.app.n8n.cloud/webhook-test/dream-analysis';
  static const String _completionWebhookUrl = '$_baseUrl/webhook-test/dream-completion';
  
  // Headers
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Trigger dream analysis via n8n webhook
  Future<bool> triggerDreamAnalysis(String dreamId, String audioUrl) async {
    try {
      debugPrint('🚀 Triggering N8N dream analysis for: $dreamId');
      
      final Map<String, dynamic> payload = {
        'dreamId': dreamId,
        'audioUrl': audioUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'analyze_dream',
        'workflow': 'dream_analysis_v1',
        // OpenAI configuration
        'openai_config': {
          'model': 'whisper-1', // For speech-to-text
          'gpt_model': 'gpt-4', // For dream analysis
          'max_tokens': 1000,
          'temperature': 0.7,
        },
        // Firebase config for callback
        'callback_config': {
          'firebase_project': 'dreamy-app-2025',
          'collection': 'dreams',
          'document_id': dreamId,
        }
      };

      debugPrint('📤 Payload: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ N8N webhook triggered successfully');
        final responseData = jsonDecode(response.body);
        debugPrint('📥 Response: $responseData');
        return true;
      } else {
        debugPrint('❌ N8N webhook failed: ${response.statusCode}');
        debugPrint('Error body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('💥 N8N webhook error: $e');
      return false;
    }
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
      };
    } catch (e) {
      debugPrint('💥 Error handling completion webhook: $e');
      return null;
    }
  }

  // Test n8n webhook connection
  Future<Map<String, dynamic>?> testWebhookConnection() async {
    try {
      debugPrint('🧪 Testing N8N webhook connection...');
      
      final Map<String, dynamic> testPayload = {
        'test': true,
        'message': 'Test connection from Flutter app',
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'platform': defaultTargetPlatform.name,
      };

      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: _headers,
        body: jsonEncode(testPayload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        debugPrint('✅ N8N test webhook successful: $responseData');
        return {
          'success': true,
          'status_code': response.statusCode,
          'response': responseData,
          'latency_ms': DateTime.now().millisecondsSinceEpoch,
        };
      } else {
        debugPrint('❌ N8N test webhook failed: ${response.statusCode}');
        debugPrint('Error body: ${response.body}');
        return {
          'success': false,
          'status_code': response.statusCode,
          'error': response.body,
        };
      }
    } catch (e) {
      debugPrint('💥 N8N test webhook error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
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
      debugPrint(success ? '✅ Feedback sent successfully' : '❌ Failed to send feedback');
      
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
      
      final response = await http.get(
        Uri.parse(statusUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('❌ Failed to get workflow status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 Get workflow status error: $e');
      return null;
    }
  }

  // Retry failed analysis
  Future<bool> retryAnalysis(String dreamId, String audioUrl) async {
    try {
      debugPrint('🔄 Retrying analysis for dream: $dreamId');
      
      final Map<String, dynamic> payload = {
        'dreamId': dreamId,
        'audioUrl': audioUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'retry_analysis',
        'retry': true,
      };

      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('💥 Retry analysis error: $e');
      return false;
    }
  }

  // Private helper methods
  String _generateTitle(String dreamText) {
    if (dreamText.isEmpty) return 'Başlıksız Rüya';
    
    final words = dreamText.split(' ');
    if (words.length <= 5) return dreamText;
    
    return '${words.take(5).join(' ')}...';
  }
}