import 'package:flutter/material.dart';
import '../models/dream_model.dart';

class DreamDetailWidget extends StatelessWidget {
  final Dream dream;

  const DreamDetailWidget({
    super.key,
    required this.dream,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Container(
      height: size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dream.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dream.formattedDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  _buildStatusBadge(context, theme),
                  
                  const SizedBox(height: 20),
                  
                  // Mood
                  if (dream.mood != 'Belirsiz') ...[
                    _buildSectionTitle(context, 'Ruh Hali', theme),
                    const SizedBox(height: 12),
                    _buildMoodChip(context, theme),
                    const SizedBox(height: 20),
                  ],
                  
                  // Symbols
                  if (dream.symbols != null && dream.symbols!.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Simgeler', theme),
                    const SizedBox(height: 12),
                    _buildSymbolsChips(context, theme),
                    const SizedBox(height: 20),
                  ],
                  
                  // Dream Text
                  if (dream.dreamText != null && dream.dreamText!.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Rüya Metni', theme),
                    const SizedBox(height: 12),
                    _buildContentCard(context, dream.dreamText!, theme),
                    const SizedBox(height: 20),
                  ],
                  
                  // Interpretation
                  if (dream.interpretation != null && dream.interpretation!.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Yorum', theme),
                    const SizedBox(height: 12),
                    _buildContentCard(context, dream.interpretation!, theme),
                    const SizedBox(height: 20),
                  ],
                  
                  // Analysis
                  if (dream.analysis != null && 
                      dream.analysis!.isNotEmpty && 
                      dream.analysis != 'Analiz yapılıyor...') ...[
                    _buildSectionTitle(context, 'Psikolojik Analiz', theme),
                    const SizedBox(height: 12),
                    _buildContentCard(context, dream.analysis!, theme),
                    const SizedBox(height: 20),
                  ],
                  
                  // Connection to Past
                  if (dream.connectionToPast != null && dream.connectionToPast!.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Önceki Rüyalarla Bağlantı', theme),
                    const SizedBox(height: 12),
                    _buildHighlightCard(context, dream.connectionToPast!, theme),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, ThemeData theme) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (dream.status) {
      case DreamStatus.completed:
        badgeColor = Colors.green;
        badgeText = 'Tamamlandı';
        badgeIcon = Icons.check_circle;
        break;
      case DreamStatus.processing:
        badgeColor = Colors.orange;
        badgeText = 'Analiz Yapılıyor...';
        badgeIcon = Icons.hourglass_empty;
        break;
      case DreamStatus.failed:
        badgeColor = Colors.red;
        badgeText = 'Başarısız';
        badgeIcon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 18, color: badgeColor),
          const SizedBox(width: 8),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodChip(BuildContext context, ThemeData theme) {
    final moodColor = _getMoodColor(dream.mood);
    final moodEmoji = _getMoodEmoji(dream.mood);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: moodColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: moodColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            moodEmoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Text(
            _capitalizeFirst(dream.mood),
            style: TextStyle(
              color: moodColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolsChips(BuildContext context, ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: dream.symbols!.map((symbol) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                _capitalizeFirst(symbol),
                style: TextStyle(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContentCard(BuildContext context, String content, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Text(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildHighlightCard(BuildContext context, String content, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.link,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'mutlu':
      case 'heyecanlı':
        return Colors.green;
      case 'kaygılı':
        return Colors.orange;
      case 'korkulu':
        return Colors.red;
      case 'huzurlu':
        return Colors.blue;
      case 'şaşkın':
        return Colors.amber;
      case 'huzursuz':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'mutlu':
        return '😊';
      case 'kaygılı':
        return '😰';
      case 'huzurlu':
        return '😌';
      case 'korkulu':
        return '😨';
      case 'heyecanlı':
        return '🤩';
      case 'şaşkın':
        return '😲';
      case 'huzursuz':
        return '😟';
      default:
        return '😐';
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}