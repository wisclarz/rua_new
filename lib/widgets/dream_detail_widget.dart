// lib/widgets/dream_detail_widget.dart

import 'package:flutter/material.dart';
import '../models/dream_model.dart';
import 'package:intl/intl.dart';

class DreamDetailWidget extends StatelessWidget {
  final Dream dream;

  const DreamDetailWidget({
    Key? key,
    required this.dream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık - "Rüyanız: [title]"
          Text(
            dream.displayTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Tarih
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(dream.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Durum Badge
          _buildStatusBadge(context),
          
          const SizedBox(height: 24),
          
          // Ruh Hali
          if (dream.mood != 'Belirsiz') ...[
            _buildSectionTitle(context, 'Ruh Hali'),
            const SizedBox(height: 8),
            _buildMoodChip(context),
            const SizedBox(height: 24),
          ],
          
          // Simgeler
          if (dream.symbols != null && dream.symbols!.isNotEmpty) ...[
            _buildSectionTitle(context, 'Simgeler'),
            const SizedBox(height: 8),
            _buildSymbolsChips(context),
            const SizedBox(height: 24),
          ],
          
          // Rüya Metni
          if (dream.dreamText != null && dream.dreamText!.isNotEmpty) ...[
            _buildSectionTitle(context, 'Rüya Metni'),
            const SizedBox(height: 8),
            _buildContentCard(context, dream.dreamText!),
            const SizedBox(height: 24),
          ],
          
          // Yorum
          if (dream.interpretation != null && dream.interpretation!.isNotEmpty) ...[
            _buildSectionTitle(context, 'Yorum'),
            const SizedBox(height: 8),
            _buildContentCard(context, dream.interpretation!),
            const SizedBox(height: 24),
          ],
          
          // Analiz
          if (dream.analysis != null && 
              dream.analysis!.isNotEmpty && 
              dream.analysis != 'Analiz yapılıyor...') ...[
            _buildSectionTitle(context, 'Psikolojik Analiz'),
            const SizedBox(height: 8),
            _buildContentCard(context, dream.analysis!),
            const SizedBox(height: 24),
          ],
          
          // Önceki Rüyalarla Bağlantı
          if (dream.connectionToPast != null && dream.connectionToPast!.isNotEmpty) ...[
            _buildSectionTitle(context, 'Önceki Rüyalarla Bağlantı'),
            const SizedBox(height: 8),
            _buildHighlightCard(context, dream.connectionToPast!),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildMoodChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _getMoodColor(dream.mood).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getMoodColor(dream.mood), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getMoodEmoji(dream.mood),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 10),
          Text(
            dream.mood,
            style: TextStyle(
              color: _getMoodColor(dream.mood),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolsChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: dream.symbols!.map((symbol) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.withOpacity(0.3), width: 1),
          ),
          child: Text(
            symbol,
            style: const TextStyle(
              color: Colors.purple,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContentCard(BuildContext context, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildHighlightCard(BuildContext context, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.05),
            Colors.purple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.link, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.blue[900],
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
      case 'korkulu':
        return Colors.red;
      case 'huzurlu':
        return Colors.blue;
      case 'şaşkın':
        return Colors.orange;
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
}