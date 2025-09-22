import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dream_provider.dart';
import '../models/dream_model.dart';

class DreamHistoryScreen extends StatefulWidget {
  const DreamHistoryScreen({super.key});

  @override
  State<DreamHistoryScreen> createState() => _DreamHistoryScreenState();
}

class _DreamHistoryScreenState extends State<DreamHistoryScreen> {
  String _selectedFilter = 'all'; // all, completed, processing, failed

  @override
  void initState() {
    super.initState();
    _loadDreams();
  }

  Future<void> _loadDreams() async {
    final dreamProvider = Provider.of<DreamProvider>(context, listen: false);
    await dreamProvider.fetchDreams();
  }

  List<Dream> _getFilteredDreams(List<Dream> dreams) {
    switch (_selectedFilter) {
      case 'completed':
        return dreams.where((dream) => dream.status == DreamStatus.completed).toList();
      case 'processing':
        return dreams.where((dream) => dream.status == DreamStatus.processing).toList();
      case 'failed':
        return dreams.where((dream) => dream.status == DreamStatus.failed).toList();
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
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Tümü'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Tamamlananlar'),
              ),
              const PopupMenuItem(
                value: 'processing',
                child: Text('İşlenenler'),
              ),
              const PopupMenuItem(
                value: 'failed',
                child: Text('Başarısızlar'),
              ),
            ],
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Consumer<DreamProvider>(
        builder: (context, dreamProvider, child) {
          if (dreamProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dreamProvider.errorMessage != null) {
            return Center(
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
                    'Hata',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dreamProvider.errorMessage!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDreams,
                    child: const Text('Yeniden Dene'),
                  ),
                ],
              ),
            );
          }

          final filteredDreams = _getFilteredDreams(dreamProvider.dreams);

          if (filteredDreams.isEmpty) {
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
                        const Icon(
                          Icons.bedtime_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'all' 
                              ? 'Henüz rüya kaydın yok'
                              : 'Bu kategoride rüya bulunamadı',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFilter == 'all'
                              ? 'Ana ekrandan yeni bir rüya kaydet!'
                              : 'Farklı bir filtre seçmeyi dene',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_selectedFilter == 'all')
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/home');
                            },
                            child: const Text('Ana Ekrana Dön'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadDreams,
            child: Column(
              children: [
                // Filter Chips
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'Tümü', dreamProvider.dreams.length),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'completed', 
                          'Tamamlanan', 
                          dreamProvider.dreams.where((d) => d.status == DreamStatus.completed).length,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'processing', 
                          'İşlenen', 
                          dreamProvider.dreams.where((d) => d.status == DreamStatus.processing).length,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'failed', 
                          'Başarısız', 
                          dreamProvider.dreams.where((d) => d.status == DreamStatus.failed).length,
                        ),
                      ],
                    ),
                  ),
                ),

                // Dreams List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _buildFilterChip(String value, String label, int count) {
    return FilterChip(
      label: Text('$label ($count)'),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
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
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showDreamDetailBottomSheet(dream);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dream.formattedDate,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      dream.statusText,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: statusColor.withOpacity(0.1),
                    side: BorderSide(color: statusColor.withOpacity(0.3)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (dream.analysis != null && dream.analysis!.isNotEmpty) ...[
                Text(
                  dream.analysis!.length > 100 
                      ? '${dream.analysis!.substring(0, 100)}...'
                      : dream.analysis!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
              ],
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dosya: ${dream.fileName?.split('/').last ?? 'Bilinmiyor'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDreamDetailBottomSheet(Dream dream) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rüya Detayları',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      
                      _buildDetailRow('Tarih', dream.formattedDate),
                      _buildDetailRow('Durum', dream.statusText),
                      _buildDetailRow('Dosya', dream.fileName?.split('/').last ?? 'Bilinmiyor'),
                      
                      if (dream.analysis != null && dream.analysis!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Analiz Sonucu',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            dream.analysis!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ] else if (dream.status == DreamStatus.processing) ...[
                        const SizedBox(height: 24),
                        const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Analiz işleniyor...'),
                            ],
                          ),
                        ),
                      ] else if (dream.status == DreamStatus.failed) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Analiz sırasında bir hata oluştu. Lütfen yeniden deneyin.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
