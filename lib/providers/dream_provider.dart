import 'package:flutter/material.dart';
import '../models/dream_model.dart';

class DreamProvider extends ChangeNotifier {
  List<Dream> _dreams = [];
  List<Dream> get dreams => _dreams;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;


  // Fetch user's dreams (mock data for testing)
  Future<void> fetchDreams() async {
    try {
      _setLoading(true);
      _clearError();

      // Mock data for testing
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      _dreams = [
        Dream(
          id: '1',
          userId: 'demo_user',
          title: 'Uçma Rüyası',
          dreamText: 'Uçtuğum bir rüya gördüm, çok güzeldi! Bulutların arasından geçiyordum.',
          content: 'Uçtuğum bir rüya gördüm, çok güzeldi! Bulutların arasından geçiyordum.',
          analysis: 'Uçma rüyaları genellikle özgürlük arzusu ve yaşamınızda yeni bir perspektif elde etme isteğinizi simgeler.',
          mood: 'Mutlu',
          status: DreamStatus.completed,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Dream(
          id: '2',
          userId: 'demo_user',
          title: 'Denizde Yüzme',
          dreamText: 'Denizde yüzdüğüm bir rüya. Sular berraktı ve çok huzurlu hissediyordum.',
          content: 'Denizde yüzdüğüm bir rüya. Sular berraktı ve çok huzurlu hissediyordum.',
          analysis: 'Su ile ilgili rüyalar duygusal durumunuzu yansıtır. Berrak suda yüzmek huzur ve iç barışı ifade eder.',
          mood: 'Huzurlu',
          status: DreamStatus.completed,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Dream(
          id: '3',
          userId: 'demo_user',
          title: 'Eski Evim',
          dreamText: 'Eski evimde geziniyordum. Her oda çok tanıdık geliyordu.',
          content: 'Eski evimde geziniyordum. Her oda çok tanıdık geliyordu.',
          analysis: 'Analiz yapılıyor... Bu rüya geçmişinizle bağlantılı anılarınızı işaret ediyor olabilir.',
          mood: 'Nostaljik',
          status: DreamStatus.processing,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        Dream(
          id: '4',
          userId: 'demo_user',
          title: 'Karanlık Yol',
          dreamText: 'Karanlık bir yerde kaybolmuştum. Çıkışı bulamıyordum.',
          content: 'Karanlık bir yerde kaybolmuştum. Çıkışı bulamıyordum.',
          analysis: 'Kaybolma rüyaları belirsizlik ve karar verme zorluğu yaşadığınız durumları simgeleyebilir.',
          mood: 'Kaygılı',
          status: DreamStatus.completed,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Dream(
          id: '5',
          userId: 'demo_user',
          title: 'Yağmur Altında',
          dreamText: 'Yağmur altında yürüyordum ama ıslanmıyordum.',
          content: 'Yağmur altında yürüyordum ama ıslanmıyordum.',
          analysis: 'Yağmur korunma ihtiyacı hissettiğiniz durumları simgeleyebilir.',
          mood: 'Huzurlu',
          status: DreamStatus.processing,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];

      notifyListeners();
    } catch (e) {
      _setError('Rüyalar yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Mock start recording
  Future<bool> startRecording() async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate recording start delay
      await Future.delayed(const Duration(milliseconds: 500));

      _isRecording = true;

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Kayıt başlatılırken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mock stop recording and save dream
  Future<bool> stopRecordingAndSave() async {
    try {
      _setLoading(true);
      _clearError();

      if (!_isRecording) {
        _setError('Kayıt yapılmıyor');
        return false;
      }

      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));

      _isRecording = false;

      // Create new dream
      final newDream = Dream(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'demo_user',
        audioUrl: 'mock_audio.m4a',
        fileName: 'dream_${DateTime.now().millisecondsSinceEpoch}.m4a',
        title: 'Yeni Rüya Kaydı',
        dreamText: 'Yeni kaydedilen rüya (demo)',
        content: 'Yeni kaydedilen rüya (demo)',
        analysis: 'Analiz yapılıyor...',
        mood: 'Belirsiz',
        createdAt: DateTime.now(),
        status: DreamStatus.processing,
      );
      
      // Add to local list
      _dreams.insert(0, newDream);

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
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Cancel recording error: $e');
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void _setError(String error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
}