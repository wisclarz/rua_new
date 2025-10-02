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
  bool _isRecorderInitialized = false; // ⚡ Track initialization state
  
  // Firebase instances  
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final N8nService _n8nService = N8nService();
  
  // Real-time listener
  StreamSubscription<QuerySnapshot>? _dreamsSubscription;

  DreamProvider() {
    debugPrint('🏗️ DreamProvider created (lightweight)');
    // ⚡ Don't initialize recorder here - do it lazily when needed
  }

  // ⚡ Lazy initialization - only when recording is needed
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
    if (user == null) {
      debugPrint('⚠️ No user, cannot start listener');
      return;
    }

    // Don't start if already listening
    if (_dreamsSubscription != null) {
      debugPrint('⚠️ Already listening to dreams');
      return;
    }

    debugPrint('🎧 Starting real-time listener for dreams...');
    
    _dreamsSubscription = _firestore
        .collection('dreams')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50) // ⚡ Limit to prevent loading too many at once
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

  // ⚡ Process snapshot efficiently
  void _processDreamsSnapshot(QuerySnapshot snapshot) {
    try {
      final newDreams = <Dream>[];
      
      for (var doc in snapshot.docs) {
        try {
          final dreamData = doc.data() as Map<String, dynamic>;
          dreamData['id'] = doc.id;
          
          final dream = Dream.fromMap(dreamData);
          newDreams.add(dream);
          
          // Log analysis updates
          if (dream.analysis != null && dream.analysis != 'Analiz yapılıyor...') {
            debugPrint('✅ Dream analysis updated: ${dream.id}');
          }
        } catch (e) {
          debugPrint('❌ Error parsing dream document ${doc.id}: $e');
        }
      }
      
      // ⚡ Batch update
      _dreams = newDreams;
      _safeNotify();
      
    } catch (e) {
      debugPrint('❌ Error processing snapshot: $e');
    }
  }

  // Stop listening when provider is disposed
  void stopListeningToDreams() {
    if (_dreamsSubscription != null) {
      debugPrint('🛑 Stopping dreams listener...');
      _dreamsSubscription?.cancel();
      _dreamsSubscription = null;
    }
  }

  // Auth-aware listener starter
  void startListeningToAuthenticatedUser() {
    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('🔐 User authenticated, starting dream listener for: ${user.uid}');
      // ⚡ Use Future.microtask to avoid blocking
      Future.microtask(() => loadDreams());
    } else {
      debugPrint('🔐 No authenticated user, stopping listener');
      stopListeningToDreams();
    }
  }

  // Load dreams and start listener
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

  // Start recording - with lazy initialization
  Future<bool> startRecording() async {
    debugPrint('🔴 START RECORDING CALLED');
    try {
      _setLoading(true);
      _clearError();

      // ⚡ Ensure recorder is initialized (lazy)
      await _ensureRecorderInitialized();
      
      if (!_isRecorderInitialized) {
        debugPrint('❌ Recorder not initialized');
        _setError('Ses kaydedici başlatılamadı');
        return false;
      }

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

  Future<Dream> uploadAudioFile(File audioFile) async {
    debugPrint('📤 uploadAudioFile called with: ${audioFile.path}');
    
    try {
      _setLoading(true);
      _clearError();

      // Validate file
      if (!audioFile.existsSync()) {
        throw Exception('Ses dosyası bulunamadı');
      }

      final int fileSize = audioFile.lengthSync();
      if (fileSize == 0) {
        throw Exception('Ses dosyası boş');
      }

      debugPrint('📁 Audio file size: $fileSize bytes');

      // Upload to Firebase Storage
      debugPrint('☁️ Uploading to Firebase Storage...');
      final String downloadUrl = await _uploadAudioToStorage(audioFile);
      debugPrint('✅ Upload successful: $downloadUrl');

      // Create dream record
      debugPrint('📝 Creating dream record...');
      final Dream newDream = await createDreamRecord(downloadUrl, audioFile.path);
      debugPrint('✅ Dream created: ${newDream.id}');

      // Clean up the file if it's in temp directory
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

  // Create dream record
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
      // Save to Firestore
      final dreamMap = newDream.toMap();
      await _firestore.collection('dreams').doc(dreamId).set(dreamMap);
      debugPrint('✅ Dream document created in Firestore: $dreamId');
      
      // Start listening if not already listening
      if (_dreamsSubscription == null) {
        startListeningToDreams();
      }
      
      // Trigger N8N workflow
      await _triggerN8NWorkflow(dreamId, audioUrl);
      
      return newDream;
    } catch (e) {
      debugPrint('❌ Failed to create dream document: $e');
      throw Exception('Firestore document oluşturulamadı: $e');
    }
  }

  // Trigger N8N workflow with previous dreams history
  Future<void> _triggerN8NWorkflow(String dreamId, String audioUrl) async {
    try {
      debugPrint('🚀 Triggering N8N workflow with history for dream: $dreamId');
      
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No user available for N8N workflow');
        return;
      }
      
      debugPrint('👤 Triggering workflow for user: ${user.uid}');
      
      // Send to N8N and get response
      final analysisResult = await _n8nService.triggerDreamAnalysisWithHistory(
        dreamId: dreamId, 
        audioUrl: audioUrl, 
        user: user,
      );
      
      if (analysisResult != null) {
        debugPrint('✅ N8N analysis completed successfully');
        debugPrint('📊 Analysis result: ${analysisResult.keys.join(', ')}');
        
        // Update Firestore with analysis
        await _updateFirestoreWithAnalysis(dreamId, analysisResult);
        
      } else {
        debugPrint('❌ Failed to get analysis from N8N');
        
        // Mark dream as failed
        await _firestore.collection('dreams').doc(dreamId).update({
          'status': 'failed',
          'analysis': 'Analiz başlatılamadı. Lütfen tekrar deneyin.',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      debugPrint('💥 Error triggering N8N workflow: $e');
      
      // Mark dream as failed
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
      
      // Prepare update data
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
      
      // Optional fields
      if (analysisResult['symbols'] != null) {
        updateData['symbols'] = analysisResult['symbols'];
      }
      
      // Connection to past
      if (analysisResult['connectionToPast'] != null && 
          analysisResult['connectionToPast'].toString().trim().isNotEmpty) {
        final connectionValue = analysisResult['connectionToPast'].toString();
        updateData['connectionToPast'] = connectionValue;
        updateData['connection_to_past'] = connectionValue;
        debugPrint('✅ Adding connectionToPast to Firestore');
      }
      
      // Update Firestore
      await _firestore.collection('dreams').doc(dreamId).update(updateData);
      
      debugPrint('✅ Firestore updated successfully');
      
    } catch (e) {
      debugPrint('❌ Error updating Firestore: $e');
      
      // Mark as failed
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

  // Update dream with analysis results
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
      
      // Update Firestore
      final Map<String, dynamic> updateData = {
        'dreamText': dreamText,
        'dream_text': dreamText,
        'content': dreamText,
        'analysis': analysis,
        'mood': mood,
        'title': title ?? _generateTitleFromText(dreamText),
        'status': 'completed',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updated_at': Timestamp.fromDate(DateTime.now()),
      };
      
      if (symbols != null && symbols.isNotEmpty) {
        updateData['symbols'] = symbols;
      }
      
      if (interpretation != null && interpretation.isNotEmpty) {
        updateData['interpretation'] = interpretation;
      }
      
      if (connectionToPast != null && connectionToPast.isNotEmpty) {
        updateData['connection_to_past'] = connectionToPast;
        updateData['connectionToPast'] = connectionToPast;
      }
      
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

  // Check dream status
  Future<void> checkDreamStatus(String dreamId) async {
    try {
      debugPrint('🔍 Checking status for dream: $dreamId');
      
      final doc = await _firestore.collection('dreams').doc(dreamId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('📊 Dream status: ${data['status']}');
        
        if (data['analysis'] != null) {
          final analysisPreview = data['analysis'].toString();
          debugPrint('📊 Analysis: ${analysisPreview.substring(0, min(50, analysisPreview.length))}...');
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
        _safeNotify();
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

  // ⚡ Safe notify - prevents "called during build" errors
  void _safeNotify() {
    scheduleMicrotask(() {
      notifyListeners();
    });
  }
}