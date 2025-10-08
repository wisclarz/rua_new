import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Modern tab seçici widget
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                theme: theme,
                icon: Icons.mic_rounded,
                label: 'Sesli Kayıt',
                isSelected: tabController.index == 0,
                onTap: () => tabController.animateTo(0),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _TabButton(
                theme: theme,
                icon: Icons.edit_rounded,
                label: 'Yazılı Kayıt',
                isSelected: tabController.index == 1,
                onTap: () => tabController.animateTo(1),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }
}

/// Tek bir tab butonu
class _TabButton extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

