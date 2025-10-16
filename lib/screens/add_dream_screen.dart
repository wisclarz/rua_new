import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/dream_provider.dart';
import '../widgets/recording_controller.dart';
import '../widgets/tab_selector.dart';
import '../widgets/recording_screen.dart';
import '../widgets/text_input_screen.dart';
import '../widgets/transcription_dialog.dart';
import '../widgets/dreamy_background.dart';

class AddDreamScreen extends StatefulWidget {
  const AddDreamScreen({super.key});

  @override
  State<AddDreamScreen> createState() => _AddDreamScreenState();
}

class _AddDreamScreenState extends State<AddDreamScreen> with TickerProviderStateMixin {
  late final RecordingController _recordingController;
  final TextEditingController _dreamTextController = TextEditingController();
  final TextEditingController _transcriptionController = TextEditingController();
  
  // Input mode: 'voice' or 'text'
  String _inputMode = 'voice';
  late TabController _tabController;
  bool _isTranscriptionLoaded = false;

  @override
  void initState() {
    super.initState();
    _recordingController = RecordingController();
    _initializeRecorder();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // Only update when the animation is complete, not during the animation
    if (!_tabController.indexIsChanging) {
      setState(() {
        _inputMode = _tabController.index == 0 ? 'voice' : 'text';
      });
      debugPrint('📝 Input mode changed to: $_inputMode');
    }
  }

  Future<void> _initializeRecorder() async {
    try {
      await _recordingController.initialize();
    } catch (e) {
      _showErrorSnackBar('Mikrofon başlatılamadı: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _startRecording() async {
    try {
      await _recordingController.startRecording();
      HapticFeedback.mediumImpact();
      setState(() {});
    } catch (e) {
      _showErrorSnackBar('Kayıt başlatılamadı: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recordingController.pauseRecording();
      HapticFeedback.lightImpact();
      setState(() {});
    } catch (e) {
      _showErrorSnackBar('Duraklat hatası: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recordingController.resumeRecording();
      HapticFeedback.lightImpact();
      setState(() {});
    } catch (e) {
      _showErrorSnackBar('Devam ettirme hatası: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _stopRecording({bool shouldSave = true}) async {
    try {
      final file = await _recordingController.stopRecording(shouldSave: shouldSave);
      HapticFeedback.mediumImpact();
      setState(() {});
      
      if (shouldSave && file != null) {
        await _saveAndUploadRecording(file);
      }
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      _recordingController.discardRecording();
      setState(() {});
    }
  }

  Future<void> _saveAndUploadRecording(File file) async {
    try {
      final dreamProvider = Provider.of<DreamProvider>(context, listen: false);
      
      debugPrint('🎙️ Starting transcription for file: ${file.path} (${file.lengthSync()} bytes)');
      
      // Önce diyalogu aç
      _showTranscriptionDialog();
      
      // Transkripsiyon yap
      await dreamProvider.transcribeAudioFile(
        file,
        onTranscriptionReady: (String transcription) {
          debugPrint('📝 Transcription received: ${transcription.substring(0, transcription.length > 50 ? 50 : transcription.length)}...');
          
          if (mounted) {
            setState(() {
              _transcriptionController.text = transcription;
              _isTranscriptionLoaded = true;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('❌ Transcription error: $e');
      
      if (mounted) {
        Navigator.of(context).pop(); // Diyalogu kapat
        _showErrorSnackBar('Ses metne çevrilemedi: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  Future<void> _approveAndSaveTranscription() async {
    if (_transcriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Rüya metni boş olamaz');
      return;
    }

    if (_transcriptionController.text.trim().length < 20) {
      _showErrorSnackBar('Rüya metni en az 20 karakter olmalı');
      return;
    }

    try {
      final dreamProvider = Provider.of<DreamProvider>(context, listen: false);
      
      debugPrint('✅ Sending dream for analysis...');
      
      await dreamProvider.createDreamWithTranscription(
        transcription: _transcriptionController.text.trim(),
        title: null, // Başlık yok
      );
      
      HapticFeedback.heavyImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Rüyanız analize gönderildi'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error saving dream: $e');
      _showErrorSnackBar('Rüya gönderilemedi: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _saveTextDream() async {
    final dreamText = _dreamTextController.text.trim();
    
    if (dreamText.isEmpty) {
      _showErrorSnackBar('Lütfen rüyanızı yazın');
      return;
    }

    if (dreamText.length < 20) {
      _showErrorSnackBar('Rüya metni çok kısa. Daha detaylı anlatın.');
      return;
    }

    try {
      final dreamProvider = Provider.of<DreamProvider>(context, listen: false);
      
      debugPrint('📝 Saving text dream...');
      
      dreamProvider.uploadTextDream(
        dreamText: dreamText,
        title: null,
      ).then((_) {
        debugPrint('✅ Text dream saved successfully');
      }).catchError((error) {
        debugPrint('❌ Text dream save failed: $error');
      });
      
      HapticFeedback.heavyImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.text_fields, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rüya kaydediliyor...',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Analiz tamamlanınca bildirim alacaksınız',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Text dream save error: $e');
      _showErrorSnackBar('Kayıt hatası: $e');
    }
  }

  void _discardRecording() {
    _recordingController.discardRecording();
    setState(() {});
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _recordingController.dispose();
    _dreamTextController.dispose();
    _transcriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Rüya Kaydet',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      body: DreamyBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 56),
            
            const SizedBox(height: 20),
          
          // Ekran ortasında icon seçici
          ModernTabSelector(
            tabController: _tabController,
            theme: theme,
          ),
          
          const SizedBox(height: 20),
          
          // Seçilen moda göre içerik göster
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _tabController.index == 0
                  ? ListenableBuilder(
                      key: const ValueKey('recording'),
                      listenable: _recordingController,
                      builder: (context, _) => RecordingScreen(
                        isRecording: _recordingController.isRecording,
                        isPaused: _recordingController.isPaused,
                        recordingDuration: _recordingController.recordingDuration,
                        onRecord: _recordingController.isRecording ? _stopRecording : _startRecording,
                        onPause: _pauseRecording,
                        onResume: _resumeRecording,
                        onDelete: () async {
                          await _stopRecording(shouldSave: false);
                          _discardRecording();
                        },
                      ),
                    )
                  : TextInputScreen(
                      key: const ValueKey('text'),
                      controller: _dreamTextController,
                      onSend: _saveTextDream,
                      onTextChanged: () => setState(() {}),
                    ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _showTranscriptionDialog() {
    _isTranscriptionLoaded = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ListenableBuilder(
        listenable: Listenable.merge([_transcriptionController]),
        builder: (context, _) {
          return TranscriptionDialog(
                              controller: _transcriptionController,
            isLoaded: _isTranscriptionLoaded,
            onSend: () {
              Navigator.pop(context);
              _approveAndSaveTranscription();
            },
            onCancel: () {
                                    _transcriptionController.clear();
                                    Navigator.pop(context);
                                  },
          );
        },
      ),
    ).then((_) {
      _isTranscriptionLoaded = false;
    });
  }

}