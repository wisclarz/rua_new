import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cache_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
            'https://dreamdemoapp.app.n8n.cloud/webhook/bf22088f-6627-4593-85b6-8dc112767901',
        headers = headers ??
            const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'DreamyApp/1.0.0',
            },
        _firestore = firestore ?? FirebaseFirestore.instance,
        _cacheService = cacheService ?? CacheService.instance;
Future<String?> _getFCMToken() async {
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('📱 FCM Token: $fcmToken');
    return fcmToken;
  } catch (e) {
    debugPrint('❌ FCM Token error: $e');
    return null;
  }
}
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
        fcmToken: await _getFCMToken() ?? '',
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

  /// Trigger dream analysis with history and return result
  ///
  /// N8N workflow analizi yapar ve sonucu JSON olarak döndürür.
  /// Flutter app bu sonucu alıp Firestore'u günceller.
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
      final fcmToken = await _getFCMToken();
      final previousDreams = await _fetchPreviousDreamsWithCache(
        user.uid,
        dreamId,
      );

      final payload = _createAnalysisPayload(
        dreamId: dreamId,
        userId: user.uid,
        idToken: idToken,
        fcmToken: fcmToken ?? '',
        audioUrl: audioUrl,
        dreamText: dreamText,
        previousDreams: previousDreams,
      );

      // N8N'den analiz sonucunu bekle (timeout artırıldı)
      final response = await _sendRequest(payload, timeout: 60);

      if (_isSuccessResponse(response)) {
        debugPrint('✅ N8N analysis completed successfully');
        return _parseAnalysisResponse(response);
      }

      debugPrint('❌ N8N analysis failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('💥 N8N analysis error: $e');
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
    required String fcmToken,
  }) {
    return {
      'audioUrl': audioUrl,
      'userId': userId,
      'idToken': idToken,
      'fcmToken': fcmToken,
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
    required String fcmToken,
    String? audioUrl,
    String? dreamText,
    required List<Map<String, dynamic>> previousDreams,
  }) {
    final inputType = audioUrl != null ? 'voice' : 'text';

    final payload = {
      'dreamId': dreamId,
      'userId': userId,
      'idToken': idToken,
      'fcmToken': fcmToken,
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
      debugPrint('📥 Raw N8N response: ${response.body}');

      final decodedData = jsonDecode(response.body);
      debugPrint('📥 Decoded type: ${decodedData.runtimeType}');

      // N8N array olarak dönebilir: [{json: {...}}]
      if (decodedData is List && decodedData.isNotEmpty) {
        debugPrint('📥 Response is a List, taking first item');
        final firstItem = decodedData[0];

        // Eğer {json: {...}} formatındaysa
        if (firstItem is Map<String, dynamic> && firstItem.containsKey('json')) {
          debugPrint('✅ Found "json" key, extracting...');
          return firstItem['json'] as Map<String, dynamic>;
        }

        // Eğer direkt obje ise
        return firstItem as Map<String, dynamic>;
      }

      // Direkt obje olarak dönmüşse
      if (decodedData is Map<String, dynamic>) {
        debugPrint('✅ Response is a Map');
        return decodedData;
      }

      debugPrint('❌ Unexpected response format');
      return null;
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

      // Firestore'da Türkçe field isimleri kullanılıyor
      final baslik = data['baslik'] ?? data['title'] ?? '';

      // Semboller - HEM string HEM array formatını destekle
      List<String> semboller = [];
      final sembollerRaw = data['semboller'] ?? data['symbols'];
      if (sembollerRaw != null) {
        if (sembollerRaw is String) {
          // JSON string ise parse et (n8n'den gelen format)
          try {
            final decoded = jsonDecode(sembollerRaw);
            if (decoded is List) {
              semboller = List<String>.from(decoded);
            }
          } catch (e) {
            debugPrint('⚠️ semboller parse error: $e');
          }
        } else if (sembollerRaw is List) {
          // Zaten List ise direkt kullan
          semboller = List<String>.from(sembollerRaw);
        }
      }

      final analiz = data['analiz'] ?? data['interpretation'] ?? data['analysis'] ?? '';
      final ruhSagligi = data['ruhSagligi'] ?? data['ruh_sagligi'] ?? '';

      // Duygular object'inden ana duyguyu al - HEM string HEM object formatını destekle
      String anaDuygu = data['mood'] ?? 'Belirsiz';
      List<String> altDuygular = [];

      if (data['duygular'] != null) {
        Map<String, dynamic>? duygularMap;

        // Eğer string ise (n8n'den gelen format), JSON parse et
        if (data['duygular'] is String) {
          try {
            final decoded = jsonDecode(data['duygular']);
            if (decoded is Map) {
              duygularMap = Map<String, dynamic>.from(decoded);
            }
          } catch (e) {
            debugPrint('⚠️ duygular parse error: $e');
          }
        }
        // Eğer zaten Map ise direkt kullan
        else if (data['duygular'] is Map) {
          duygularMap = Map<String, dynamic>.from(data['duygular']);
        }

        if (duygularMap != null) {
          anaDuygu = duygularMap['anaDuygu'] ?? duygularMap['ana_duygu'] ?? anaDuygu;

          final altDuygularRaw = duygularMap['altDuygular'] ?? duygularMap['alt_duygular'];
          if (altDuygularRaw is List) {
            altDuygular = List<String>.from(altDuygularRaw);
          }
        }
      }

      previousDreams.add({
        'dreamId': doc.id,
        'dreamText': dreamText,
        'baslik': baslik,
        'duygular': {
          'anaDuygu': anaDuygu,
          'altDuygular': altDuygular,
        },
        'semboller': semboller,
        'analiz': analiz,
        'ruhSagligi': ruhSagligi,
        'timestamp': data['timestamp']?.toString() ??
            data['createdAt']?.toString() ??
            '',
      });

      debugPrint('✅ Added dream: $baslik (${doc.id})');

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
