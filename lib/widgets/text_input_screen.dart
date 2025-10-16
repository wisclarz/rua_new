import 'package:flutter/material.dart';
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
      bottom: false, // Klavye için manual padding yapacağız
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                       MediaQuery.of(context).padding.top -
                       MediaQuery.of(context).padding.bottom -
                       56 - // AppBar height
                       100 - // Tab selector ve spacing
                       keyboardHeight,
          ),
          child: IntrinsicHeight(
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
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextEditor(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
        onChanged: (_) => onTextChanged(),
        decoration: InputDecoration(
          hintText: 'Dün gece gördüğüm rüyada...\n\nDetaylı anlatın, her ayrıntı önemli.',
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterInfo(ThemeData theme) {
    final charCount = controller.text.trim().length;
    final isValid = charCount >= 20;

    return Row(
      children: [
        Expanded(
          child: Text(
            isValid ? 'Rüyanız kaydedilmeye hazır' : 'En az 20 karakter gerekli',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isValid
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isValid)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              Text(
                '$charCount',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isValid
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton(ThemeData theme) {
    final isValid = controller.text.trim().length >= 20;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: isValid ? onSend : null,
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: const Text(
          'Rüyayı Analiz Et',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          disabledForegroundColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

