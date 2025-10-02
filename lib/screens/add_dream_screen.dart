import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/dream_provider.dart';

class AddDreamScreen extends StatefulWidget {
  const AddDreamScreen({super.key});

  @override
  State<AddDreamScreen> createState() => _AddDreamScreenState();
}

class _AddDreamScreenState extends State<AddDreamScreen> with TickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final TextEditingController _titleController = TextEditingController();
  
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  bool _isPaused = false;
  String? _recordedFilePath;
  Duration _recordingDuration = Duration.zero;
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeRecorder() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _showErrorSnackBar('Mikrofon izni gerekli');
        return;
      }

      await _recorder.openRecorder();
      setState(() {
        _isRecorderInitialized = true;
      });
      debugPrint('✅ Recorder initialized');
    } catch (e) {
      debugPrint('❌ Recorder initialization error: $e');
      _showErrorSnackBar('Mikrofon başlatılamadı: $e');
    }
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) {
      _showErrorSnackBar('Mikrofon hazır değil');
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/dream_${DateTime.now().millisecondsSinceEpoch}.aac';
      
      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _recordedFilePath = filePath;
      });

      _pulseController.repeat(reverse: true);
      _startDurationTimer();
      
      HapticFeedback.mediumImpact();
      debugPrint('🎤 Recording started: $filePath');
    } catch (e) {
      debugPrint('❌ Start recording error: $e');
      _showErrorSnackBar('Kayıt başlatılamadı: $e');
    }
  }

  void _startDurationTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && !_isPaused && mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
        _startDurationTimer();
      }
    });
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorder.pauseRecorder();
      setState(() {
        _isPaused = true;
      });
      _pulseController.stop();
      HapticFeedback.lightImpact();
      debugPrint('⏸️ Recording paused');
    } catch (e) {
      debugPrint('❌ Pause error: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recorder.resumeRecorder();
      setState(() {
        _isPaused = false;
      });
      _pulseController.repeat(reverse: true);
      _startDurationTimer();
      HapticFeedback.lightImpact();
      debugPrint('▶️ Recording resumed');
    } catch (e) {
      debugPrint('❌ Resume error: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
      _pulseController.stop();
      _pulseController.reset();
      HapticFeedback.mediumImpact();
      debugPrint('⏹️ Recording stopped');
      
      if (_recordedFilePath != null) {
        _showSaveDialog();
      }
    } catch (e) {
      debugPrint('❌ Stop recording error: $e');
      _showErrorSnackBar('Kayıt durdurulamadı: $e');
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rüya Kaydını Kaydet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Kaydınızı analiz için göndermek istiyor musunuz?'),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Rüya Başlığı (Opsiyonel)',
                hintText: 'Örn: Uçma Rüyası',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _discardRecording();
            },
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _saveAndUploadRecording();
            },
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Kaydet ve Gönder'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndUploadRecording() async {
    if (_recordedFilePath == null) return;

    try {
      final dreamProvider = Provider.of<DreamProvider>(context, listen: false);
      
      // ✅ DÜZELTME: uploadAudioFile sadece File parametresi alıyor
      // Title şimdilik kullanılmıyor, ileride ekleyebilirsiniz
      dreamProvider.uploadAudioFile(File(_recordedFilePath!)).then((_) {
        debugPrint('✅ Background upload completed');
      }).catchError((error) {
        debugPrint('❌ Background upload failed: $error');
      });
      
      // Hemen kullanıcıya geri bildirim ver
      HapticFeedback.heavyImpact();
      
      if (mounted) {
        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_upload, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rüya kaydediliyor...',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _titleController.text.isNotEmpty 
                          ? 'Başlık: ${_titleController.text}'
                          : 'Analiz tamamlanınca bildirim alacaksınız',
                        style: const TextStyle(fontSize: 12),
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
        
        // Hemen ana ekrana dön
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Save error: $e');
      _showErrorSnackBar('Kayıt hatası: $e');
    }
  }

  void _discardRecording() {
    if (_recordedFilePath != null) {
      try {
        File(_recordedFilePath!).deleteSync();
        debugPrint('🗑️ Recording discarded');
      } catch (e) {
        debugPrint('❌ Delete file error: $e');
      }
    }
    
    setState(() {
      _recordedFilePath = null;
      _recordingDuration = Duration.zero;
    });
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _titleController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Rüya Kaydet'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildRecordingScreen(theme, size),
    );
  }

  Widget _buildRecordingScreen(ThemeData theme, Size size) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // Info text
            Text(
              _isRecording 
                  ? (_isPaused ? 'Kayıt Duraklatıldı' : 'Kayıt Devam Ediyor')
                  : 'Rüyanızı Anlatın',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              _isRecording 
                  ? 'Detaylı anlatın, daha iyi analiz edelim'
                  : 'Kayıt butonuna basarak başlayın',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            const Spacer(),
            
            // Recording visualization
            _buildRecordingVisualization(theme),
            
            const SizedBox(height: 40),
            
            // Duration display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: _isRecording 
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isRecording 
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Text(
                _formatDuration(_recordingDuration),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isRecording 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurfaceVariant,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Control buttons
            _buildControlButtons(theme),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingVisualization(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring
            if (_isRecording && !_isPaused)
              Container(
                width: 280 * _pulseAnimation.value,
                height: 280 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 
                      0.2 * (1 - (_pulseAnimation.value - 1) / 0.15)
                    ),
                    width: 2,
                  ),
                ),
              ),
            
            // Middle pulse ring
            if (_isRecording && !_isPaused)
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                      theme.colorScheme.primary.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            
            // Main recording circle
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: _isRecording
                      ? [
                          theme.colorScheme.primary.withValues(alpha: 0.3),
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                          Colors.transparent,
                        ]
                      : [
                          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.surfaceContainerHighest).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording 
                        ? (_isPaused ? Icons.pause_rounded : Icons.mic_rounded)
                        : Icons.mic_none_rounded,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Delete/Cancel button (only when recording)
        if (_isRecording) ...[
          _buildIconButton(
            icon: Icons.delete_rounded,
            color: Colors.red,
            onPressed: () {
              _stopRecording();
              _discardRecording();
            },
          ),
          const SizedBox(width: 32),
        ],
        
        // Pause/Resume button (only when recording)
        if (_isRecording) ...[
          _buildIconButton(
            icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: theme.colorScheme.primary,
            onPressed: _isPaused ? _resumeRecording : _pauseRecording,
          ),
          const SizedBox(width: 32),
        ],
        
        // Main record/stop button
        GestureDetector(
          onTap: _isRecording ? _stopRecording : _startRecording,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isRecording 
                    ? [Colors.red, Colors.red.shade700]
                    : [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? Colors.red : theme.colorScheme.primary)
                      .withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 28,
        color: color,
      ),
    );
  }
}