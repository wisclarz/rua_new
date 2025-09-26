import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:math';
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

  // Fetch user's dreams from Firestore
  Future<void> fetchDreams() async {
  debugPrint('📥 Fetching dreams...');
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
      return Dream(
        id: doc.id,
        userId: data['userId'] ?? '',
        audioUrl: data['audioUrl'],
        fileName: data['fileName'],
        title: data['title'],
        dreamText: data['dreamText'],
        content: data['content'],
        analysis: data['analysis'],
        mood: data['mood'],
        status: _parseStatus(data['status']),
        createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(data['updatedAt']),
      );
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

// Helper metodu ekleyin - tarih parsing için
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

// Status parsing metodunu da güncelleyin
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
      final Dream newDream = await _createDreamDocument(downloadUrl, audioFile.path);
      debugPrint('✅ Dream document created: ${newDream.id}');
      
      // Add to local list
      _dreams.insert(0, newDream);
      notifyListeners();

      // Trigger N8N workflow
      debugPrint('🤖 Triggering N8N workflow...');
      _triggerN8NWorkflow(newDream.id, downloadUrl);

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

  // Create dream document in Firestore
  Future<Dream> _createDreamDocument(String audioUrl, String originalPath) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    debugPrint('📝 Creating Firestore document for user: ${user.uid}');

    final String dreamId = _generateDreamId();
    final Dream newDream = Dream(
      id: dreamId,
      userId: user.uid,
      audioUrl: audioUrl,
      fileName: originalPath.split('/').last,
      title: 'Yeni Rüya Kaydı',
      dreamText: null, // Will be filled by OpenAI
      content: null,   // Will be filled by OpenAI
      analysis: 'Analiz yapılıyor...', // Will be updated by N8N workflow
      mood: 'Belirsiz',
      status: DreamStatus.processing,
      createdAt: DateTime.now(),
    );

    try {
      // Save to Firestore
      await _firestore.collection('dreams').doc(dreamId).set(newDream.toMap());
      debugPrint('✅ Dream document created in Firestore: $dreamId');
      
      return newDream;
    } catch (e) {
      debugPrint('❌ Failed to create dream document: $e');
      throw Exception('Firestore document oluşturulamadı: $e');
    }
  }

  // Trigger N8N workflow for dream analysis
  Future<void> _triggerN8NWorkflow(String dreamId, String audioUrl) async {
  try {
    debugPrint('🚀 Triggering N8N workflow for dream: $dreamId');
    
    // User bilgisini al
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ No user available for N8N workflow');
      return;
    }
    
    debugPrint('👤 Triggering workflow for user: ${user.uid}');
    
    // User bilgisi ile beraber çağır
    final success = await _n8nService.triggerDreamAnalysisWithUser(
      dreamId: dreamId, 
      audioUrl: audioUrl, 
      user: user,
    );
    
    if (success) {
      debugPrint('✅ N8N workflow triggered successfully');
    } else {
      debugPrint('❌ Failed to trigger N8N workflow');
    }
  } catch (e) {
    debugPrint('💥 Error triggering N8N workflow: $e');
  }
}

  // Update dream with analysis results (called by N8N webhook or manual update)
  Future<void> updateDreamWithAnalysis({
    required String dreamId,
    required String dreamText,
    required String analysis,
    required String mood,
    String? title,
  }) async {
    try {
      debugPrint('🔄 Updating dream $dreamId with analysis results');
      
      // Update Firestore
      await _firestore.collection('dreams').doc(dreamId).update({
        'dreamText': dreamText,
        'content': dreamText,
        'analysis': analysis,
        'mood': mood,
        'title': title ?? _generateTitleFromText(dreamText),
        'status': 'completed',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update local list
      final index = _dreams.indexWhere((dream) => dream.id == dreamId);
      if (index != -1) {
        _dreams[index] = _dreams[index].copyWith(
          dreamText: dreamText,
          content: dreamText,
          analysis: analysis,
          mood: mood,
          title: title ?? _generateTitleFromText(dreamText),
          status: DreamStatus.completed,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      debugPrint('✅ Dream analysis updated successfully');
      
    } catch (e) {
      debugPrint('❌ Error updating dream with analysis: $e');
      
      // Mark dream as failed
      try {
        await _firestore.collection('dreams').doc(dreamId).update({
          'status': 'failed',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } catch (updateError) {
        debugPrint('❌ Failed to mark dream as failed: $updateError');
      }
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