import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class N8nService {
  static const String _baseUrl = 'https://wisclarz.app.n8n.cloud'; 
  static const String _webhookUrl = 'https://wisclarz.app.n8n.cloud/webhook/dream-analysis';
  
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'DreamyApp/1.0.0',
  };

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ANA FONKSİYON: Önceki rüyalarla birlikte analiz tetikle ve sonucu al
  Future<Map<String, dynamic>?> triggerDreamAnalysisWithHistory({
    required String dreamId,
    required String audioUrl,
    required firebase_auth.User user,
  }) async {
    try {
      debugPrint('🚀 Starting dream analysis with history for: $dreamId');
      debugPrint('👤 User ID: ${user.uid}');
      
      // 1. ID Token al
      String idToken = '';
      try {
        idToken = await user.getIdTokenResult().then((result) => result.token ?? '');
        debugPrint('🔑 ID Token retrieved');
      } catch (tokenError) {
        debugPrint('⚠️ ID Token error: $tokenError');
      }
      
      // 2. Önceki 5 rüyayı Firestore'dan çek
      final previousDreams = await _fetchPreviousDreams(user.uid, dreamId);
      debugPrint('📚 Found ${previousDreams.length} previous dreams');
      
      // 3. Payload'ı hazırla
      final Map<String, dynamic> payload = {
        'dreamId': dreamId,
        'audioUrl': audioUrl,
        'userId': user.uid,
        'idToken': idToken,
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'analyze_dream',
        'workflow': 'dream_analysis_v2',
        'version': '2.0.0',
        
        // Önceki rüyalar
        'hasPreviousDreams': previousDreams.isNotEmpty,
        'previousDreams': previousDreams,
        'previousDreamsCount': previousDreams.length,
        
        // OpenAI configuration
        'openai_config': {
          'model': 'whisper-1',
          'language': 'tr',
          'gpt_model': 'gpt-4o-mini',
          'max_tokens': 2000,
          'temperature': 0.7,
        },
        
        'debug': {
          'client': 'flutter_app',
          'platform': defaultTargetPlatform.name,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'user_id': user.uid,
          'has_history': previousDreams.isNotEmpty,
        }
      };

      debugPrint('📤 Sending payload with ${previousDreams.length} previous dreams');

      // 4. N8N'e gönder ve RESPONSE AL
      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 60)); // Timeout artırıldı

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ N8N webhook triggered successfully');
        
        try {
          // Response'u parse et
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          debugPrint('📥 Analysis received from N8N');
          
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

  // Firestore'dan önceki 5 rüyayı çek
  Future<List<Map<String, dynamic>>> _fetchPreviousDreams(String userId, String currentDreamId) async {
    try {
      debugPrint('📚 Fetching previous dreams for user: $userId');
      
      QuerySnapshot? snapshot;
      
      // Önce createdAt ile dene (en yaygın)
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
        
        // createdAt başarısız olursa timestamp dene
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
          
          // orderBy olmadan dene (index yoksa)
          snapshot = await _firestore
              .collection('dreams')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'completed')
              .limit(6)
              .get();
          debugPrint('✅ Query without orderBy successful');
        }
      }

      if (snapshot == null || snapshot.docs.isEmpty) {
        debugPrint('📚 No completed dreams found, trying all statuses...');
        
        // Status filtresi olmadan dene - herhangi bir rüya
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
        // Mevcut rüyayı dahil etme
        if (doc.id == currentDreamId) {
          debugPrint('⏭️ Skipping current dream: $currentDreamId');
          continue;
        }
        
        final data = doc.data() as Map<String, dynamic>;
        
        // Sadece dreamText olan rüyaları al (analizi tamamlanmış)
        final dreamText = data['dreamText'] ?? data['dream_text'] ?? '';
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
      debugPrint('💥 Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Test için: Önceki rüyaları manuel çek
  Future<void> testFetchPreviousDreams(String userId) async {
    debugPrint('🧪 Testing previous dreams fetch...');
    final dreams = await _fetchPreviousDreams(userId, 'test_dream_id');
    debugPrint('🧪 Found ${dreams.length} dreams');
    for (var dream in dreams) {
      debugPrint('  - ${dream['title']} (${dream['timestamp']})');
    }
  }
}