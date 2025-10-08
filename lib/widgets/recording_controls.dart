import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Recording kontrol butonları widget
/// Kayıt, duraklat, sil işlemlerini yönetir
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
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
            ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.5, end: 0),
            const SizedBox(width: 20),
          ],
          
          if (isRecording) ...[
            _RecordingIconButton(
              theme: theme,
              icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              label: isPaused ? 'Devam' : 'Duraklat',
              color: theme.colorScheme.primary,
              onPressed: isPaused ? (onResume ?? () {}) : (onPause ?? () {}),
            ).animate().fadeIn(duration: 300.ms, delay: 50.ms),
            const SizedBox(width: 20),
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

/// Ana kayıt butonu widget
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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
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
              color: (isRecording 
                  ? const Color(0xFFFF5252) 
                  : theme.colorScheme.primary).withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isRecording ? Icons.check_rounded : Icons.mic_rounded,
          size: 36,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Yan butonlar (sil, duraklat/devam)
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: 2,
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
              size: 28,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
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
          if (isRecording)
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
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
        size: 64,
        color: isRecording 
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    )
      .animate(
        onPlay: (controller) {
          if (isRecording && !isPaused) {
            controller.repeat(reverse: true);
          } else {
            controller.reset();
          }
        },
      )
      .scale(
        duration: 1000.ms,
        curve: Curves.easeInOut,
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.08, 1.08),
      );
  }
}

