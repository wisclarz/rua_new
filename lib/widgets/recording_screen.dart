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
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 40,
        vertical: AppConstants.spacingXL,
      ),
      borderRadius: AppConstants.radiusXXL,
      child: Text(
        _formatDuration(duration),
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

