import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import 'recording_controls.dart';
import 'dreamy_background.dart';

/// Sesli kayıt ekranı widget
/// 
/// Performance optimizations:
/// - Uses AppConstants for all values
/// - Const constructors where possible
/// - Separated duration display for better rebuilds
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
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXXL),
        child: Column(
          children: [
            const Spacer(),
            
            RecordingVisualization(
              isRecording: isRecording,
              isPaused: isPaused,
              theme: theme,
            ),
            
            const SizedBox(height: AppConstants.spacingXXXL + 8),
            
            _DurationDisplay(
              duration: recordingDuration,
              isRecording: isRecording,
              theme: theme,
            ),
            
            const Spacer(),
            
            RecordingControls(
              isRecording: isRecording,
              isPaused: isPaused,
              onRecord: onRecord,
              onPause: onPause,
              onResume: onResume,
              onDelete: onDelete,
            ),
            
            const SizedBox(height: AppConstants.spacingXXXL + 8),
          ],
        ),
      ),
    );
  }
}

/// Optimized duration display widget
class _DurationDisplay extends StatelessWidget {
  final Duration duration;
  final bool isRecording;
  final ThemeData theme;
  
  const _DurationDisplay({
    required this.duration,
    required this.isRecording,
    required this.theme,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: isRecording
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRecording
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.dividerColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Text(
            _formatDuration(duration),
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isRecording
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isRecording ? 'Kaydediliyor...' : 'Kaydı başlatmak için tıklayın',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

