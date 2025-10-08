import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// Recording yönetimi için controller sınıfı
/// Business logic'i UI'dan ayırarak performans ve sürdürülebilirlik sağlar
class RecordingController extends ChangeNotifier {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  bool _isPaused = false;
  String? _recordedFilePath;
  Duration _recordingDuration = Duration.zero;

  bool get isRecorderInitialized => _isRecorderInitialized;
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String? get recordedFilePath => _recordedFilePath;
  Duration get recordingDuration => _recordingDuration;

  Future<void> initialize() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Mikrofon izni gerekli');
      }

      await _recorder.openRecorder();
      _isRecorderInitialized = true;
      notifyListeners();
      debugPrint('✅ Recorder initialized');
    } catch (e) {
      debugPrint('❌ Recorder initialization error: $e');
      rethrow;
    }
  }

  Future<void> startRecording() async {
    if (!_isRecorderInitialized) {
      throw Exception('Mikrofon hazır değil');
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/dream_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      Codec selectedCodec = Codec.aacMP4;
      String fileExtension = '.m4a';
      
      try {
        await _recorder.startRecorder(
          toFile: filePath.replaceAll('.wav', fileExtension),
          codec: selectedCodec,
          audioSource: AudioSource.voice_recognition,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        );
      } catch (e) {
        debugPrint('⚠️ AAC not supported, trying Opus...');
        selectedCodec = Codec.opusOGG;
        fileExtension = '.ogg';
        
        try {
          await _recorder.startRecorder(
            toFile: filePath.replaceAll('.wav', fileExtension),
            codec: selectedCodec,
            bitRate: 128000,
            sampleRate: 44100,
            numChannels: 1,
          );
        } catch (e2) {
          debugPrint('⚠️ Opus not supported, using default codec...');
          await _recorder.startRecorder(
            toFile: filePath.replaceAll('.wav', '.aac'),
            codec: Codec.defaultCodec,
            bitRate: 128000,
            sampleRate: 44100,
            numChannels: 1,
          );
        }
      }

      _isRecording = true;
      _recordedFilePath = filePath;
      notifyListeners();
      
      _startDurationTimer();
      debugPrint('🎤 Recording started: $filePath');
    } catch (e) {
      debugPrint('❌ Start recording error: $e');
      rethrow;
    }
  }

  void _startDurationTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && !_isPaused) {
        _recordingDuration += const Duration(seconds: 1);
        notifyListeners();
        _startDurationTimer();
      }
    });
  }

  Future<void> pauseRecording() async {
    try {
      await _recorder.pauseRecorder();
      _isPaused = true;
      notifyListeners();
      debugPrint('⏸️ Recording paused');
    } catch (e) {
      debugPrint('❌ Pause error: $e');
      rethrow;
    }
  }

  Future<void> resumeRecording() async {
    try {
      await _recorder.resumeRecorder();
      _isPaused = false;
      notifyListeners();
      _startDurationTimer();
      debugPrint('▶️ Recording resumed');
    } catch (e) {
      debugPrint('❌ Resume error: $e');
      rethrow;
    }
  }

  Future<File?> stopRecording({bool shouldSave = true}) async {
    try {
      debugPrint('⏹️ Stopping recording...');
      
      _isRecording = false;
      _isPaused = false;
      notifyListeners();
      
      await _recorder.stopRecorder();
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!shouldSave) {
        debugPrint('🚫 Recording discarded by user');
        return null;
      }
      
      if (_recordedFilePath != null) {
        final file = File(_recordedFilePath!);
        if (file.existsSync()) {
          final fileSize = file.lengthSync();
          debugPrint('📁 Recorded file size: $fileSize bytes');
          
          if (fileSize < 1000) {
            debugPrint('❌ File too small: $fileSize bytes');
            throw Exception('Kayıt çok kısa. Lütfen tekrar deneyin.');
          }
          
          final isValid = await _validateAudioFile(file);
          if (!isValid) {
            debugPrint('❌ Invalid audio file');
            throw Exception('Geçersiz ses dosyası. Lütfen tekrar deneyin.');
          }
          
          debugPrint('✅ Recording stopped successfully');
          return file;
        } else {
          debugPrint('❌ File does not exist');
          throw Exception('Ses dosyası oluşturulamadı');
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Stop recording error: $e');
      rethrow;
    }
  }

  Future<bool> _validateAudioFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      
      if (bytes.length < 100) {
        debugPrint('❌ File too small to be valid audio');
        return false;
      }

      final String path = file.path.toLowerCase();
      
      if (path.endsWith('.m4a') || path.endsWith('.mp4')) {
        if (bytes.length >= 8) {
          final signature = String.fromCharCodes(bytes.sublist(4, 8));
          if (signature == 'ftyp') {
            debugPrint('✅ Valid M4A/MP4 file format');
            return true;
          }
        }
      }
      
      if (path.endsWith('.ogg') || path.endsWith('.opus')) {
        if (bytes.length >= 4) {
          final signature = String.fromCharCodes(bytes.sublist(0, 4));
          if (signature == 'OggS') {
            debugPrint('✅ Valid OGG file format');
            return true;
          }
        }
      }
      
      if (path.endsWith('.aac')) {
        if (bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xF0) == 0xF0) {
          debugPrint('✅ Valid AAC file format');
          return true;
        }
      }

      debugPrint('⚠️ Format unknown but file size ok (${bytes.length} bytes)');
      return true;
    } catch (e) {
      debugPrint('❌ Audio validation error: $e');
      return false;
    }
  }

  void discardRecording() {
    if (_recordedFilePath != null) {
      try {
        File(_recordedFilePath!).deleteSync();
        debugPrint('🗑️ Recording discarded');
      } catch (e) {
        debugPrint('❌ Delete file error: $e');
      }
    }
    
    _recordedFilePath = null;
    _recordingDuration = Duration.zero;
    notifyListeners();
  }

  void reset() {
    _recordedFilePath = null;
    _recordingDuration = Duration.zero;
    _isRecording = false;
    _isPaused = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }
}

