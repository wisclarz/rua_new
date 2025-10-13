import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cache_service.dart';

/// N8N Service (Refactored)
///
/// SOLID Principles:
/// - Single Responsibility: Sadece N8N webhook işlemlerini yönetir
/// - Dependency Injection: Firestore ve Cache inject edilir
/// - Open/Closed: Yeni workflow'lar eklenebilir
///
/// Improvements:
/// - Shorter methods (< 50 lines each)
/// - Cache integration for previous dreams
/// - Better error handling
/// - Configuration injection
class N8nService {
  final String webhookUrl;
  final Map<String, String> headers;
  final FirebaseFirestore _firestore;
  final CacheService _cacheService;

  N8nService({
    String? webhookUrl,
    Map<String, String>? headers,
    FirebaseFirestore? firestore,
    CacheService? cacheService,
  })  : webhookUrl = webhookUrl ??
            'https://dreamdemoo.app.n8n.cloud/webhook/bf22088f-6627-4593-85b6-8dc112767901',
        headers = headers ??
            const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'DreamyApp/1.0.0',
            },
        _firestore = firestore ?? FirebaseFirestore.instance,
        _cacheService = cacheService ?? CacheService.instance;

  /// Transcribe audio only (no analysis)
  Future<String?> transcribeAudioOnly({
    required String audioUrl,
    required firebase_auth.User user,
  }) async {
    try {
      debugPrint('🎙️ Starting transcription-only for audio: $audioUrl');

      final idToken = await _getIdToken(user);
      final payload = _createTranscriptionPayload(
        audioUrl: audioUrl,
        userId: user.uid,
        idToken: idToken,
      );

      final response = await _sendRequest(payload, timeout: 45);

      if (_isSuccessResponse(response)) {
        return _extractTranscription(response);
      }

      debugPrint('❌ Transcription request failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('💥 Transcription error: $e');
      return null;
    }
  }

  /// Trigger dream analysis with history
  Future<Map<String, dynamic>?> triggerDreamAnalysisWithHistory({
    required String dreamId,
    String? audioUrl,
    String? dreamText,
    required firebase_auth.User user,
  }) async {
    try {
      final inputType = audioUrl != null ? 'voice' : 'text';
      debugPrint('🚀 Starting $inputType dream analysis for: $dreamId');

      final idToken = await _getIdToken(user);
      final previousDreams = await _fetchPreviousDreamsWithCache(
        user.uid,
        dreamId,
      );

      final payload = _createAnalysisPayload(
        dreamId: dreamId,
        userId: user.uid,
        idToken: idToken,
        audioUrl: audioUrl,
        dreamText: dreamText,
        previousDreams: previousDreams,
      );

      final response = await _sendRequest(payload, timeout: 60);

      if (_isSuccessResponse(response)) {
        return _parseAnalysisResponse(response);
      }

      debugPrint('❌ N8N webhook failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('💥 N8N webhook error: $e');
      return null;
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Get Firebase ID token for authentication
  Future<String> _getIdToken(firebase_auth.User user) async {
    try {
      final idToken = await user.getIdTokenResult().then((result) => result.token ?? '');
      debugPrint('🔑 ID Token retrieved');
      return idToken;
    } catch (e) {
      debugPrint('⚠️ ID Token error: $e');
      return '';
    }
  }

  /// Create transcription-only payload
  Map<String, dynamic> _createTranscriptionPayload({
    required String audioUrl,
    required String userId,
    required String idToken,
  }) {
    return {
      'audioUrl': audioUrl,
      'userId': userId,
      'idToken': idToken,
      'action': 'transcribe_only',
      'timestamp': DateTime.now().toIso8601String(),
      'openai_config': {
        'model': 'whisper-1',
        'language': 'tr',
      },
      'debug': {
        'client': 'flutter_app',
        'platform': defaultTargetPlatform.name,
        'action': 'transcribe_only',
      }
    };
  }

  /// Create analysis payload
  Map<String, dynamic> _createAnalysisPayload({
    required String dreamId,
    required String userId,
    required String idToken,
    String? audioUrl,
    String? dreamText,
    required List<Map<String, dynamic>> previousDreams,
  }) {
    final inputType = audioUrl != null ? 'voice' : 'text';

    final payload = {
      'dreamId': dreamId,
      'userId': userId,
      'idToken': idToken,
      'inputType': inputType,
      'action': 'analyze_dream',
      'timestamp': DateTime.now().toIso8601String(),
      'workflow': 'dream_analysis_v2',
      'version': '2.0.0',
      'hasPreviousDreams': previousDreams.isNotEmpty,
      'previousDreams': previousDreams,
      'previousDreamsCount': previousDreams.length,
      'debug': {
        'client': 'flutter_app',
        'platform': defaultTargetPlatform.name,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'user_id': userId,
        'has_history': previousDreams.isNotEmpty,
        'input_type': inputType,
      }
    };

    if (audioUrl != null) {
      payload['audioUrl'] = audioUrl;
      payload['openai_config'] = {
        'model': 'whisper-1',
        'language': 'tr',
        'gpt_model': 'gpt-5-mini-2025-08-07',
      };
    }

    if (dreamText != null) {
      payload['dreamText'] = dreamText;
      payload['openai_config'] = {
        'gpt_model': 'gpt-5-mini-2025-08-07',
        'language': 'tr',
      };
      (payload['debug'] as Map<String, dynamic>)['text_length'] = dreamText.length;
    }

    return payload;
  }

  /// Send HTTP request to webhook
  Future<http.Response> _sendRequest(
    Map<String, dynamic> payload, {
    int timeout = 60,
  }) async {
    debugPrint('📤 Sending request to N8N webhook...');

    return await http.post(
      Uri.parse(webhookUrl),
      headers: headers,
      body: jsonEncode(payload),
    ).timeout(Duration(seconds: timeout));
  }

  /// Check if response is successful
  bool _isSuccessResponse(http.Response response) {
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Extract transcription from response
  String? _extractTranscription(http.Response response) {
    try {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final transcription = responseData['transcription'] ?? responseData['dreamText'];

      if (transcription != null && transcription.toString().isNotEmpty) {
        final text = transcription.toString();
        debugPrint('✅ Transcription received: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
        return text;
      }

      debugPrint('❌ Empty transcription in response');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to parse transcription: $e');
      return null;
    }
  }

  /// Parse analysis response
  Map<String, dynamic>? _parseAnalysisResponse(http.Response response) {
    try {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('📥 Analysis received from N8N');
      return responseData;
    } catch (e) {
      debugPrint('❌ Failed to parse N8N response: $e');
      debugPrint('📥 Raw response: ${response.body}');
      return null;
    }
  }

  /// Fetch previous dreams with cache
  Future<List<Map<String, dynamic>>> _fetchPreviousDreamsWithCache(
    String userId,
    String currentDreamId,
  ) async {
    final cacheKey = 'previous_dreams_$userId';

    // Try cache first
    final cachedDreams = await _cacheService.get<List<dynamic>>(cacheKey);
    if (cachedDreams != null) {
      debugPrint('✅ Using cached previous dreams (${cachedDreams.length})');
      return cachedDreams.cast<Map<String, dynamic>>();
    }

    // Fetch from Firestore
    final dreams = await _fetchPreviousDreams(userId, currentDreamId);

    // Cache for 10 minutes
    if (dreams.isNotEmpty) {
      await _cacheService.put(
        cacheKey,
        dreams,
        ttl: const Duration(minutes: 10),
      );
    }

    return dreams;
  }

  /// Fetch previous dreams from Firestore
  Future<List<Map<String, dynamic>>> _fetchPreviousDreams(
    String userId,
    String currentDreamId,
  ) async {
    try {
      debugPrint('📚 Fetching previous dreams for user: $userId');

      final snapshot = await _queryCompletedDreams(userId);

      if (snapshot.docs.isEmpty) {
        debugPrint('📚 No completed dreams found');
        return [];
      }

      return _processDreamsSnapshot(snapshot, currentDreamId);
    } catch (e) {
      debugPrint('💥 Error fetching previous dreams: $e');
      return [];
    }
  }

  /// Query completed dreams from Firestore
  Future<QuerySnapshot> _queryCompletedDreams(String userId) async {
    try {
      // Try with createdAt ordering
      return await _firestore
          .collection('dreams')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .limit(6)
          .get();
    } catch (e) {
      debugPrint('⚠️ createdAt query failed: $e');

      try {
        // Fallback: Try with timestamp
        return await _firestore
            .collection('dreams')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'completed')
            .orderBy('timestamp', descending: true)
            .limit(6)
            .get();
      } catch (e2) {
        debugPrint('⚠️ timestamp query failed: $e2');

        // Fallback: No ordering
        return await _firestore
            .collection('dreams')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'completed')
            .limit(6)
            .get();
      }
    }
  }

  /// Process dreams snapshot into list
  List<Map<String, dynamic>> _processDreamsSnapshot(
    QuerySnapshot snapshot,
    String currentDreamId,
  ) {
    final List<Map<String, dynamic>> previousDreams = [];

    for (var doc in snapshot.docs) {
      if (doc.id == currentDreamId) {
        debugPrint('⏭️ Skipping current dream: $currentDreamId');
        continue;
      }

      final data = doc.data() as Map<String, dynamic>;
      final dreamText = data['dreamText'] ?? '';

      if (dreamText.isEmpty) {
        debugPrint('⏭️ Skipping dream without dreamText: ${doc.id}');
        continue;
      }

      previousDreams.add({
        'dreamId': doc.id,
        'dreamText': dreamText,
        'title': data['title'] ?? '',
        'mood': data['mood'] ?? '',
        'symbols': data['symbols'] ?? [],
        'interpretation': data['interpretation'] ?? '',
        'analysis': data['analysis'] ?? '',
        'timestamp': data['timestamp']?.toString() ??
            data['createdAt']?.toString() ??
            '',
      });

      debugPrint('✅ Added dream: ${data['title'] ?? doc.id}');

      if (previousDreams.length >= 5) break;
    }

    debugPrint('📚 Retrieved ${previousDreams.length} previous dreams');
    return previousDreams;
  }

  /// Clear previous dreams cache
  Future<void> clearCache() async {
    debugPrint('🗑️ Clearing N8N cache...');
    await _cacheService.clearExpired();
  }
}
