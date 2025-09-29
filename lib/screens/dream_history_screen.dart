import 'package:flutter/material.dart';
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
    await dreamProvider.fetchDreams();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rüya Geçmişi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDreams,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Consumer<DreamProvider>(
        builder: (context, dreamProvider, child) {
          if (dreamProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dreamProvider.errorMessage != null) {
            return _buildErrorState(dreamProvider.errorMessage!);
          }

          final filteredDreams = _getFilteredDreams(dreamProvider.dreams);

          if (filteredDreams.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadDreams,
            child: Column(
              children: [
                _buildFilterChips(dreamProvider.dreams),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDreams.length,
                    itemBuilder: (context, index) {
                      final dream = filteredDreams[index];
                      return _buildDreamCard(dream);
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

  Widget _buildErrorState(String errorMessage) {
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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
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

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadDreams,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.nights_stay_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  _selectedFilter == 'all' 
                      ? 'Henüz Rüya Kaydın Yok'
                      : 'Bu Kategoride Rüya Bulunamadı',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedFilter == 'all'
                      ? 'Ana ekrandan yeni bir rüya kaydet\nve analiz sonuçlarını gör!'
                      : 'Farklı bir filtre seçmeyi dene',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                  ),
                ),
                if (_selectedFilter == 'all') ...[
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Ana Ekrana Dön'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(List<Dream> allDreams) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'all',
              'Tümü',
              allDreams.length,
              Icons.all_inclusive,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'completed',
              'Tamamlanan',
              allDreams.where((d) => d.isCompleted).length,
              Icons.check_circle,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'processing',
              'İşlenen',
              allDreams.where((d) => d.isProcessing).length,
              Icons.hourglass_empty,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'failed',
              'Başarısız',
              allDreams.where((d) => d.isFailed).length,
              Icons.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count, IconData icon) {
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
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      side: BorderSide(
        color: isSelected 
            ? Theme.of(context).primaryColor 
            : Colors.grey[300]!,
        width: 1,
      ),
    );
  }

  Widget _buildDreamCard(Dream dream) {
    Color statusColor;
    IconData statusIcon;
    
    switch (dream.status) {
      case DreamStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case DreamStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case DreamStatus.processing:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDreamDetail(dream),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dream.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dream.formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              
              // Mood & Symbols (sadece completed için)
              if (dream.isCompleted) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    // Mood
                    if (dream.mood != 'Belirsiz')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getMoodColor(dream.mood).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getMoodColor(dream.mood).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getMoodEmoji(dream.mood),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
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
                    
                    const SizedBox(width: 8),
                    
                    // Symbols count
                    if (dream.symbols != null && dream.symbols!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.3),
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
              
              // Preview text
              if (dream.isCompleted && 
                  dream.interpretation != null && 
                  dream.interpretation!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  dream.interpretation!.length > 120
                      ? '${dream.interpretation!.substring(0, 120)}...'
                      : dream.interpretation!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openDreamDetail(Dream dream) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Rüya Detayları'),
            actions: [
              if (dream.isCompleted)
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // TODO: Implement share
                  },
                  tooltip: 'Paylaş',
                ),
            ],
          ),
          body: DreamDetailWidget(dream: dream),
        ),
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