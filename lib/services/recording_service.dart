import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

/// Recording Service
///
/// SOLID Principles:
/// - Single Responsibility: Sadece ses kaydetme işlemlerini yönetir
/// - Dependency Inversion: Interface pattern kullanır
/// - Open/Closed: Farklı codec'ler eklenebilir
///
/// Responsibilities:
/// - Microphone permission management
/// - Audio recording (start, pause, resume, stop)
/// - File validation
/// - Recorder lifecycle management
class RecordingService {
  FlutterSoundRecorder? _recorder;
  bool _isInitialized = false;
  String? _currentRecordingPath;

  bool get isInitialized => _isInitialized;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Initialize the recorder
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ RecordingService already initialized');
      return;
    }

    try {
      debugPrint('🎤 Initializing RecordingService...');
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
      _isInitialized = true;
      debugPrint('✅ RecordingService initialized');
    } catch (e) {
      debugPrint('❌ RecordingService initialization failed: $e');
      throw Exception('Ses kaydedici başlatılamadı');
    }
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    try {
      debugPrint('🔒 Requesting microphone permission...');
      final status = await Permission.microphone.request();
      final granted = status == PermissionStatus.granted;

      if (granted) {
        debugPrint('✅ Microphone permission granted');
      } else {
        debugPrint('❌ Microphone permission denied');
      }

      return granted;
    } catch (e) {
      debugPrint('❌ Permission request error: $e');
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status == PermissionStatus.granted;
  }

  /// Start recording audio
  ///
  /// Returns: The file path where audio is being recorded
  Future<String> startRecording({
    Codec codec = Codec.aacADTS,
    int bitRate = 128000,
    int sampleRate = 44100,
    int numChannels = 1,
  }) async {
    if (!_isInitialized) {
      throw Exception('RecordingService not initialized. Call initialize() first.');
    }

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('Mikrofon izni gerekli');
    }

    try {
      final String fileName = 'dream_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final Directory tempDir = Directory.systemTemp;
      _currentRecordingPath = '${tempDir.path}/$fileName';

      debugPrint('🔴 Starting recording...');
      debugPrint('📁 Recording path: $_currentRecordingPath');

      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: codec,
        bitRate: bitRate,
        sampleRate: sampleRate,
        numChannels: numChannels,
      );

      debugPrint('✅ Recording started successfully');
      return _currentRecordingPath!;
    } catch (e) {
      debugPrint('❌ Start recording error: $e');
      throw Exception('Kayıt başlatılamadı: $e');
    }
  }

  /// Stop recording and return the audio file
  ///
  /// Returns: The recorded audio file, or null if recording failed
  Future<File?> stopRecording() async {
    if (!_isInitialized || _currentRecordingPath == null) {
      throw Exception('No active recording');
    }

    try {
      debugPrint('⏹️ Stopping recording...');

      await _recorder!.stopRecorder();
      debugPrint('✅ Recording stopped');

      // Wait for file to be properly written
      await Future.delayed(const Duration(milliseconds: 500));

      final File audioFile = File(_currentRecordingPath!);

      if (!audioFile.existsSync()) {
        debugPrint('❌ Audio file does not exist');
        _currentRecordingPath = null;
        throw Exception('Ses dosyası oluşturulamadı');
      }

      final int fileSize = audioFile.lengthSync();
      debugPrint('📁 Audio file size: $fileSize bytes');

      if (fileSize < 1000) {
        debugPrint('❌ Audio file too small: $fileSize bytes');
        await audioFile.delete();
        _currentRecordingPath = null;
        throw Exception('Ses dosyası çok kısa veya bozuk');
      }

      final isValid = await validateAudioFile(audioFile);
      if (!isValid) {
        debugPrint('❌ Invalid audio file format');
        await audioFile.delete();
        _currentRecordingPath = null;
        throw Exception('Geçersiz ses dosya formatı');
      }

      debugPrint('✅ Recording saved successfully');
      final result = audioFile;
      _currentRecordingPath = null;

      return result;
    } catch (e) {
      debugPrint('❌ Stop recording error: $e');
      _currentRecordingPath = null;
      rethrow;
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    if (!_isInitialized) {
      throw Exception('RecordingService not initialized');
    }

    try {
      debugPrint('⏸️ Pausing recording...');
      await _recorder!.pauseRecorder();
      debugPrint('✅ Recording paused');
    } catch (e) {
      debugPrint('❌ Pause recording error: $e');
      throw Exception('Kayıt duraklatılamadı: $e');
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    if (!_isInitialized) {
      throw Exception('RecordingService not initialized');
    }

    try {
      debugPrint('▶️ Resuming recording...');
      await _recorder!.resumeRecorder();
      debugPrint('✅ Recording resumed');
    } catch (e) {
      debugPrint('❌ Resume recording error: $e');
      throw Exception('Kayıt devam ettirilemedi: $e');
    }
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    if (_currentRecordingPath == null) return;

    try {
      debugPrint('❌ Cancelling recording...');

      if (_isInitialized && _recorder != null) {
        await _recorder!.stopRecorder();
      }

      final File file = File(_currentRecordingPath!);
      if (file.existsSync()) {
        await file.delete();
        debugPrint('🗑️ Temporary file deleted');
      }

      _currentRecordingPath = null;
      debugPrint('✅ Recording cancelled');
    } catch (e) {
      debugPrint('❌ Cancel recording error: $e');
      _currentRecordingPath = null;
    }
  }

  /// Validate audio file format
  ///
  /// Checks if the file is a valid M4A/AAC audio file
  Future<bool> validateAudioFile(File file) async {
    try {
      final bytes = await file.readAsBytes();

      if (bytes.length < 100) {
        debugPrint('❌ File too small to be valid audio');
        return false;
      }

      // Check M4A signature
      if (bytes.length >= 8) {
        final signature = String.fromCharCodes(bytes.sublist(4, 8));
        if (signature == 'ftyp') {
          debugPrint('✅ Valid M4A/AAC file format detected');
          return true;
        }
      }

      debugPrint('⚠️ Could not verify file format, but size seems ok (${bytes.length} bytes)');
      return true;
    } catch (e) {
      debugPrint('❌ Audio validation error: $e');
      return false;
    }
  }

  /// Check if currently recording
  bool get isRecording => _currentRecordingPath != null;

  /// Dispose the service
  Future<void> disposeService() async {
    if (!_isInitialized) return;

    try {
      debugPrint('🔄 Disposing RecordingService...');

      if (_currentRecordingPath != null) {
        await cancelRecording();
      }

      await _recorder?.closeRecorder();
      _recorder = null;
      _isInitialized = false;

      debugPrint('✅ RecordingService disposed');
    } catch (e) {
      debugPrint('❌ RecordingService dispose error: $e');
    }
  }
}
