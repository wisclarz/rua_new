import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dreamy_background.dart';

/// Yazılı rüya girişi için ekran widget
class TextInputScreen extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onTextChanged;

  const TextInputScreen({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          const SizedBox(height: 20),

          // TextField - Genişleyebilir alan
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildTextEditor(theme),
            ),
          ),

          // Alt bilgiler - Klavye açıkken daha compact
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.fromLTRB(
              24.0,
              isKeyboardOpen ? 8.0 : 20.0,
              24.0,
              isKeyboardOpen ? 8.0 : 20.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCharacterInfo(theme),
                SizedBox(height: isKeyboardOpen ? 12.0 : 20.0),
                _buildSendButton(theme),
                // Klavye için padding
                if (isKeyboardOpen) SizedBox(height: keyboardHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextEditor(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: theme.textTheme.bodyLarge,
        onChanged: (_) => onTextChanged(),
        decoration: InputDecoration(
          hintText: 'Dün gece gördüğüm rüyada...',
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildCharacterInfo(ThemeData theme) {
    final isValid = controller.text.trim().length >= 20;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'En az 20 karakter',
              style: TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isValid
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${controller.text.length}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isValid
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSendButton(ThemeData theme) {
    final isValid = controller.text.trim().length >= 20;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isValid ? onSend : null,
        icon: const Icon(Icons.send_rounded, size: 22),
        label: const Text(
          'Gönder',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isValid ? 4 : 0,
          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.5),
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          disabledForegroundColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0);
  }
}

