import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
        bitRate: 128000,
        sampleRate: 44100,
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
      
      // ✅ DÜZELTME: Upload'u arka planda başlat, bekleme
      // Fire and forget - kullanıcıyı bekleme
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
  return Stack(
    alignment: Alignment.center,
    children: [
      // Outer Pulsing Circles
      ...List.generate(3, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 1000 + (index * 200)),
          width: 200 + (index * 40.0),
          height: 200 + (index * 40.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _isRecording 
                  ? theme.colorScheme.primary.withOpacity(0.2 - (index * 0.05))
                  : Colors.transparent,
              width: 2,
            ),
          ),
        )
          .animate(onPlay: (controller) {
            if (_isRecording) {
              controller.repeat();
            }
          })
          .fadeIn(duration: 400.ms)
          .scale(
            duration: Duration(milliseconds: 1500 + (index * 200)),
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
          )
          .then()
          .scale(
            duration: Duration(milliseconds: 1500 + (index * 200)),
            begin: const Offset(1.0, 1.0),
            end: const Offset(0.8, 0.8),
          );
      }),
      
      // Wave Bars Visualization
      if (_isRecording && !_isPaused)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(5, (index) {
            return Container(
              width: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .custom(
                duration: Duration(milliseconds: 300 + (index * 100)),
                begin: 20,
                end: 60 + (index * 10.0),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return SizedBox(
                    height: value,
                    child: child,
                  );
                },
              );
          }),
        ),
      
      // Central Microphone Icon
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isRecording
                ? [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ]
                : [
                    theme.colorScheme.surfaceContainerHighest,
                    theme.colorScheme.surfaceContainerHigh,
                  ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            if (_isRecording)
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.mic : Icons.mic_none,
          size: 48,
          color: _isRecording ? Colors.white : theme.colorScheme.onSurface,
        ),
      )
        .animate(target: _isRecording ? 1 : 0)
        .scale(
          duration: 400.ms,
          curve: Curves.elasticOut,
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.15, 1.15),
        )
        
        .scale(
          duration: 1000.ms,
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
        ),
    ],
  );
}

// Duraklat/Devam Et butonu için animasyonlu tasarım
Widget _buildRecordingControls(ThemeData theme) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause/Resume Button
        if (_isRecording)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isPaused ? _resumeRecording : _pauseRecording,
              borderRadius: BorderRadius.circular(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: _isPaused
                      ? Colors.green.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _isPaused
                        ? Colors.green.withOpacity(0.5)
                        : Colors.orange.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      color: _isPaused ? Colors.green : Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isPaused ? 'Devam Et' : 'Duraklat',
                      style: TextStyle(
                        color: _isPaused ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(duration: 400.ms, curve: Curves.elasticOut),
        
        const SizedBox(width: 16),
        
        // Stop Button
        if (_isRecording)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _stopRecording,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.red, Colors.redAccent],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stop,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Bitir',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut)
            .shimmer(
              delay: 1000.ms,
              duration: 2000.ms,
              color: Colors.white.withOpacity(0.3),
            ),
      ],
    ),
  );
}

// Başlat butonu için geliştirilmiş animasyon
Widget _buildStartButton(ThemeData theme) {
  return GestureDetector(
    onTap: _startRecording,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic,
            size: 60,
            color: Colors.white,
          ),
          SizedBox(height: 8),
          Text(
            'Başlat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  )
    .animate(onPlay: (controller) => controller.repeat(reverse: true))
    .scale(
      duration: 2000.ms,
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.08, 1.08),
      curve: Curves.easeInOut,
    )
    .shimmer(
      delay: 500.ms,
      duration: 2000.ms,
      color: Colors.white.withOpacity(0.3),
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