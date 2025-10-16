import 'package:flutter/material.dart';

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
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeButton(
              theme: theme,
              icon: Icons.mic_rounded,
              label: 'Sesli',
              isSelected: tabController.index == 0,
              onTap: () => tabController.animateTo(0),
            ),
            const SizedBox(width: 8),
            _ModeButton(
              theme: theme,
              icon: Icons.edit_rounded,
              label: 'Yazılı',
              isSelected: tabController.index == 1,
              onTap: () => tabController.animateTo(1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek bir mod butonu - Modern segmented control
class _ModeButton extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

