import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/dream_provider.dart';
import '../models/dream_model.dart';
import '../widgets/dream_detail_widget.dart';

class DreamHistoryScreen extends StatefulWidget {
  const DreamHistoryScreen({super.key});

  @override
  State<DreamHistoryScreen> createState() => _DreamHistoryScreenState();
}

class _DreamHistoryScreenState extends State<DreamHistoryScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDreams();
    });
  }

  Future<void> _loadDreams() async {
    if (!mounted) return;
    final dreamProvider = Provider.of<DreamProvider>(context, listen: false);
    await dreamProvider.loadDreams();
  }

  List<Dream> _getFilteredDreams(List<Dream> dreams) {
    switch (_selectedFilter) {
      case 'completed':
        return dreams.where((d) => d.status == DreamStatus.completed).toList();
      case 'processing':
        return dreams.where((d) => d.status == DreamStatus.processing).toList();
      case 'failed':
        return dreams.where((d) => d.status == DreamStatus.failed).toList();
      case 'all':
      default:
        return dreams;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Rüya Geçmişi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadDreams();
            },
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Consumer<DreamProvider>(
        builder: (context, dreamProvider, child) {
          if (dreamProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (dreamProvider.errorMessage != null) {
            return _buildErrorState(dreamProvider.errorMessage!, theme);
          }

          final filteredDreams = _getFilteredDreams(dreamProvider.dreams);

          if (filteredDreams.isEmpty) {
            return _buildEmptyState(theme);
          }

          return RefreshIndicator(
            onRefresh: _loadDreams,
            child: Column(
              children: [
                _buildFilterChips(dreamProvider.dreams, theme),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: filteredDreams.length,
                    itemBuilder: (context, index) {
                      return RepaintBoundary(
                        child: _buildDreamCard(filteredDreams[index], theme),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(List<Dream> allDreams, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip(
              'all',
              'Tümü',
              allDreams.length,
              Icons.all_inclusive,
              theme,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'completed',
              'Tamamlanan',
              allDreams.where((d) => d.isCompleted).length,
              Icons.check_circle,
              theme,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'processing',
              'İşleniyor',
              allDreams.where((d) => d.isProcessing).length,
              Icons.hourglass_empty,
              theme,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'failed',
              'Başarısız',
              allDreams.where((d) => d.isFailed).length,
              Icons.error,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String value,
    String label,
    int count,
    IconData icon,
    ThemeData theme,
  ) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text('$label ($count)'),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
      side: BorderSide(
        color: isSelected 
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant,
        width: isSelected ? 1.5 : 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  Widget _buildDreamCard(Dream dream, ThemeData theme) {
    final Color statusColor = dream.isCompleted
        ? Colors.green
        : dream.isProcessing
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            _openDreamDetail(dream);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        dream.isCompleted
                            ? Icons.check_circle
                            : dream.isProcessing
                                ? Icons.hourglass_empty
                                : Icons.error,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Title and Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dream.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dream.formattedDate,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                
                // Content
                if (dream.isCompleted && dream.interpretation != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dream.interpretation!.length > 120
                          ? '${dream.interpretation!.substring(0, 120)}...'
                          : dream.interpretation!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else if (dream.isProcessing) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Analiz yapılıyor...',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Mood & Symbols
                if (dream.isCompleted) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Mood
                      if (dream.mood != 'Belirsiz')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getMoodColor(dream.mood).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getMoodColor(dream.mood).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getMoodEmoji(dream.mood),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dream.mood,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getMoodColor(dream.mood),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Symbols
                      if (dream.symbols != null && dream.symbols!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.purple.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${dream.symbols!.length} simge',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadDreams,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.nights_stay_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _selectedFilter == 'all' 
                        ? 'Henüz Rüya Kaydın Yok'
                        : 'Bu Kategoride Rüya Bulunamadı',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFilter == 'all'
                        ? 'Ana ekrandan yeni bir rüya kaydet\nve analiz sonuçlarını gör!'
                        : 'Farklı bir filtre seçmeyi dene',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Bir Hata Oluştu',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDreams,
              icon: const Icon(Icons.refresh),
              label: const Text('Yeniden Dene'),
            ),
          ],
        ),
      ),
    );
  }

 void _openDreamDetail(Dream dream) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DreamDetailWidget(dream: dream),
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