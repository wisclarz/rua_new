import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class N8nService {
  static const String _webhookUrl = 'https://dreamdemoo.app.n8n.cloud/webhook/bf22088f-6627-4593-85b6-8dc112767901';
  
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'DreamyApp/1.0.0',
  };

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // DEPRECATED: Artık OpenAIService kullanılıyor
  // YENİ: TRANSCRIBE ONLY - Sadece ses metne çevrilir
  // ==========================================
  /* 
  Future<String?> transcribeAudioOnly({
    required String audioUrl,
    required firebase_auth.User user,
  }) async {
    try {
      debugPrint('🎙️ Starting transcription-only for audio: $audioUrl');
      
      String idToken = '';
      try {
        idToken = await user.getIdTokenResult().then((result) => result.token ?? '');
      } catch (tokenError) {
        debugPrint('⚠️ ID Token error: $tokenError');
      }
      
      final Map<String, dynamic> payload = {
        'audioUrl': audioUrl,
        'userId': user.uid,
        'idToken': idToken,
        'action': 'transcribe_only', // ← N8N Switch için kritik
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

      debugPrint('📤 Sending transcription-only request');

      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 45));

      debugPrint('📥 Transcription response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final transcription = responseData['transcription'] ?? responseData['dreamText'];
          
          if (transcription != null && transcription.toString().isNotEmpty) {
            debugPrint('✅ Transcription received: ${transcription.toString().substring(0, transcription.toString().length > 50 ? 50 : transcription.toString().length)}...');
            return transcription.toString();
          } else {
            debugPrint('❌ Empty transcription in response');
            return null;
          }
        } catch (e) {
          debugPrint('❌ Failed to parse transcription: $e');
          return null;
        }
      } else {
        debugPrint('❌ Transcription request failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 Transcription error: $e');
      return null;
    }
  }
  */

  // ==========================================
  // UNIFIED: Hem voice hem text için tek fonksiyon
  // ==========================================
  Future<Map<String, dynamic>?> triggerDreamAnalysisWithHistory({
    required String dreamId,
    String? audioUrl,
    String? dreamText,
    required firebase_auth.User user,
  }) async {
    try {
      // Input type'ı belirle
      final inputType = audioUrl != null ? 'voice' : 'text';
      
      debugPrint('🚀 Starting $inputType dream analysis with history for: $dreamId');
      debugPrint('👤 User ID: ${user.uid}');
      
      String idToken = '';
      try {
        idToken = await user.getIdTokenResult().then((result) => result.token ?? '');
        debugPrint('🔑 ID Token retrieved');
      } catch (tokenError) {
        debugPrint('⚠️ ID Token error: $tokenError');
      }
      
      final previousDreams = await _fetchPreviousDreams(user.uid, dreamId);
      debugPrint('📚 Found ${previousDreams.length} previous dreams');
      
      // Dynamic payload
      final Map<String, dynamic> payload = {
        'dreamId': dreamId,
        'userId': user.uid,
        'idToken': idToken,
        'inputType': inputType,
        'action': 'analyze_dream', // ← N8N Switch için
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
          'user_id': user.uid,
          'has_history': previousDreams.isNotEmpty,
          'input_type': inputType,
        }
      };

      // Voice-specific fields
      if (audioUrl != null) {
        payload['audioUrl'] = audioUrl;
        payload['openai_config'] = {
          'model': 'whisper-1',
          'language': 'tr',
          'gpt_model': 'gpt-4o-mini',
        };
      }

      // Text-specific fields
      if (dreamText != null) {
        payload['dreamText'] = dreamText;
        payload['openai_config'] = {
          'gpt_model': 'gpt-4o-mini',
          'language': 'tr',
        };
        payload['debug']['text_length'] = dreamText.length;
      }

      debugPrint('📤 Sending $inputType payload with ${previousDreams.length} previous dreams');

      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 60));

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ N8N $inputType webhook triggered successfully');
        
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          debugPrint('📥 $inputType Analysis received from N8N');
          
          return responseData;
          
        } catch (e) {
          debugPrint('❌ Failed to parse N8N response: $e');
          debugPrint('📥 Raw response: ${response.body}');
          return null;
        }
      } else {
        debugPrint('❌ N8N webhook failed: ${response.statusCode}');
        debugPrint('❌ Error body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 N8N webhook error: $e');
      return null;
    }
  }

  // ==========================================
  // Firestore'dan önceki rüyaları çek
  // ==========================================
  Future<List<Map<String, dynamic>>> _fetchPreviousDreams(String userId, String currentDreamId) async {
    try {
      debugPrint('📚 Fetching previous dreams for user: $userId');
      
      QuerySnapshot? snapshot;
      
      try {
        snapshot = await _firestore
            .collection('dreams')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'completed')
            .orderBy('createdAt', descending: true)
            .limit(6)
            .get();
        debugPrint('✅ Query with createdAt successful');
      } catch (e) {
        debugPrint('⚠️ createdAt query failed, trying timestamp: $e');
        
        try {
          snapshot = await _firestore
              .collection('dreams')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'completed')
              .orderBy('timestamp', descending: true)
              .limit(6)
              .get();
          debugPrint('✅ Query with timestamp successful');
        } catch (e2) {
          debugPrint('⚠️ timestamp query also failed, trying without orderBy: $e2');
          
          snapshot = await _firestore
              .collection('dreams')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'completed')
              .limit(6)
              .get();
          debugPrint('✅ Query without orderBy successful');
        }
      }

      if (snapshot.docs.isEmpty) {
        debugPrint('📚 No completed dreams found, trying all statuses...');
        
        try {
          snapshot = await _firestore
              .collection('dreams')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(6)
              .get();
          debugPrint('✅ Found ${snapshot.docs.length} dreams (any status)');
        } catch (e) {
          debugPrint('⚠️ Even fallback query failed: $e');
          return [];
        }
      }

      if (snapshot.docs.isEmpty) {
        debugPrint('📚 No previous dreams found at all');
        return [];
      }

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
          'timestamp': data['timestamp']?.toString() ?? data['createdAt']?.toString() ?? '',
        });
        
        debugPrint('✅ Added dream: ${data['title'] ?? doc.id}');
        
        if (previousDreams.length >= 5) break;
      }

      debugPrint('📚 Retrieved ${previousDreams.length} previous dreams with analysis');
      return previousDreams;
      
    } catch (e) {
      debugPrint('💥 Error fetching previous dreams: $e');
      return [];
    }
  }
}