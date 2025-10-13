import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_constants.dart';

/// Recording kontrol butonları widget
/// Kayıt, duraklat, sil işlemlerini yönetir
/// 
/// Performance optimizations:
/// - Uses AppConstants for all values
/// - Optimized animations for 60/120Hz displays
/// - Reduced widget rebuilds
class RecordingControls extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final VoidCallback onRecord;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onDelete;

  const RecordingControls({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.onRecord,
    this.onPause,
    this.onResume,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isRecording) ...[
            _RecordingIconButton(
              theme: theme,
              icon: Icons.delete_rounded,
              label: 'Sil',
              color: Colors.red.shade400,
              onPressed: onDelete ?? () {},
            ).animate()
                .fadeIn(duration: AppConstants.animationNormal)
                .slideX(begin: -0.5, end: 0),
            const SizedBox(width: AppConstants.spacingXL),
          ],
          
          if (isRecording) ...[
            _RecordingIconButton(
              theme: theme,
              icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              label: isPaused ? 'Devam' : 'Duraklat',
              color: theme.colorScheme.primary,
              onPressed: isPaused ? (onResume ?? () {}) : (onPause ?? () {}),
            ).animate()
                .fadeIn(
                  duration: AppConstants.animationNormal,
                  delay: AppConstants.delayShort,
                ),
            const SizedBox(width: AppConstants.spacingXL),
          ],
          
          // Ana kayıt butonu
          _MainRecordButton(
            isRecording: isRecording,
            onPressed: onRecord,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

/// Ana kayıt butonu widget - Optimized
class _MainRecordButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onPressed;
  final ThemeData theme;

  const _MainRecordButton({
    required this.isRecording,
    required this.onPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Pre-calculate colors to avoid rebuilds
    final buttonColor = isRecording 
        ? const Color(0xFFFF5252) 
        : theme.colorScheme.primary;
    
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: AppConstants.recordingMainButtonSize,
        height: AppConstants.recordingMainButtonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isRecording 
                ? const [
                    Color(0xFFFF5252),
                    Color(0xFFE53935),
                  ]
                : [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.85),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isRecording ? Icons.check_rounded : Icons.mic_rounded,
          size: AppConstants.recordingIconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Yan butonlar (sil, duraklat/devam) - Optimized
class _RecordingIconButton extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _RecordingIconButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: AppConstants.recordingSideButtonSize,
            height: AppConstants.recordingSideButtonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: AppConstants.borderThick,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: AppConstants.recordingSideIconSize,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Recording görselleştirme widget (animasyonlu mikrofon ikonu)
/// 
/// Performance optimizations:
/// - Optimized animations for 60/120Hz displays
/// - Uses AppConstants for consistent timing
/// - Reduced opacity calculations
/// - Conditional animation rendering
class RecordingVisualization extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final ThemeData theme;

  const RecordingVisualization({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.theme,
  });

  static const double _iconContainerSize = 140.0;
  static const double _iconSize = 64.0;

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = isRecording && !isPaused;
    
    return SizedBox(
      width: AppConstants.recordingVisualizationSize,
      height: AppConstants.recordingVisualizationSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse halkası 1 - En dış (sadece recording sırasında render edilir)
          if (shouldAnimate)
            _PulseRing(
              size: _iconContainerSize,
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderWidth: AppConstants.borderThin,
              delay: Duration.zero,
            ),
          
          // Pulse halkası 2 - Orta
          if (shouldAnimate)
            _PulseRing(
              size: _iconContainerSize,
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              borderWidth: AppConstants.borderThin,
              delay: const Duration(milliseconds: 1000),
            ),
          
          // Pulse halkası 3 - İç
          if (shouldAnimate)
            _PulseRing(
              size: _iconContainerSize,
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
              borderWidth: AppConstants.borderNormal,
              delay: const Duration(milliseconds: 2000),
            ),
          
          // Ana mikrofon ikonu
          _MicrophoneIcon(
            size: _iconContainerSize,
            iconSize: _iconSize,
            isRecording: isRecording,
            isPaused: isPaused,
            shouldAnimate: shouldAnimate,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

/// Optimized pulse ring component
class _PulseRing extends StatelessWidget {
  final double size;
  final Color color;
  final double borderWidth;
  final Duration delay;

  const _PulseRing({
    required this.size,
    required this.color,
    required this.borderWidth,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: borderWidth,
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(), delay: delay)
        .scale(
          duration: Duration(milliseconds: AppConstants.pulseDuration),
          curve: Curves.easeOut,
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.8, 1.8),
        )
        .fadeOut(
          duration: Duration(milliseconds: AppConstants.pulseDuration),
          curve: Curves.easeIn,
        );
  }
}

/// Optimized microphone icon with breathing animation
class _MicrophoneIcon extends StatelessWidget {
  final double size;
  final double iconSize;
  final bool isRecording;
  final bool isPaused;
  final bool shouldAnimate;
  final ThemeData theme;

  const _MicrophoneIcon({
    required this.size,
    required this.iconSize,
    required this.isRecording,
    required this.isPaused,
    required this.shouldAnimate,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isRecording
              ? [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.85),
                ]
              : [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surfaceContainerHigh,
                ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        isRecording 
            ? (isPaused ? Icons.pause_rounded : Icons.mic_rounded)
            : Icons.mic_none_rounded,
        size: iconSize,
        color: isRecording 
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    )
        .animate(
          onPlay: (controller) {
            if (shouldAnimate) {
              controller.repeat(reverse: true);
            } else {
              controller.reset();
            }
          },
        )
        .scale(
          duration: Duration(milliseconds: AppConstants.breathingDuration),
          curve: Curves.easeInOutSine,
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
        );
  }
}

