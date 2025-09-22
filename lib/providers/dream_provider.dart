import 'package:flutter/material.dart';
// Firebase temporarily disabled for UI development
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:record/record.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';

import '../models/dream_model.dart';
import '../services/n8n_service.dart';

class DreamProvider extends ChangeNotifier {
  // Firebase temporarily disabled for testing
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final AudioRecorder _audioRecorder = AudioRecorder(); // Temporarily disabled
  // final N8nService _n8nService = N8nService(); // Temporarily disabled

  List<Dream> _dreams = [];
  List<Dream> get dreams => _dreams;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _currentRecordingPath;

  // Fetch user's dreams (temporarily using mock data for testing)
  Future<void> fetchDreams() async {
    try {
      _setLoading(true);
      _clearError();

      // Mock data for testing - Firebase disabled
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      _dreams = [
        Dream(
          id: '1',
          userId: 'demo_user',
          dreamText: 'Uçtuğum bir rüya gördüm, çok güzeldi!',
          analysis: 'Uçma rüyaları genellikle özgürlük arzusu ve yaşamınızda yeni bir perspektif elde etme isteğinizi simgeler.',
          mood: 'Mutlu',
          status: DreamStatus.completed,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Dream(
          id: '2',
          userId: 'demo_user',
          dreamText: 'Denizde yüzdüğüm bir rüya',
          analysis: 'Su ile ilgili rüyalar duygusal durumunuzu yansıtır. Berrak suda yüzmek huzur ve iç barışı ifade eder.',
          mood: 'Huzurlu',
          status: DreamStatus.completed,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Dream(
          id: '3',
          userId: 'demo_user',
          dreamText: 'Eski evimde geziniyordum',
          analysis: 'Analiz yapılıyor... Bu rüya geçmişinizle bağlantılı anılarınızı işaret ediyor olabilir.',
          mood: 'Nostaljik',
          status: DreamStatus.processing,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        Dream(
          id: '4',
          userId: 'demo_user',
          dreamText: 'Karanlık bir yerde kaybolmuştum',
          analysis: 'Kaybolma rüyaları belirsizlik ve karar verme zorluğu yaşadığınız durumları simgeleyebilir.',
          mood: 'Kaygılı',
          status: DreamStatus.completed,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Dream(
          id: '5',
          userId: 'demo_user',
          dreamText: 'Arkadaşlarımla güzel bir parkta piknik yapıyorduk',
          analysis: 'Sosyal aktivite rüyaları bağlantı kurma ihtiyacınızı ve hayatınızdaki mutluluk arayışınızı gösterir.',
          mood: 'Neşeli',
          status: DreamStatus.completed,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];

      notifyListeners();
    } catch (e) {
      _setError('Rüyalar yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Mock start audio recording
  Future<bool> startRecording() async {
    try {
      // Simulate recording start
      await Future.delayed(const Duration(milliseconds: 500));
      
      _currentRecordingPath = 'mock_path/dream_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _isRecording = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Kayıt başlatılamadı: $e');
      return false;
    }
  }

  // Stop audio recording and save dream (Firebase temporarily disabled)
  Future<bool> stopRecordingAndSaveDream() async {
    try {
      if (!_isRecording || _currentRecordingPath == null) return false;

      _setLoading(true);
      
      // Mock stop recording
      await Future.delayed(const Duration(seconds: 1));
      _isRecording = false;
      notifyListeners();

      // Create mock dream
      final Dream newDream = Dream(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'demo_user',
        audioUrl: 'mock_audio.m4a',
        fileName: 'dream_${DateTime.now().millisecondsSinceEpoch}.m4a',
        dreamText: 'Yeni kaydedilen rüya (demo)',
        analysis: 'Analiz yapılıyor...',
        mood: 'Belirsiz',
        createdAt: DateTime.now(),
        status: DreamStatus.processing,
      );
      
      // Add to local list
      _dreams.insert(0, newDream);
      _currentRecordingPath = null;

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Rüya kaydedilirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mock cancel recording
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await Future.delayed(const Duration(milliseconds: 200));
        _isRecording = false;
        _currentRecordingPath = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Cancel recording error: $e');
    }
  }

  // Test Firestore connection (Firebase temporarily disabled)
  Future<bool> testFirestoreConnection() async {
    try {
      _setLoading(true);
      _clearError();

      // Firebase temporarily disabled - simulate connection test
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate successful connection
      return true;
    } catch (e) {
      _setError('Firestore bağlantı testi başarısız: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Test Firebase Storage upload (Firebase temporarily disabled)
  Future<bool> testStorageUpload() async {
    try {
      _setLoading(true);
      _clearError();

      // Firebase temporarily disabled - simulate storage test
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate successful upload
      return true;
    } catch (e) {
      _setError('Storage upload testi başarısız: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    // Audio recorder disabled for UI development
    // _audioRecorder.dispose();
    super.dispose();
  }
}
