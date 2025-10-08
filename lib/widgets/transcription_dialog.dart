import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Transkripsiyon sonuçlarını göstermek için dialog widget
/// Loading ve editing state'lerini yönetir
class TranscriptionDialog extends StatefulWidget {
  final TextEditingController controller;
  final bool isLoaded;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const TranscriptionDialog({
    super.key,
    required this.controller,
    required this.isLoaded,
    required this.onSend,
    required this.onCancel,
  });

  @override
  State<TranscriptionDialog> createState() => _TranscriptionDialogState();
}

class _TranscriptionDialogState extends State<TranscriptionDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: widget.isLoaded
              ? _buildEditingView(theme)
              : _buildLoadingView(theme),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.2),
                theme.colorScheme.primary.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ).animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 3000.ms),
        const SizedBox(height: 28),
        Text(
          'Sesiniz metne çevriliyor...',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Yapay zeka rüyanızı analiz ediyor',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEditingView(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 20),
        _buildTextEditor(theme),
        const SizedBox(height: 20),
        _buildCharacterCounter(theme),
        const SizedBox(height: 24),
        _buildActionButtons(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.edit_note_rounded,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Metni Düzenle',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'İstersen düzenleyebilirsin',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextEditor(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: TextField(
        controller: widget.controller,
        maxLines: null,
        minLines: 8,
        autofocus: true,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Rüya metni...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildCharacterCounter(ThemeData theme) {
    final isValid = widget.controller.text.trim().length >= 20;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isValid
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.info_outline,
            size: 18,
            color: isValid ? theme.colorScheme.primary : theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.controller.text.length} karakter',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final isValid = widget.controller.text.trim().length >= 20;
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('İptal'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: isValid ? widget.onSend : null,
            icon: const Icon(Icons.send_rounded, size: 20),
            label: const Text('Gönder'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

