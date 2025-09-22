import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class N8nService {
  // TODO: Bu URL'leri Firebase Remote Config veya production ortamında environment variables ile değiştirin
  static const String _baseUrl = 'https://your-n8n-instance.com'; // Replace with your n8n URL
  static const String _webhookUrl = '$_baseUrl/webhook/dream-analysis';

  // Trigger dream analysis via n8n webhook
  Future<bool> triggerDreamAnalysis(String dreamId, String audioUrl) async {
    try {
      final Map<String, dynamic> payload = {
        'dreamId': dreamId,
        'audioUrl': audioUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'analyze_dream',
      };

      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('n8n webhook triggered successfully');
        return true;
      } else {
        debugPrint('n8n webhook failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('n8n webhook error: $e');
      return false;
    }
  }

  // Test n8n webhook connection
  Future<Map<String, dynamic>?> testWebhookConnection() async {
    try {
      final Map<String, dynamic> testPayload = {
        'test': true,
        'message': 'Test connection from Flutter app',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(testPayload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        debugPrint('n8n test webhook successful: $responseData');
        return responseData;
      } else {
        debugPrint('n8n test webhook failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('n8n test webhook error: $e');
      return null;
    }
  }

  // Get available AI models (example endpoint)
  Future<List<String>> getAvailableModels() async {
    try {
      final String modelsUrl = '$_baseUrl/webhook/available-models';
      
      final response = await http.get(
        Uri.parse(modelsUrl),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> models = responseData['models'] ?? [];
        return models.cast<String>();
      } else {
        debugPrint('Failed to get available models: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Get available models error: $e');
      return [];
    }
  }

  // Send feedback about analysis
  Future<bool> sendAnalysisFeedback(String dreamId, bool isHelpful, String? feedback) async {
    try {
      final String feedbackUrl = '$_baseUrl/webhook/analysis-feedback';
      
      final Map<String, dynamic> payload = {
        'dreamId': dreamId,
        'isHelpful': isHelpful,
        'feedback': feedback,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse(feedbackUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Send feedback error: $e');
      return false;
    }
  }
}
