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
  
  // Firebase instances  
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final N8nService _n8nService = N8nService();
  
  // Real-time listener
  StreamSubscription<QuerySnapshot>? _dreamsSubscription;

  DreamProvider() {
    debugPrint('🏗️ DreamProvider initialized');
    _initializeRecorder();
  }

  // Initialize audio recorder
  Future<void> _initializeRecorder() async {
    try {
      debugPrint('🎤 Initializing recorder...');
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
      debugPrint('✅ Recorder initialized successfully');
    } catch (e) {
      debugPrint('❌ Recorder initialization failed: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('🔄 Disposing DreamProvider...');
    stopListeningToDreams();
    _recorder?.closeRecorder();
    super.dispose();
  }

  // Request microphone permission
  Future<bool> _requestMicrophonePermission() async {
    debugPrint('🔒 Requesting microphone permission...');
    final status = await Permission.microphone.request();
    final granted = status == PermissionStatus.granted;
    debugPrint(granted ? '✅ Microphone permission granted' : '❌ Microphone permission denied');
    return granted;
  }

  // Real-time listener for dreams
  void startListeningToDreams() {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint('🎧 Starting real-time listener for dreams...');
    
    _dreamsSubscription = _firestore
        .collection('dreams')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        debugPrint('🔄 Firestore snapshot received: ${snapshot.docs.length} dreams');
        
        _dreams.clear();
        for (var doc in snapshot.docs) {
          try {
            final dreamData = doc.data() as Map<String, dynamic>;
            dreamData['id'] = doc.id;
            
            final dream = Dream.fromMap(dreamData);
            _dreams.add(dream);
            
            // Log analysis updates
            if (dream.analysis != null && dream.analysis != 'Analiz yapılıyor...') {
              debugPrint('✅ Dream analysis updated: ${dream.id} - ${dream.analysis?.substring(0, 50)}...');
            }
          } catch (e) {
            debugPrint('❌ Error parsing dream document ${doc.id}: $e');
          }
        }
        
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Firestore listener error: $error');
      },
    );
  }

  // Stop listening when provider is disposed
  void stopListeningToDreams() {
    debugPrint('🛑 Stopping dreams listener...');
    _dreamsSubscription?.cancel();
    _dreamsSubscription = null;
  }

  // Auth-aware listener starter
  void startListeningToAuthenticatedUser() {
    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('🔐 User authenticated, starting dream listener for: ${user.uid}');
      
      // Load dreams with real-time listener
      loadDreams();
    } else {
      debugPrint('🔐 No authenticated user, stopping listener');
      stopListeningToDreams();
    }
  }

  // Load dreams and start listener
  Future<void> loadDreams() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _setError('Kullanıcı oturumu bulunamadı');
        return;
      }

      debugPrint('📱 Loading dreams for user: ${user.uid}');
      
      // Start real-time listener instead of one-time fetch
      startListeningToDreams();
      
      debugPrint('✅ Dreams loaded successfully with real-time listener');
      
    } catch (e) {
      debugPrint('❌ Error loading dreams: $e');
      _setError('Rüyalar yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Manual refresh method for pull-to-refresh
  Future<void> refreshDreams() async {
    debugPrint('🔄 Refreshing dreams...');
    
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Force refresh by stopping and starting listener
      stopListeningToDreams();
      await Future.delayed(Duration(milliseconds: 500));
      startListeningToDreams();
      
      debugPrint('✅ Dreams refreshed');
    } catch (e) {
      debugPrint('❌ Error refreshing dreams: $e');
    }
  }

  // Legacy fetch method (keeping for compatibility)
  Future<void> fetchDreams() async {
    debugPrint('📥 Fetching dreams (legacy method)...');
    try {
      _setLoading(true);
      _clearError();

      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user');
        _setError('Kullanıcı oturumu bulunamadı');
        return;
      }

      debugPrint('👤 Fetching dreams for user: ${user.uid}');

      final QuerySnapshot querySnapshot = await _firestore
          .collection('dreams')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('📊 Found ${querySnapshot.docs.length} dreams in Firestore');

      _dreams = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Dream.fromMap(data);
      }).toList();

      debugPrint('✅ Successfully loaded ${_dreams.length} dreams');
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ Error fetching dreams: $e');
      _setError('Rüyalar yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper method - tarih parsing için
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        debugPrint('⚠️ Unknown datetime format: ${value.runtimeType}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error parsing datetime: $e');
      return null;
    }
  }

  // Status parsing method
  DreamStatus _parseStatus(dynamic status) {
    if (status == null) return DreamStatus.processing;
    
    final statusString = status.toString().toLowerCase();
    switch (statusString) {
      case 'completed':
        return DreamStatus.completed;
      case 'failed':
        return DreamStatus.failed;
      case 'processing':
      default:
        return DreamStatus.processing;
    }
  }

  // Start recording
  Future<bool> startRecording() async {
    debugPrint('🔴 START RECORDING CALLED');
    try {
      _setLoading(true);
      _clearError();

      // Request microphone permission
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        debugPrint('❌ No microphone permission');
        _setError('Mikrofon izni gerekli');
        return false;
      }

      // Create temporary file path
      final String fileName = 'dream_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final Directory tempDir = Directory.systemTemp;
      _currentRecordingPath = '${tempDir.path}/$fileName';
      
      debugPrint('📁 Recording path: $_currentRecordingPath');

      // Start recording
      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacMP4,
        bitRate: 128000,
        sampleRate: 44100,
      );

      _isRecording = true;
      debugPrint('🎤 Recording started successfully!');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Recording start error: $e');
      _setError('Kayıt başlatılırken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Stop recording and save dream
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

      // Stop recording
      debugPrint('⏹️ Stopping recorder...');
      await _recorder!.stopRecorder();
      _isRecording = false;

      // Check if file exists and has content
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

      // Upload to Firebase Storage
      debugPrint('☁️ Uploading audio file to Firebase Storage...');
      final String downloadUrl = await _uploadAudioToStorage(audioFile);
      debugPrint('✅ Audio uploaded successfully: $downloadUrl');
      
      // Create dream document in Firestore
      debugPrint('📝 Creating dream document in Firestore...');
      final Dream newDream = await createDreamRecord(downloadUrl, audioFile.path);
      debugPrint('✅ Dream document created: ${newDream.id}');

      // Clean up temporary file
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

  // Upload audio file to Firebase Storage
  Future<String> _uploadAudioToStorage(File audioFile) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    debugPrint('📤 Starting Firebase Storage upload for user: ${user.uid}');

    final String fileName = 'dream_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final Reference storageRef = _storage
        .ref()
        .child('users')
        .child(user.uid)
        .child('dreams')
        .child(fileName);

    debugPrint('📂 Storage path: users/${user.uid}/dreams/$fileName');

    // Upload file with metadata
    final SettableMetadata metadata = SettableMetadata(
      contentType: 'audio/mp4',
      customMetadata: {
        'uploadedBy': user.uid,
        'uploadedAt': DateTime.now().toIso8601String(),
        'fileSize': audioFile.lengthSync().toString(),
      },
    );

    try {
      debugPrint('⬆️ Starting upload...');
      final UploadTask uploadTask = storageRef.putFile(audioFile, metadata);
      
      // Show upload progress
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

  // Create dream record (updated with real-time listener)
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
      content: null,
      analysis: 'Analiz yapılıyor...',
      mood: 'Belirsiz',
      status: DreamStatus.processing,
      createdAt: DateTime.now(),
    );

    try {
      // Save to Firestore with both field formats for compatibility
      final dreamMap = newDream.toMap();
      await _firestore.collection('dreams').doc(dreamId).set(dreamMap);
      debugPrint('✅ Dream document created in Firestore: $dreamId');
      
      // Start listening if not already listening
      if (_dreamsSubscription == null) {
        startListeningToDreams();
      }
      
      // 🔥 ÖNEMLİ: Yeni N8N workflow'unu tetikle (önceki rüyalarla birlikte)
      await _triggerN8NWorkflow(dreamId, audioUrl);
      
      return newDream;
    } catch (e) {
      debugPrint('❌ Failed to create dream document: $e');
      throw Exception('Firestore document oluşturulamadı: $e');
    }
  }

  // Legacy create dream document method
  Future<Dream> _createDreamDocument(String audioUrl, String originalPath) async {
    return await createDreamRecord(audioUrl, originalPath);
  }

  // 🔥 YENİ: Trigger N8N workflow with previous dreams history
  // YENİ VERSİYON: N8N'den response al ve Firestore'a yaz
Future<void> _triggerN8NWorkflow(String dreamId, String audioUrl) async {
  try {
    debugPrint('🚀 Triggering N8N workflow with history for dream: $dreamId');
    
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ No user available for N8N workflow');
      return;
    }
    
    debugPrint('👤 Triggering workflow for user: ${user.uid}');
    
    // N8N'e gönder ve RESPONSE AL
    final analysisResult = await _n8nService.triggerDreamAnalysisWithHistory(
      dreamId: dreamId, 
      audioUrl: audioUrl, 
      user: user,
    );
    
    if (analysisResult != null) {
      debugPrint('✅ N8N analysis completed successfully');
      debugPrint('📊 Analysis result: ${analysisResult.keys.join(', ')}');
      
      // Firestore'a yaz (Flutter'dan)
      await _updateFirestoreWithAnalysis(dreamId, analysisResult);
      
    } else {
      debugPrint('❌ Failed to get analysis from N8N');
      
      // Hata durumunda dream'i failed olarak işaretle
      await _firestore.collection('dreams').doc(dreamId).update({
        'status': 'failed',
        'analysis': 'Analiz başlatılamadı. Lütfen tekrar deneyin.',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  } catch (e) {
    debugPrint('💥 Error triggering N8N workflow: $e');
    
    // Hata durumunda dream'i failed olarak işaretle
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
Future<void> _updateFirestoreWithAnalysis(
  String dreamId, 
  Map<String, dynamic> analysisResult
) async {
  try {
    debugPrint('💾 Updating Firestore with analysis for dream: $dreamId');
    
    // Firestore'a yazılacak data
    final Map<String, dynamic> updateData = {
      'dreamText': analysisResult['dreamText'] ?? '',
      'dream_text': analysisResult['dreamText'] ?? '',
      'title': analysisResult['title'] ?? 'Başlıksız Rüya',
      'mood': analysisResult['mood'] ?? 'Belirsiz',
      'analysis': analysisResult['analysis'] ?? '',
      'interpretation': analysisResult['interpretation'] ?? '',
      'status': 'completed',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    };
    
    // Opsiyonel alanlar
    if (analysisResult['symbols'] != null) {
      updateData['symbols'] = analysisResult['symbols'];
    }
    
    if (analysisResult['connection_to_past'] != null && 
        analysisResult['connection_to_past'].toString().isNotEmpty) {
      updateData['connection_to_past'] = analysisResult['connection_to_past'];
      updateData['connectionToPast'] = analysisResult['connection_to_past'];
    }
    
    // Firestore'a yaz
    await _firestore.collection('dreams').doc(dreamId).update(updateData);
    
    debugPrint('✅ Firestore updated successfully');
    
  } catch (e) {
    debugPrint('❌ Error updating Firestore: $e');
    
    // En azından status'u completed yap
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
  // Update dream with analysis results (Snake case compatible)
  Future<void> updateDreamWithAnalysis({
    required String dreamId,
    required String dreamText,
    required String analysis,
    required String mood,
    String? title,
    List<String>? symbols,
    String? interpretation,
    String? connectionToPast,
  }) async {
    try {
      debugPrint('🔄 Updating dream $dreamId with analysis results');
      
      // Update Firestore - Both camelCase and snake_case for compatibility
      final Map<String, dynamic> updateData = {
        'dreamText': dreamText,
        'dream_text': dreamText, // N8N compatible
        'content': dreamText,
        'analysis': analysis,
        'mood': mood,
        'title': title ?? _generateTitleFromText(dreamText),
        'status': 'completed',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updated_at': Timestamp.fromDate(DateTime.now()), // N8N compatible
      };
      
      // Opsiyonel alanlar
      if (symbols != null && symbols.isNotEmpty) {
        updateData['symbols'] = symbols;
      }
      
      if (interpretation != null && interpretation.isNotEmpty) {
        updateData['interpretation'] = interpretation;
      }
      
      // 🆕 Önceki rüyalarla bağlantı
      if (connectionToPast != null && connectionToPast.isNotEmpty) {
        updateData['connection_to_past'] = connectionToPast;
        updateData['connectionToPast'] = connectionToPast;
      }
      
      await _firestore.collection('dreams').doc(dreamId).update(updateData);

      // Real-time listener will handle local list updates automatically
      debugPrint('✅ Dream analysis updated successfully in Firestore');
      
    } catch (e) {
      debugPrint('❌ Error updating dream with analysis: $e');
      
      // Mark dream as failed
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

  // Force check for specific dream updates
  Future<void> checkDreamStatus(String dreamId) async {
    try {
      debugPrint('🔍 Checking status for dream: $dreamId');
      
      final doc = await _firestore.collection('dreams').doc(dreamId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('📊 Dream status: ${data['status']}');
        debugPrint('📊 Analysis: ${data['analysis']?.toString().substring(0, min(50, data['analysis']?.toString().length ?? 0))}...');
        debugPrint('📊 Dream text: ${data['dream_text']?.toString().substring(0, min(50, data['dream_text']?.toString().length ?? 0))}...');
        
        if (data['connection_to_past'] != null) {
          debugPrint('📊 Connection to past: ${data['connection_to_past'].toString().substring(0, min(50, data['connection_to_past'].toString().length))}...');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking dream status: $e');
    }
  }

  // Cancel recording
  Future<void> cancelRecording() async {
    debugPrint('❌ CANCEL RECORDING CALLED');
    try {
      if (_isRecording) {
        await _recorder!.stopRecorder();
        _isRecording = false;
        
        // Delete temporary file if exists
        if (_currentRecordingPath != null) {
          final File file = File(_currentRecordingPath!);
          if (file.existsSync()) {
            await file.delete();
            debugPrint('🗑️ Temp file deleted on cancel');
          }
        }
        
        debugPrint('✅ Recording cancelled');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Cancel recording error: $e');
    }
  }

  // Helper methods
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void _setError(String error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
}