import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import '../models/dream_model.dart';
import '../services/n8n_service.dart';

class DreamProvider extends ChangeNotifier {
  List<Dream> _dreams = [];
  List<Dream> get dreams => _dreams;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Audio recording variables
  FlutterSoundRecorder? _recorder;
  String? _currentRecordingPath;
  bool _isRecorderInitialized = false;
  
  // Firebase instances  
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final N8nService _n8nService = N8nService();
  
  // Real-time listener
  StreamSubscription<QuerySnapshot>? _dreamsSubscription;

  DreamProvider() {
    debugPrint('🏗️ DreamProvider created (lightweight)');
  }

  // ⚡ Lazy initialization
  Future<void> _ensureRecorderInitialized() async {
    if (_isRecorderInitialized) return;
    
    try {
      debugPrint('🎤 Lazy initializing recorder...');
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
      _isRecorderInitialized = true;
      debugPrint('✅ Recorder initialized');
    } catch (e) {
      debugPrint('❌ Recorder initialization failed: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('🔄 Disposing DreamProvider...');
    stopListeningToDreams();
    if (_isRecorderInitialized) {
      _recorder?.closeRecorder();
    }
    super.dispose();
  }

  Future<bool> _requestMicrophonePermission() async {
    debugPrint('🔒 Requesting microphone permission...');
    final status = await Permission.microphone.request();
    final granted = status == PermissionStatus.granted;
    debugPrint(granted ? '✅ Microphone permission granted' : '❌ Microphone permission denied');
    return granted;
  }

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
    
    _dreamsSubscription = _firestore
        .collection('dreams')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snapshot) {
        debugPrint('🔄 Firestore snapshot received: ${snapshot.docs.length} dreams');
        _processDreamsSnapshot(snapshot);
      },
      onError: (error) {
        debugPrint('❌ Firestore listener error: $error');
      },
    );
  }

  void _processDreamsSnapshot(QuerySnapshot snapshot) {
    try {
      final newDreams = <Dream>[];
      
      for (var doc in snapshot.docs) {
        try {
          final dreamData = doc.data() as Map<String, dynamic>;
          dreamData['id'] = doc.id;
          
          final dream = Dream.fromMap(dreamData);
          newDreams.add(dream);
          
          if (dream.analysis != null && dream.analysis != 'Analiz yapılıyor...') {
            debugPrint('✅ Dream analysis updated: ${dream.id}');
          }
        } catch (e) {
          debugPrint('❌ Error parsing dream document ${doc.id}: $e');
        }
      }
      
      _dreams = newDreams;
      _safeNotify();
      
    } catch (e) {
      debugPrint('❌ Error processing snapshot: $e');
    }
  }

  void stopListeningToDreams() {
    if (_dreamsSubscription != null) {
      debugPrint('🛑 Stopping dreams listener...');
      _dreamsSubscription?.cancel();
      _dreamsSubscription = null;
    }
  }

  void startListeningToAuthenticatedUser() {
    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('🔐 User authenticated, starting dream listener for: ${user.uid}');
      Future.microtask(() => loadDreams());
    } else {
      debugPrint('🔐 No authenticated user, stopping listener');
      stopListeningToDreams();
    }
  }

  Future<void> loadDreams() async {
    if (_isLoading) {
      debugPrint('⚠️ Already loading dreams');
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
      debugPrint('✅ Dreams loaded successfully with real-time listener');
      
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
      await Future.delayed(Duration(milliseconds: 500));
      startListeningToDreams();
      
      debugPrint('✅ Dreams refreshed');
    } catch (e) {
      debugPrint('❌ Error refreshing dreams: $e');
    }
  }

  Future<bool> startRecording() async {
    debugPrint('🔴 START RECORDING CALLED');
    try {
      _setLoading(true);
      _clearError();

      await _ensureRecorderInitialized();
      
      if (!_isRecorderInitialized) {
        debugPrint('❌ Recorder not initialized');
        _setError('Ses kaydedici başlatılamadı');
        return false;
      }

      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        debugPrint('❌ No microphone permission');
        _setError('Mikrofon izni gerekli');
        return false;
      }

      final String fileName = 'dream_${DateTime.now().millisecondsSinceEpoch}.wav';
      final Directory tempDir = Directory.systemTemp;
      _currentRecordingPath = '${tempDir.path}/$fileName';
      
      debugPrint('📁 Recording path: $_currentRecordingPath');

      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.pcm16,
        bitRate: 128000,
        sampleRate: 44100,
      );

      _isRecording = true;
      debugPrint('🎤 Recording started successfully!');
      _safeNotify();
      return true;
    } catch (e) {
      debugPrint('❌ Recording start error: $e');
      _setError('Kayıt başlatılırken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> stopRecordingAndSave() async {
    debugPrint('🛑 STOP RECORDING CALLED');
    try {
      _setLoading(true);
      _clearError();

      if (!_isRecording || _currentRecordingPath == null) {
        debugPrint('❌ Not recording or no path');
        _setError('Kayıt yapılmıyor');
        return false;
      }

      debugPrint('⏹️ Stopping recorder...');
      await _recorder!.stopRecorder();
      _isRecording = false;

      final File audioFile = File(_currentRecordingPath!);
      if (!audioFile.existsSync()) {
        debugPrint('❌ Audio file does not exist');
        _setError('Ses dosyası oluşturulamadı');
        return false;
      }

      final int fileSize = audioFile.lengthSync();
      debugPrint('📁 Audio file size: $fileSize bytes');

      if (fileSize == 0) {
        debugPrint('❌ Audio file is empty');
        _setError('Ses dosyası boş');
        return false;
      }

      debugPrint('☁️ Uploading audio file to Firebase Storage...');
      final String downloadUrl = await _uploadAudioToStorage(audioFile);
      debugPrint('✅ Audio uploaded successfully: $downloadUrl');
      
      debugPrint('📝 Creating dream document in Firestore...');
      final Dream newDream = await createDreamRecord(downloadUrl, audioFile.path);
      debugPrint('✅ Dream document created: ${newDream.id}');

      try {
        await audioFile.delete();
        debugPrint('🗑️ Temporary file cleaned up');
      } catch (e) {
        debugPrint('⚠️ Could not delete temp file: $e');
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Stop recording error: $e');
      _setError('Rüya kaydedilirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Dream> uploadAudioFile(File audioFile) async {
    debugPrint('📤 uploadAudioFile called with: ${audioFile.path}');
    
    try {
      _setLoading(true);
      _clearError();

      if (!audioFile.existsSync()) {
        throw Exception('Ses dosyası bulunamadı');
      }

      final int fileSize = audioFile.lengthSync();
      if (fileSize == 0) {
        throw Exception('Ses dosyası boş');
      }

      debugPrint('📁 Audio file size: $fileSize bytes');

      debugPrint('☁️ Uploading to Firebase Storage...');
      final String downloadUrl = await _uploadAudioToStorage(audioFile);
      debugPrint('✅ Upload successful: $downloadUrl');

      debugPrint('📝 Creating dream record...');
      final Dream newDream = await createDreamRecord(downloadUrl, audioFile.path);
      debugPrint('✅ Dream created: ${newDream.id}');

      try {
        if (audioFile.path.contains('temp') || audioFile.path.contains('cache')) {
          await audioFile.delete();
          debugPrint('🗑️ Temporary file deleted');
        }
      } catch (e) {
        debugPrint('⚠️ Could not delete file: $e');
      }

      return newDream;
    } catch (e) {
      debugPrint('❌ uploadAudioFile error: $e');
      _setError('Dosya yüklenirken hata oluştu: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<String> _uploadAudioToStorage(File audioFile) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    debugPrint('📤 Starting Firebase Storage upload for user: ${user.uid}');

    final String fileName = 'dream_${DateTime.now().millisecondsSinceEpoch}.aac';
    final Reference storageRef = _storage
        .ref()
        .child('users')
        .child(user.uid)
        .child('dreams')
        .child(fileName);

    debugPrint('📂 Storage path: users/${user.uid}/dreams/$fileName');

    final SettableMetadata metadata = SettableMetadata(
      contentType: 'audio/aac',
      customMetadata: {
        'uploadedBy': user.uid,
        'uploadedAt': DateTime.now().toIso8601String(),
        'fileSize': audioFile.lengthSync().toString(),
      },
    );

    try {
      debugPrint('⬆️ Starting upload...');
      final UploadTask uploadTask = storageRef.putFile(audioFile, metadata);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ Upload completed successfully');
      debugPrint('🔗 Download URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Firebase Storage upload failed: $e');
      throw Exception('Firebase Storage upload başarısız: $e');
    }
  }

  Future<Dream> createDreamRecord(String audioUrl, String originalPath) async {
    debugPrint('🔄 Creating dream record...');
    
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    final String dreamId = _generateDreamId();
    
    final Dream newDream = Dream(
      id: dreamId,
      userId: user.uid,
      audioUrl: audioUrl,
      fileName: originalPath.split('/').last,
      title: 'Yeni Rüya Kaydı',
      dreamText: null,
      analysis: 'Analiz yapılıyor...',
      mood: 'Belirsiz',
      status: DreamStatus.processing,
      createdAt: DateTime.now(),
    );

    try {
      final dreamMap = newDream.toMap();
      await _firestore.collection('dreams').doc(dreamId).set(dreamMap);
      debugPrint('✅ Dream document created in Firestore: $dreamId');
      
      if (_dreamsSubscription == null) {
        startListeningToDreams();
      }
      
      // Background workflow trigger
      _triggerN8NWorkflow(dreamId, audioUrl).then((_) {
        debugPrint('✅ Background N8N workflow completed for: $dreamId');
      }).catchError((error) {
        debugPrint('❌ Background N8N workflow error: $error');
      });
      
      return newDream;
    } catch (e) {
      debugPrint('❌ Failed to create dream document: $e');
      throw Exception('Firestore document oluşturulamadı: $e');
    }
  }

  Future<void> _triggerN8NWorkflow(String dreamId, String audioUrl) async {
    try {
      debugPrint('🚀 Triggering N8N workflow for dream: $dreamId');
      
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No user available for N8N workflow');
        return;
      }
      
      debugPrint('👤 Triggering workflow for user: ${user.uid}');
      
      final analysisResult = await _n8nService.triggerDreamAnalysisWithHistory(
        dreamId: dreamId, 
        audioUrl: audioUrl, 
        user: user,
      );
      
      if (analysisResult != null) {
        debugPrint('✅ N8N analysis completed successfully');
        debugPrint('📊 Analysis result: ${analysisResult.keys.join(', ')}');
        
        await _updateFirestoreWithAnalysis(dreamId, analysisResult);
        
      } else {
        debugPrint('❌ Failed to get analysis from N8N');
        
        await _firestore.collection('dreams').doc(dreamId).update({
          'status': 'failed',
          'analysis': 'Analiz başlatılamadı. Lütfen tekrar deneyin.',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      debugPrint('💥 Error triggering N8N workflow: $e');
      
      try {
        await _firestore.collection('dreams').doc(dreamId).update({
          'status': 'failed',
          'analysis': 'Analiz sırasında hata oluştu: $e',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } catch (updateError) {
        debugPrint('❌ Failed to update dream status: $updateError');
      }
    }
  }

  // 🔥 YENİ FORMAT: baslik, duygular, semboller, analiz, ruhSagligi
  Future<void> _updateFirestoreWithAnalysis(
  String dreamId, 
  Map<String, dynamic> analysisResult
) async {
  try {
    debugPrint('💾 Updating Firestore with NEW FORMAT analysis for dream: $dreamId');
    
    // DÜZELTME: ruhSagligi hem camelCase hem snake_case kontrol et
    final ruhSagligiValue = analysisResult['ruhSagligi'] ?? 
                           analysisResult['ruh_sagligi'] ?? '';
    
    final Map<String, dynamic> updateData = {
      'dreamText': analysisResult['dreamText'] ?? '',
      'dream_text': analysisResult['dreamText'] ?? '',
      
      'title': analysisResult['baslik'] ?? 'Başlıksız Rüya',
      'baslik': analysisResult['baslik'] ?? 'Başlıksız Rüya',
      
      // Duygular
      'mood': analysisResult['duygular']?['anaDuygu'] ?? 
              analysisResult['duygular']?['ana_duygu'] ?? 'Belirsiz',
      'duygular': analysisResult['duygular'] ?? {
        'anaDuygu': 'Belirsiz',
        'altDuygular': []
      },
      
      // Semboller
      'symbols': analysisResult['semboller'] ?? [],
      'semboller': analysisResult['semboller'] ?? [],
      
      // Analiz
      'analysis': analysisResult['analiz'] ?? '',
      'analiz': analysisResult['analiz'] ?? '',
      'interpretation': analysisResult['analiz'] ?? '',
      
      // DÜZELTME: Ruh Sağlığı - her iki format da
      'ruhSagligi': ruhSagligiValue,
      'ruh_sagligi': ruhSagligiValue,
      
      'status': 'completed',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    };
    
    await _firestore.collection('dreams').doc(dreamId).update(updateData);
    
    debugPrint('✅ Firestore updated successfully with new format');
    debugPrint('📝 Title: ${analysisResult['baslik']}');
    debugPrint('😊 Ana Duygu: ${analysisResult['duygular']?['anaDuygu']}');
    debugPrint('🔮 Semboller: ${analysisResult['semboller']}');
    debugPrint('❤️ Ruh Sağlığı: ${ruhSagligiValue.substring(0, min<int>(50, ruhSagligiValue.length))}...');
    
  } catch (e) {
    debugPrint('❌ Error updating Firestore: $e');
    
    try {
      await _firestore.collection('dreams').doc(dreamId).update({
        'status': 'failed',
        'analysis': 'Sonuç kaydedilemedi: $e',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (updateError) {
      debugPrint('❌ Failed to update status: $updateError');
    }
  }
}

  // 🔥 YENİ FORMAT için güncellendi
  Future<void> updateDreamWithAnalysis({
    required String dreamId,
    required String dreamText,
    required String baslik,
    required Map<String, dynamic> duygular,
    required List<String> semboller,
    required String analiz,
    required String ruhSagligi,
  }) async {
    try {
      debugPrint('🔄 Updating dream $dreamId with NEW FORMAT analysis');
      
      final Map<String, dynamic> updateData = {
        'dreamText': dreamText,
        'dream_text': dreamText,
        
        'title': baslik,
        'baslik': baslik,
        
        'mood': duygular['ana_duygu'] ?? 'Belirsiz',
        'duygular': duygular,
        
        'symbols': semboller,
        'semboller': semboller,
        
        'analysis': analiz,
        'analiz': analiz,
        'interpretation': analiz,
        
        'ruhSagligi': ruhSagligi,
        'ruh_sagligi': ruhSagligi,
        
        'status': 'completed',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updated_at': Timestamp.fromDate(DateTime.now()),
      };
      
      await _firestore.collection('dreams').doc(dreamId).update(updateData);
      debugPrint('✅ Dream analysis updated successfully in Firestore');
      
    } catch (e) {
      debugPrint('❌ Error updating dream with analysis: $e');
      
      try {
        await _firestore.collection('dreams').doc(dreamId).update({
          'status': 'failed',
          'analysis': 'Analiz tamamlanamadı: $e',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'updated_at': Timestamp.fromDate(DateTime.now()),
        });
      } catch (updateError) {
        debugPrint('❌ Failed to mark dream as failed: $updateError');
      }
    }
  }

  Future<void> checkDreamStatus(String dreamId) async {
    try {
      debugPrint('🔍 Checking status for dream: $dreamId');
      
      final doc = await _firestore.collection('dreams').doc(dreamId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('📊 Dream status: ${data['status']}');
        
        if (data['analysis'] != null) {
          final analysisPreview = data['analysis'].toString();
          debugPrint('📊 Analysis: ${analysisPreview.substring(0, min<int>(50, analysisPreview.length))}...');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking dream status: $e');
    }
  }

  Future<void> cancelRecording() async {
    debugPrint('❌ CANCEL RECORDING CALLED');
    try {
      if (_isRecording) {
        await _recorder!.stopRecorder();
        _isRecording = false;
        
        if (_currentRecordingPath != null) {
          final File file = File(_currentRecordingPath!);
          if (file.existsSync()) {
            await file.delete();
            debugPrint('🗑️ Temp file deleted on cancel');
          }
        }
        
        debugPrint('✅ Recording cancelled');
        _safeNotify();
      }
    } catch (e) {
      debugPrint('❌ Cancel recording error: $e');
    }
  }

  String _generateDreamId() {
    return 'dream_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  String _generateTitleFromText(String text) {
    if (text.isEmpty) return 'Başlıksız Rüya';
    if (text.length <= 30) return text;
    return '${text.substring(0, 30)}...';
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