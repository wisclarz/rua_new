import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import '../models/dream_model.dart';
import '../services/recording_service.dart';
import '../services/transcription_service.dart';
import '../services/audio_upload_service.dart';
import '../services/n8n_service.dart';
import '../services/cache_service.dart';
import '../repositories/dream_repository.dart';

/// Dream Provider (Refactored)
///
/// SOLID Principles:
/// - Single Responsibility: Sadece dream state management
/// - Dependency Injection: Tüm servisler inject edilir
/// - Open/Closed: Yeni özellikler servislere eklenir
///
/// Improvements:
/// - From 1010 lines to ~400 lines
/// - Clear separation of concerns
/// - All business logic moved to services
/// - Easier to test and maintain
class DreamProvider extends ChangeNotifier {
  // State
  List<Dream> _dreams = [];
  List<Dream> get dreams => _dreams;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _pendingTranscription;
  String? get pendingTranscription => _pendingTranscription;

  // Track which dreams already sent notification
  final Set<String> _notifiedDreams = {};

  // Services (Dependency Injection)
  final RecordingService _recordingService;
  bool get isRecording => _recordingService.isRecording;
  final TranscriptionService _transcriptionService;
  final AudioUploadService _audioUploadService;
  final N8nService _n8nService;
  final DreamRepository _dreamRepository;
  final FirebaseAuth _auth;

  StreamSubscription<List<Dream>>? _dreamsSubscription;

  DreamProvider({
    RecordingService? recordingService,
    TranscriptionService? transcriptionService,
    AudioUploadService? audioUploadService,
    N8nService? n8nService,
    DreamRepository? dreamRepository,
    FirebaseAuth? firebaseAuth,
  })  : _recordingService = recordingService ?? RecordingService(),
        _transcriptionService = transcriptionService ?? TranscriptionService(),
        _audioUploadService = audioUploadService ?? AudioUploadService(),
        _n8nService = n8nService ?? N8nService(),
        _dreamRepository = dreamRepository ?? FirebaseDreamRepository(),
        _auth = firebaseAuth ?? FirebaseAuth.instance {
    debugPrint('🏗️ DreamProvider created (refactored)');
  }

  @override
  void dispose() {
    debugPrint('🔄 Disposing DreamProvider...');
    stopListeningToDreams();
    _recordingService.disposeService();
    super.dispose();
  }

  // ==================== DREAM LISTENING ====================

  void startListeningToDreams() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ No user, cannot start listener');
      return;
    }

    if (_dreamsSubscription != null) {
      debugPrint('⚠️ Already listening to dreams');
      return;
    }

    debugPrint('🎧 Starting real-time listener for dreams...');

    // ⚡ PERFORMANCE: Load cached dreams immediately for instant UI
    _loadCachedDreams(user.uid);

    _dreamsSubscription = _dreamRepository
        .watchUserDreams(user.uid)
        .listen(
          (dreams) async {
            debugPrint('🔄 Received ${dreams.length} dreams from Firestore');

            // Debug: Print each dream status
            for (var dream in dreams) {
              debugPrint('  - Dream ${dream.id}: status=${dream.status}, title=${dream.title}');
            }

            // Check for newly completed dreams
            _checkForCompletedDreams(dreams);

            _dreams = dreams;
            _safeNotify();

            // ⚡ CACHE: Save to cache for next app launch
            await _cacheDreams(user.uid, dreams);
          },
          onError: (error) {
            debugPrint('❌ Stream error: $error');
            _setError('Rüyalar yüklenirken hata: $error');
          },
        );
  }

  /// ⚡ Load cached dreams for instant UI
  Future<void> _loadCachedDreams(String userId) async {
    try {
      final cachedData = await CacheService.instance.get<List>(
        CacheKeys.previousDreams(userId),
      );

      if (cachedData != null && cachedData.isNotEmpty) {
        debugPrint('✅ Loaded ${cachedData.length} dreams from cache');

        _dreams = cachedData
            .map((data) => Dream.fromMap(Map<String, dynamic>.from(data)))
            .toList();
        _safeNotify();

        debugPrint('⚡ UI populated with cached dreams (instant load!)');
      } else {
        debugPrint('📭 No cached dreams found');
      }
    } catch (e) {
      debugPrint('⚠️ Cache load error: $e');
      // Continue without cache
    }
  }

  /// ⚡ Cache dreams for next app launch
  Future<void> _cacheDreams(String userId, List<Dream> dreams) async {
    try {
      final dreamsData = dreams.map((d) => d.toMap()).toList();

      await CacheService.instance.put(
        CacheKeys.previousDreams(userId),
        dreamsData,
        ttl: const Duration(days: 7), // Cache for 7 days
      );

      debugPrint('💾 Cached ${dreams.length} dreams');
    } catch (e) {
      debugPrint('⚠️ Cache save error: $e');
      // Continue without caching
    }
  }

  void stopListeningToDreams() {
    if (_dreamsSubscription != null) {
      debugPrint('🛑 Stopping dreams listener...');
      _dreamsSubscription?.cancel();
      _dreamsSubscription = null;
    }
  }

  Future<void> loadDreams() async {
    if (_isLoading) {
      debugPrint('⚠️ Already loading dreams');
      return;
    }

    // ⚡ Check if already listening - skip if active
    if (_dreamsSubscription != null) {
      debugPrint('⚠️ Already listening to dreams');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _setError('Kullanıcı oturumu bulunamadı');
        return;
      }

      debugPrint('📱 Loading dreams for user: ${user.uid}');
      startListeningToDreams();
      debugPrint('✅ Dreams loaded successfully');
    } catch (e) {
      debugPrint('❌ Error loading dreams: $e');
      _setError('Rüyalar yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshDreams() async {
    debugPrint('🔄 Refreshing dreams...');

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      stopListeningToDreams();
      await Future.delayed(const Duration(milliseconds: 500));
      startListeningToDreams();

      debugPrint('✅ Dreams refreshed');
    } catch (e) {
      debugPrint('❌ Error refreshing dreams: $e');
    }
  }

  /// Get a specific dream by ID from Firestore (fresh data)
  /// Used for notification navigation to ensure latest data
  Future<Dream?> getDreamById(String dreamId) async {
    debugPrint('📥 [PROVIDER] Fetching dream from Firestore: $dreamId');

    try {
      final dream = await _dreamRepository.getDreamById(dreamId);

      if (dream == null) {
        debugPrint('⚠️ [PROVIDER] Dream not found: $dreamId');
        return null;
      }

      debugPrint('✅ [PROVIDER] Dream fetched successfully');
      debugPrint('✅ [PROVIDER] Title: ${dream.baslik ?? dream.title}');
      debugPrint('✅ [PROVIDER] Status: ${dream.status}');

      return dream;
    } catch (e) {
      debugPrint('❌ [PROVIDER] Error fetching dream: $e');
      return null;
    }
  }

  /// Called when user authentication state changes
  void startListeningToAuthenticatedUser() {
    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('🔐 User authenticated, starting dream listener: ${user.uid}');
      Future.microtask(() => loadDreams());
    } else {
      debugPrint('🔐 No authenticated user, stopping listener');
      stopListeningToDreams();
    }
  }

  // ==================== TEXT DREAM ====================

  Future<Dream> uploadTextDream({
    required String dreamText,
    String? title,
  }) async {
    debugPrint('📝 uploadTextDream called');

    try {
      _setLoading(true);
      _clearError();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      if (dreamText.trim().isEmpty) {
        throw Exception('Rüya metni boş olamaz');
      }

      if (dreamText.trim().length < 20) {
        throw Exception('Rüya metni en az 20 karakter olmalıdır');
      }

      debugPrint('📝 Creating text dream record...');
      final Dream newDream = await _createTextDreamRecord(
        dreamText: dreamText.trim(),
        title: title?.trim(),
        userId: user.uid,
      );

      debugPrint('✅ Text dream created: ${newDream.id}');
      return newDream;
    } catch (e) {
      debugPrint('❌ uploadTextDream error: $e');
      _setError('Metin rüya kaydedilirken hata oluştu: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Dream> _createTextDreamRecord({
    required String dreamText,
    String? title,
    required String userId,
  }) async {
    final String dreamId = _generateDreamId();

    // FCM Token'ı al
    final fcmToken = await _getFCMToken();

    final Dream newDream = Dream(
      id: dreamId,
      userId: userId,
      fcmToken: fcmToken,
      fileName: null,
      title: title ?? 'Analiz Ediliyor',
      baslik: title ?? 'Analiz Ediliyor', // n8n için gerekli
      dreamText: dreamText,

      // Duygular - başlangıç değerleri
      mood: 'Belirsiz',
      duygular: {
        'anaDuygu': 'Belirsiz',
        'altDuygular': <String>[],
      },

      // Semboller - başlangıç değerleri
      symbols: [],
      semboller: [],

      // Analiz - başlangıç değerleri
      analysis: 'Analiz yapılıyor...',
      analiz: 'Analiz yapılıyor...',
      interpretation: 'Analiz yapılıyor...',

      // Ruh sağlığı - başlangıç değeri
      ruhSagligi: '',

      status: DreamStatus.processing,
      createdAt: DateTime.now(),
    );

    await _dreamRepository.createDream(dreamId, newDream);
    debugPrint('✅ TEXT Dream document created: $dreamId');

    if (_dreamsSubscription == null) {
      startListeningToDreams();
    }

    // Trigger analysis in background
    _triggerTextAnalysis(dreamId, dreamText, userId);

    return newDream;
  }

  Future<void> _triggerTextAnalysis(
    String dreamId,
    String dreamText,
    String userId,
  ) async {
    try {
      debugPrint('🚀 Triggering TEXT analysis for: $dreamId');

      final user = _auth.currentUser;
      if (user == null) return;

      // N8N'den analiz sonucunu al
      final analysisResult = await _n8nService.triggerDreamAnalysisWithHistory(
        dreamId: dreamId,
        dreamText: dreamText,
        user: user,
      );

      if (analysisResult == null) {
        debugPrint('⚠️ Failed to get TEXT analysis result');
        await _markDreamAsFailed(dreamId, 'Analiz başlatılamadı');
      } else {
        debugPrint('✅ TEXT analysis completed!');
        debugPrint('📊 Analysis result: baslik=${analysisResult['baslik']}, analiz=${analysisResult['analiz']?.toString().substring(0, 50)}...');
        // n8n zaten Firestore'u güncelliyor, Flutter sadece dinlesin
        debugPrint('📡 Firestore will be updated by n8n, listening for changes...');
      }
    } catch (e) {
      debugPrint('❌ TEXT analysis error: $e');
      await _markDreamAsFailed(dreamId, 'Analiz hatası: $e');
    }
  }

  // ==================== VOICE DREAM WITH TRANSCRIPTION ====================

  Future<void> transcribeAudioFile(
    File audioFile, {
    required Function(String transcription) onTranscriptionReady,
  }) async {
    debugPrint('🎙️ transcribeAudioFile called: ${audioFile.path}');

    try {
      _setLoading(true);
      _clearError();

      final transcription = await _transcriptionService.transcribe(
        audioFile: audioFile,
        language: 'tr',
        useCache: true,
      );

      if (transcription != null && transcription.isNotEmpty) {
        debugPrint('✅ Transcription successful');
        _pendingTranscription = transcription;
        onTranscriptionReady(transcription);

        // Clean up audio file
        try {
          await audioFile.delete();
          debugPrint('🗑️ Audio file deleted after transcription');
        } catch (e) {
          debugPrint('⚠️ Could not delete audio file: $e');
        }
      } else {
        throw Exception('Ses dosyası metne çevrilemedi');
      }
    } catch (e) {
      debugPrint('❌ transcribeAudioFile error: $e');
      _setError('Transkripsiyon hatası: $e');

      // Clean up on error
      try {
        if (audioFile.existsSync()) {
          await audioFile.delete();
        }
      } catch (_) {}

      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Dream> createDreamWithTranscription({
    required String transcription,
    String? title,
  }) async {
    debugPrint('📝 Creating dream with transcription...');

    try {
      _setLoading(true);
      _clearError();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      if (transcription.trim().isEmpty) {
        throw Exception('Transkripsiyon metni boş olamaz');
      }

      final String dreamId = _generateDreamId();

      // FCM Token'ı al
      final fcmToken = await _getFCMToken();

      final Dream newDream = Dream(
        id: dreamId,
        userId: user.uid,
        fcmToken: fcmToken,
        fileName: null,
        title: title ?? 'Yeni Sesli Rüya',
        baslik: title ?? 'Yeni Sesli Rüya', // n8n için gerekli
        dreamText: transcription,

        // Duygular - başlangıç değerleri
        mood: 'Belirsiz',
        duygular: {
          'anaDuygu': 'Belirsiz',
          'altDuygular': <String>[],
        },

        // Semboller - başlangıç değerleri
        symbols: [],
        semboller: [],

        // Analiz - başlangıç değerleri
        analysis: 'Analiz yapılıyor...',
        analiz: 'Analiz yapılıyor...',
        interpretation: 'Analiz yapılıyor...',

        // Ruh sağlığı - başlangıç değeri
        ruhSagligi: '',

        status: DreamStatus.processing,
        createdAt: DateTime.now(),
      );

      await _dreamRepository.createDream(dreamId, newDream);
      debugPrint('✅ Voice dream created: $dreamId');

      if (_dreamsSubscription == null) {
        startListeningToDreams();
      }

      // Trigger analysis
      _triggerVoiceAnalysis(dreamId, transcription, user);

      _pendingTranscription = null;
      return newDream;
    } catch (e) {
      debugPrint('❌ createDreamWithTranscription error: $e');
      _setError('Rüya kaydedilirken hata oluştu: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _triggerVoiceAnalysis(
    String dreamId,
    String transcription,
    User user,
  ) async {
    try {
      debugPrint('🚀 Triggering VOICE analysis for: $dreamId');

      // N8N'den analiz sonucunu al
      final analysisResult = await _n8nService.triggerDreamAnalysisWithHistory(
        dreamId: dreamId,
        dreamText: transcription,
        user: user,
      );

      if (analysisResult == null) {
        debugPrint('⚠️ Failed to get VOICE analysis result');
        await _markDreamAsFailed(dreamId, 'Analiz başlatılamadı');
      } else {
        debugPrint('✅ VOICE analysis completed!');
        debugPrint('📊 Analysis result: baslik=${analysisResult['baslik']}, analiz=${analysisResult['analiz']?.toString().substring(0, 50)}...');
        // n8n zaten Firestore'u güncelliyor, Flutter sadece dinlesin
        debugPrint('📡 Firestore will be updated by n8n, listening for changes...');
      }
    } catch (e) {
      debugPrint('❌ VOICE analysis error: $e');
      await _markDreamAsFailed(dreamId, 'Analiz hatası: $e');
    }
  }

  // ==================== LEGACY: RECORDING WITH UPLOAD ====================
  // (Kept for backward compatibility)

  Future<bool> stopRecordingAndSave() async {
    debugPrint('🛑 STOP RECORDING CALLED');

    try {
      _setLoading(true);
      _clearError();

      final audioFile = await _recordingService.stopRecording();
      if (audioFile == null) {
        throw Exception('Ses dosyası oluşturulamadı');
      }

      debugPrint('☁️ Uploading audio to Firebase Storage...');
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final downloadUrl = await _audioUploadService.uploadAudio(
        userId: user.uid,
        audioFile: audioFile,
      );

      debugPrint('📝 Creating dream with audio URL...');
      final Dream newDream = await _createVoiceDreamRecord(
        audioUrl: downloadUrl,
        userId: user.uid,
      );

      // Clean up
      try {
        await audioFile.delete();
      } catch (_) {}

      debugPrint('✅ Dream saved: ${newDream.id}');
      return true;
    } catch (e) {
      debugPrint('❌ stopRecordingAndSave error: $e');
      _setError('Rüya kaydedilirken hata: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Dream> _createVoiceDreamRecord({
    required String audioUrl,
    required String userId,
  }) async {
    final String dreamId = _generateDreamId();

    // FCM Token'ı al
    final fcmToken = await _getFCMToken();

    final Dream newDream = Dream(
      id: dreamId,
      userId: userId,
      fcmToken: fcmToken,
      fileName: null,
      title: 'Analiz Ediliyor',
      baslik: 'Analiz Ediliyor', // n8n için gerekli
      dreamText: null,

      // Duygular - başlangıç değerleri
      mood: 'Belirsiz',
      duygular: {
        'anaDuygu': 'Belirsiz',
        'altDuygular': <String>[],
      },

      // Semboller - başlangıç değerleri
      symbols: [],
      semboller: [],

      // Analiz - başlangıç değerleri
      analysis: 'Analiz yapılıyor...',
      analiz: 'Analiz yapılıyor...',
      interpretation: 'Analiz yapılıyor...',

      // Ruh sağlığı - başlangıç değeri
      ruhSagligi: '',

      status: DreamStatus.processing,
      createdAt: DateTime.now(),
    );

    await _dreamRepository.createDream(dreamId, newDream);

    if (_dreamsSubscription == null) {
      startListeningToDreams();
    }

    // Trigger analysis
    final user = _auth.currentUser;
    if (user != null) {
      _triggerAudioAnalysis(dreamId, audioUrl, user);
    }

    return newDream;
  }

  Future<void> _triggerAudioAnalysis(
    String dreamId,
    String audioUrl,
    User user,
  ) async {
    try {
      debugPrint('🚀 Triggering AUDIO analysis for: $dreamId');

      // N8N'den analiz sonucunu al
      final analysisResult = await _n8nService.triggerDreamAnalysisWithHistory(
        dreamId: dreamId,
        audioUrl: audioUrl,
        user: user,
      );

      if (analysisResult == null) {
        debugPrint('⚠️ Failed to get AUDIO analysis result');
        await _markDreamAsFailed(dreamId, 'Analiz başlatılamadı');
      } else {
        debugPrint('✅ AUDIO analysis completed!');
        debugPrint('📊 Analysis result: baslik=${analysisResult['baslik']}, analiz=${analysisResult['analiz']?.toString().substring(0, 50)}...');
        // n8n zaten Firestore'u güncelliyor, Flutter sadece dinlesin
        debugPrint('📡 Firestore will be updated by n8n, listening for changes...');
      }
    } catch (e) {
      debugPrint('❌ AUDIO analysis error: $e');
      await _markDreamAsFailed(dreamId, 'Analiz hatası: $e');
    }
  }

  // ==================== FIRESTORE UPDATE HELPERS ====================

  Future<void> _updateDreamWithAnalysis(
    String dreamId,
    Map<String, dynamic> analysisResult,
  ) async {
    try {
      debugPrint('💾 Updating dream with analysis: $dreamId');

      // N8N'den gelen field'lar: baslik, analiz, duygular, semboller
      final baslik = analysisResult['baslik'] ?? 'Başlıksız Rüya';
      final analiz = analysisResult['analiz'] ?? '';

      // Semboller - array olarak gelir
      final semboller = analysisResult['semboller'] is List
          ? List<String>.from(analysisResult['semboller'])
          : <String>[];

      // Duygular - map olarak gelir
      final duygular = analysisResult['duygular'] is Map
          ? Map<String, dynamic>.from(analysisResult['duygular'])
          : {
              'anaDuygu': 'Belirsiz',
              'altDuygular': <String>[],
            };

      final updateData = {
        // Rüya Metni
        'dreamText': analysisResult['dreamText'] ?? '',

        // Başlık (hem yeni hem eski format)
        'baslik': baslik,

        // Duygular (Map olarak)
        'duygular': duygular,
        'mood': duygular['anaDuygu'] ?? duygular['ana_duygu'] ?? 'Belirsiz',

        // Semboller (Array olarak)
        'semboller': semboller,

        // Analiz
        'analiz': analiz,

        // Ruh Sağlığı
        'ruhSagligi': analysisResult['ruhSagligi'] ?? '',

        // Status
        'status': 'completed',
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _dreamRepository.updateDream(dreamId, updateData);
      debugPrint('✅ Dream updated successfully with fields: baslik=$baslik, analiz=${analiz.length} chars');
    } catch (e) {
      debugPrint('❌ Update error: $e');
      await _markDreamAsFailed(dreamId, 'Güncelleme hatası');
    }
  }

  Future<void> _markDreamAsFailed(String dreamId, String message) async {
    try {
      await _dreamRepository.updateDream(dreamId, {
        'status': 'failed',
        'analysis': message,
      });
    } catch (e) {
      debugPrint('❌ Failed to mark as failed: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Get FCM Token for push notifications
  Future<String?> _getFCMToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('📱 FCM Token retrieved: ${fcmToken?.substring(0, 20)}...');
      return fcmToken;
    } catch (e) {
      debugPrint('❌ FCM Token error: $e');
      return null;
    }
  }

  /// Check for newly completed dreams (n8n sends notification, we just log)
  void _checkForCompletedDreams(List<Dream> newDreams) {
    for (final dream in newDreams) {
      // Skip if already logged
      if (_notifiedDreams.contains(dream.id)) {
        continue;
      }

      // Log newly completed dreams
      if (dream.status == DreamStatus.completed) {
        debugPrint('✅ Completed dream detected: ${dream.id}, title=${dream.baslik ?? dream.title}');
        _notifiedDreams.add(dream.id);
        // n8n zaten FCM notification gönderiyor, Flutter local notification göstermesin
      }
    }
  }

  String _generateDreamId() {
    return 'dream_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _safeNotify();
    }
  }

  void _setError(String error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      _safeNotify();
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      _safeNotify();
    }
  }

  void _safeNotify() {
    scheduleMicrotask(() {
      notifyListeners();
    });
  }
}
