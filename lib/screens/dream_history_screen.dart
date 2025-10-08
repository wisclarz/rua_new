// lib/screens/dream_history_screen.dart - Enhanced with Staggered Animations

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animations/animations.dart';
import '../providers/dream_provider.dart';
import '../models/dream_model.dart';
import '../widgets/dream_detail_widget.dart';
import '../widgets/decorative_header.dart';

class DreamHistoryScreen extends StatefulWidget {
  const DreamHistoryScreen({super.key});

  @override
  State<DreamHistoryScreen> createState() => _DreamHistoryScreenState();
}

class _DreamHistoryScreenState extends State<DreamHistoryScreen> 
    with AutomaticKeepAliveClientMixin {
  String _selectedFilter = 'all';

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<DreamProvider>(
        builder: (context, dreamProvider, child) {
          if (dreamProvider.isLoading) {
            return _buildLoadingState(theme);
          }

          if (dreamProvider.errorMessage != null) {
            return _buildErrorState(dreamProvider.errorMessage!, theme);
          }

          final filteredDreams = _getFilteredDreams(dreamProvider.dreams);

          if (filteredDreams.isEmpty) {
            return Stack(
              children: [
                // Floating background clouds
                Positioned.fill(
                  child: FloatingClouds(
                    clouds: FloatingClouds.subtleClouds(theme),
                  ),
                ),
                
                // Main content
                CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: DecorativeHeader(
                        title: 'Rüya Geçmişi',
                        subtitle: 'Geçmiş rüyalarınızı inceleyin',
                        decorations: DecorativeHeader.cloudDecorations(theme),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: GradientTransition(),
                    ),
                    SliverFillRemaining(
                      child: _buildEmptyState(theme),
                    ),
                  ],
                ),
              ],
            );
          }

          return Stack(
            children: [
              // Floating background clouds
              Positioned.fill(
                child: FloatingClouds(
                  clouds: FloatingClouds.scatteredClouds(theme),
                ),
              ),
              
              // Main content with refresh
              RefreshIndicator(
            onRefresh: _loadDreams,
            color: theme.colorScheme.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Decorative Header
                SliverToBoxAdapter(
                  child: DecorativeHeader(
                    title: 'Rüya Geçmişi',
                    subtitle: '${dreamProvider.dreams.length} rüya kaydedildi',
                    decorations: DecorativeHeader.cloudDecorations(theme),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton.filled(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _loadDreams();
                            },
                            tooltip: 'Yenile',
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              foregroundColor: theme.colorScheme.onPrimaryContainer,
                            ),
                          )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .rotate(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Gradient Transition
                const SliverToBoxAdapter(
                  child: GradientTransition(),
                ),
                
                // Filter Chips
                SliverToBoxAdapter(
                  child: _buildFilterChips(dreamProvider.dreams, theme),
                ),
                
                // Dreams List
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 400),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildDreamCard(
                                filteredDreams[index],
                                theme,
                                index,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filteredDreams.length,
                    ),
                  ),
                ),
              ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 2000.ms),
          
          const SizedBox(height: 24),
          
          Text(
            'Rüyalar yükleniyor...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          )
            .animate(onPlay: (controller) => controller.repeat())
            .fadeIn(duration: 1000.ms)
            .then(delay: 200.ms)
            .fadeOut(duration: 1000.ms),
        ],
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
            _buildFilterChip('all', 'Tümü', allDreams.length, Icons.all_inclusive, theme, 0),
            const SizedBox(width: 8),
            _buildFilterChip('completed', 'Tamamlanan', allDreams.where((d) => d.isCompleted).length, Icons.check_circle, theme, 1),
            const SizedBox(width: 8),
            _buildFilterChip('processing', 'İşleniyor', allDreams.where((d) => d.isProcessing).length, Icons.hourglass_empty, theme, 2),
            const SizedBox(width: 8),
            _buildFilterChip('failed', 'Başarısız', allDreams.where((d) => d.isFailed).length, Icons.error, theme, 3),
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
    int index,
  ) {
    final isSelected = _selectedFilter == value;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: FilterChip(
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
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        selectedColor: theme.colorScheme.primaryContainer,
        checkmarkColor: theme.colorScheme.primary,
        side: BorderSide(
          color: isSelected 
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 1.5 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        elevation: isSelected ? 2 : 0,
        shadowColor: theme.colorScheme.primary.withOpacity(0.2),
      ),
    )
      .animate()
      .fadeIn(delay: (index * 100).ms, duration: 400.ms)
      .slideX(begin: 0.2, end: 0, delay: (index * 100).ms);
  }

  Widget _buildDreamCard(Dream dream, ThemeData theme, int index) {
    final Color statusColor = dream.isCompleted
        ? Colors.green
        : dream.isProcessing
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        child: OpenContainer(
          closedElevation: 0,
          openElevation: 0,
          closedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          closedColor: theme.colorScheme.surface,
          openColor: theme.colorScheme.surface,
          transitionDuration: const Duration(milliseconds: 500),
          transitionType: ContainerTransitionType.fadeThrough,
          closedBuilder: (context, action) {
            return InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                action();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Status Icon with Animated Background
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            dream.isCompleted
                                ? Icons.check_circle
                                : dream.isProcessing
                                    ? Icons.hourglass_empty
                                    : Icons.error,
                            color: statusColor,
                            size: 22,
                          ),
                        )
                          .animate(onPlay: (controller) {
                            if (dream.isProcessing) {
                              controller.repeat();
                            }
                          })
                          .rotate(
                            duration: 2000.ms,
                            begin: 0,
                            end: dream.isProcessing ? 1 : 0,
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dream.formattedDate,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ],
                    ),
                    
                    // Content Preview
                    if (dream.isCompleted && dream.interpretation != null) ...[
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: theme.dividerColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                dream.interpretation!.length > 100
                                    ? '${dream.interpretation!.substring(0, 100)}...'
                                    : dream.interpretation!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                                  height: 1.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Symbols Badge
                      if (dream.symbols != null && dream.symbols!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: dream.symbols!.take(3).map((symbol) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.withOpacity(0.15),
                                    Colors.deepPurple.withOpacity(0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.purple.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: Colors.purple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    // Baş harfi büyük yap
                                    symbol.substring(0, 1).toUpperCase() + symbol.substring(1),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                              .animate()
                              .fadeIn(delay: (300 + index * 50).ms)
                              .scale(delay: (300 + index * 50).ms);
                          }).toList(),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            );
          },
          openBuilder: (context, action) {
            return DreamDetailWidget(dream: dream);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.2),
                          theme.colorScheme.secondary.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.nights_stay_outlined,
                      size: 60,
                      color: theme.colorScheme.primary.withOpacity(0.6),
                    ),
                  )
                    .animate()
                    .scale(duration: 800.ms, curve: Curves.elasticOut)
                    .then(delay: 1000.ms)
                    .shake(duration: 500.ms, hz: 2),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    _selectedFilter == 'all' 
                        ? 'Henüz Rüya Kaydın Yok'
                        : 'Bu Kategoride Rüya Bulunamadı',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 12),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _selectedFilter == 'all'
                          ? 'Ana ekrandan yeni bir rüya kaydet\nve analiz sonuçlarını gör!'
                          : 'Farklı bir kategori seçmeyi dene',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms),
                ],
              ),
            );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.withOpacity(0.6),
          )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .shake(duration: 1000.ms),
          
          const SizedBox(height: 24),
          
          Text(
            'Bir hata oluştu',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton.icon(
            onPressed: _loadDreams,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}