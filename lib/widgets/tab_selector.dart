import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Ekran ortasında icon seçici
/// Sesli ve yazılı kayıt modları arasında geçiş yapar
class ModernTabSelector extends StatelessWidget {
  final TabController tabController;
  final ThemeData theme;

  const ModernTabSelector({
    super.key,
    required this.tabController,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            theme: theme,
            icon: Icons.mic_rounded,
            isSelected: tabController.index == 0,
            onTap: () => tabController.animateTo(0),
          ),
          const SizedBox(width: 40),
          _ModeButton(
            theme: theme,
            icon: Icons.edit_rounded,
            isSelected: tabController.index == 1,
            onTap: () => tabController.animateTo(1),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

/// Tek bir mod butonu (ekran ortasında büyük icon - minimalist)
class _ModeButton extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.theme,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
        builder: (context, value, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Icon(
              icon,
              color: Color.lerp(
                theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                theme.colorScheme.primary,
                value,
              ),
              size: 48 + (value * 16), // 48 -> 64
              shadows: isSelected
                  ? [
                      Shadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                      ),
                    ]
                  : null,
            ),
          );
        },
      ),
    );
  }
}

