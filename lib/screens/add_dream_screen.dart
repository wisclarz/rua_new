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
  final TextEditingController _dreamTextController = TextEditingController();
  
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  bool _isPaused = false;
  String? _recordedFilePath;
  Duration _recordingDuration = Duration.zero;
  
  // Input mode: 'voice' or 'text'
  String _inputMode = 'voice';
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _setupAnimations();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    setState(() {
      _inputMode = _tabController.index == 0 ? 'voice' : 'text';
    });
    debugPrint('📝 Input mode changed to: $_inputMode');
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
      debugPrint('⏹️ Stopping recording...');
      await _recorder.stopRecorder();
      
      debugPrint('⏳ Waiting for file to be properly closed...');
      await Future.delayed(Duration(milliseconds: 500));
      
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
      _pulseController.stop();
      _pulseController.reset();
      HapticFeedback.mediumImpact();
      
      if (_recordedFilePath != null) {
        final file = File(_recordedFilePath!);
        if (file.existsSync()) {
          final fileSize = file.lengthSync();
          debugPrint('📁 Recorded file size: $fileSize bytes');
          
          if (fileSize < 1000) {
            debugPrint('❌ File too small: $fileSize bytes');
            _showErrorSnackBar('Kayıt çok kısa. Lütfen tekrar deneyin.');
            _discardRecording();
            return;
          }
          
          final isValid = await _validateAudioFile(file);
          if (!isValid) {
            debugPrint('❌ Invalid audio file');
            _showErrorSnackBar('Geçersiz ses dosyası. Lütfen tekrar deneyin.');
            _discardRecording();
            return;
          }
          
          debugPrint('✅ Recording stopped successfully');
          _showSaveDialog();
        } else {
          debugPrint('❌ File does not exist');
          _showErrorSnackBar('Ses dosyası oluşturulamadı');
        }
      }
    } catch (e) {
      debugPrint('❌ Stop recording error: $e');
      _showErrorSnackBar('Kayıt durdurulamadı: $e');
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

  void _showSaveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_inputMode == 'voice' ? 'Rüya Kaydını Kaydet' : 'Rüyayı Kaydet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _inputMode == 'voice' 
                ? 'Kaydınızı analiz için göndermek istiyor musunuz?'
                : 'Rüyanızı analiz için göndermek istiyor musunuz?'
            ),
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
              if (_inputMode == 'voice') {
                _discardRecording();
              }
            },
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (_inputMode == 'voice') {
                _saveAndUploadRecording();
              } else {
                _saveTextDream();
              }
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
      
      final file = File(_recordedFilePath!);
      debugPrint('📤 Uploading file: $_recordedFilePath (${file.lengthSync()} bytes)');
      
      dreamProvider.uploadAudioFile(file).then((_) {
        debugPrint('✅ Background upload completed');
      }).catchError((error) {
        debugPrint('❌ Background upload failed: $error');
      });
      
      HapticFeedback.heavyImpact();
      
      if (mounted) {
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
        
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Save error: $e');
      _showErrorSnackBar('Kayıt hatası: $e');
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
        title: _titleController.text.trim(),
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
    _dreamTextController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _tabController.dispose();
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              tabs: const [
                Tab(
                  icon: Icon(Icons.mic),
                  text: 'Sesli',
                ),
                Tab(
                  icon: Icon(Icons.text_fields),
                  text: 'Yazılı',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecordingScreen(theme, size),
          _buildTextInputScreen(theme, size),
        ],
      ),
    );
  }

  Widget _buildTextInputScreen(ThemeData theme, Size size) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            Text(
              'Rüyanızı Yazın',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Rüyanızı detaylı anlatın, daha iyi analiz edelim',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _dreamTextController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: theme.textTheme.bodyLarge,
                  onChanged: (value) {
                    setState(() {}); // Real-time update
                  },
                  decoration: InputDecoration(
                    hintText: 'Dün gece gördüğüm rüyada...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'En az 20 karakter yazmanız gerekmektedir',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _dreamTextController.text.trim().length >= 20
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_dreamTextController.text.length} / 20',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _dreamTextController.text.trim().length >= 20
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _dreamTextController.text.trim().length >= 20
                    ? _showSaveDialog
                    : null,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Analiz İçin Gönder'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                  disabledForegroundColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingScreen(ThemeData theme, Size size) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
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
            
            _buildRecordingVisualization(theme),
            
            const SizedBox(height: 40),
            
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

  Widget _buildControlButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
        
        if (_isRecording) ...[
          _buildIconButton(
            icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: theme.colorScheme.primary,
            onPressed: _isPaused ? _resumeRecording : _pauseRecording,
          ),
          const SizedBox(width: 32),
        ],
        
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