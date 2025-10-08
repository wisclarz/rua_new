import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'recording_controls.dart';

/// Sesli kayıt ekranı widget
class RecordingScreen extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final Duration recordingDuration;
  final VoidCallback onRecord;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onDelete;

  const RecordingScreen({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.recordingDuration,
    required this.onRecord,
    this.onPause,
    this.onResume,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            _buildTitle(theme),
            
            const SizedBox(height: 8),
            
            _buildSubtitle(theme),
            
            const Spacer(),
            
            RecordingVisualization(
              isRecording: isRecording,
              isPaused: isPaused,
              theme: theme,
            ),
            
            const SizedBox(height: 40),
            
            _buildDurationDisplay(theme),
            
            const Spacer(),
            
            RecordingControls(
              isRecording: isRecording,
              isPaused: isPaused,
              onRecord: onRecord,
              onPause: onPause,
              onResume: onResume,
              onDelete: onDelete,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      isRecording 
          ? (isPaused ? 'Kayıt Duraklatıldı' : 'Kayıt Devam Ediyor')
          : 'Rüyanızı Anlatın',
      style: theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ).animate(target: isRecording ? 1 : 0).fadeIn(duration: 400.ms);
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Text(
      isRecording 
          ? 'Detaylı anlatın, daha iyi analiz edelim'
          : 'Kayıt butonuna basarak başlayın',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      textAlign: TextAlign.center,
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms);
  }

  Widget _buildDurationDisplay(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRecording 
              ? [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                ]
              : [
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRecording 
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: isRecording
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Text(
        _formatDuration(recordingDuration),
        style: theme.textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: isRecording 
              ? theme.colorScheme.primary 
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontFeatures: const [FontFeature.tabularFigures()],
          letterSpacing: 4,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

