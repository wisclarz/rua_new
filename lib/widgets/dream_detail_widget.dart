// lib/widgets/dream_detail_widget.dart - Yeni Format ile Güncellenmiş

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../models/dream_model.dart';
import '../providers/subscription_provider.dart';
import '../screens/subscription_screen.dart';
import '../utils/navigation_utils.dart';

class DreamDetailWidget extends StatefulWidget {
  final Dream dream;

  const DreamDetailWidget({
    super.key,
    required this.dream,
  });

  @override
  State<DreamDetailWidget> createState() => _DreamDetailWidgetState();
}

class _DreamDetailWidgetState extends State<DreamDetailWidget> 
    with TickerProviderStateMixin {
  late AnimationController _unlockController;
  late AnimationController _shimmerController;
  final ScrollController _scrollController = ScrollController();
  bool _isUnlocked = false;
  double _dragDistance = 0;

  @override
  void initState() {
    super.initState();
    _unlockController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _unlockController.dispose();
    _shimmerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _watchAdToUnlock(SubscriptionProvider provider) async {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reklam yükleniyor...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );

    if (!provider.isAdLoaded) {
      await provider.loadRewardedAd();
    }

    if (mounted) Navigator.pop(context);

    final success = await provider.showRewardedAd();
    
    if (success) {
      _unlockController.forward();
      setState(() {
        _isUnlocked = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✨ Rüya analizi açıldı!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Reklam yüklenemedi'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, _) {
        final isPro = provider.isPro;
        final shouldBlur = !isPro && !_isUnlocked;

        return GestureDetector(
          onVerticalDragUpdate: (details) {
            // Sadece scroll en üstteyken ve aşağı sürükleniyorsa
            if (_scrollController.hasClients && 
                _scrollController.position.pixels <= 0 &&
                details.primaryDelta! > 0) {
              setState(() {
                _dragDistance += details.primaryDelta!;
              });
            }
          },
          onVerticalDragEnd: (details) {
            // Yeterince aşağı sürüklendiyse kapat
            if (_dragDistance > 100) {
              Navigator.pop(context);
            }
            setState(() {
              _dragDistance = 0;
            });
          },
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
              // Animated Header Section
              SliverToBoxAdapter(
                child: _buildHeader(theme)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
              ),

              // Content Sections with Staggered Animation
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    
                    // 1. Rüya Metni
                    if (widget.dream.dreamText != null && 
                        widget.dream.dreamText!.isNotEmpty) ...[
                      _buildContentSection(
                        theme: theme,
                        title: 'Rüyanız',
                        icon: Icons.description,
                        content: widget.dream.dreamText!,
                        shouldBlur: false,
                        index: 0,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 2. Duygular Bölümü (YENİ FORMAT)
                    if (widget.dream.duygular != null || widget.dream.mood.isNotEmpty) ...[
                      _buildEmotionsSection(theme, index: 1),
                      const SizedBox(height: 20),
                    ],

                    // 3. Semboller
                    if (widget.dream.allSymbols.isNotEmpty) ...[
                      _buildSymbolsSection(theme, index: 2),
                      const SizedBox(height: 20),
                    ],

                    // 4. Rüya Analizi (YENİ FORMAT - Birleşik)
                    if (widget.dream.fullAnalysis.isNotEmpty && 
                        widget.dream.fullAnalysis != 'Analiz yapılıyor...' &&
                        widget.dream.fullAnalysis != 'Analiz bekleniyor...') ...[
                      _buildContentSection(
                        theme: theme,
                        title: 'Rüya Analizi',
                        icon: Icons.psychology,
                        content: widget.dream.fullAnalysis,
                        shouldBlur: shouldBlur,
                        provider: provider,
                        index: 3,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 5. Ruh Sağlığı Değerlendirmesi (YENİ)
                    if (widget.dream.ruhSagligi != null && 
                        widget.dream.ruhSagligi!.isNotEmpty) ...[
                      _buildContentSection(
                        theme: theme,
                        title: 'Ruh Sağlığı Değerlendirmesi',
                        icon: Icons.favorite,
                        content: widget.dream.ruhSagligi!,
                        shouldBlur: shouldBlur,
                        provider: provider,
                        index: 4,
                        gradient: [Colors.pink.withOpacity(0.2), Colors.red.withOpacity(0.1)],
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (shouldBlur) ...[
                      _buildUnlockButton(provider, theme),
                      const SizedBox(height: 40),
                    ] else ...[
                      const SizedBox(height: 40),
                    ],
                  ]),
                ),
              ),
            ],
          ),
              
              // Close Button - Top Right
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  color: theme.colorScheme.onSurface,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(duration: 400.ms, curve: Curves.elasticOut),
              
              // Pro Button - Top Left (if not pro)
              if (!isPro && !_isUnlocked)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // ⚡ Fast transition (120ms)
                        context.pushFast(const SubscriptionScreen());
                      },
                      icon: const Icon(Icons.workspace_premium, size: 18),
                      label: const Text('Pro'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    delay: 1000.ms,
                    duration: 2000.ms,
                    color: Colors.amber.withOpacity(0.3),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 64,
        24,
        24,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.bedtime,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .rotate(duration: 3000.ms, begin: -0.05, end: 0.05),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dream.baslik ?? widget.dream.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip(theme),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.dream.formattedDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    Color color;
    IconData icon;
    String text;

    switch (widget.dream.status) {
      case DreamStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Tamamlandı';
        break;
      case DreamStatus.processing:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        text = 'İşleniyor';
        break;
      case DreamStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        text = 'Başarısız';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    )
      .animate()
      .fadeIn(duration: 400.ms)
      .scale(duration: 400.ms, curve: Curves.elasticOut);
  }

  // YENİ: Duygular Bölümü
  Widget _buildEmotionsSection(ThemeData theme, {required int index}) {
    final anaDuygu = widget.dream.anaDuygu;
    final altDuygular = widget.dream.altDuygular;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.2),
                    Colors.lightBlue.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.mood, size: 20, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Text(
              'Rüyadaki Duygular',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Ana Duygu
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.lightBlue.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _getEmotionEmoji(anaDuygu),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ana Duygu',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        anaDuygu,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              if (altDuygular.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Alt Duygular',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: altDuygular.map((duygu) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        duygu,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    )
      .animate()
      .fadeIn(delay: (200 + index * 100).ms, duration: 600.ms)
      .slideY(begin: 0.2, end: 0, delay: (200 + index * 100).ms);
  }

  String _getEmotionEmoji(String emotion) {
    final emotionLower = emotion.toLowerCase();
    if (emotionLower.contains('öfke') || emotionLower.contains('kızgın')) return '😠';
    if (emotionLower.contains('korku')) return '😰';
    if (emotionLower.contains('üzgün') || emotionLower.contains('üzün')) return '😔';
    if (emotionLower.contains('huzur')) return '😌';
    if (emotionLower.contains('güçlü')) return '💪';
    if (emotionLower.contains('neşeli') || emotionLower.contains('mutlu')) return '😊';
    return '😐';
  }

  Widget _buildContentSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required String content,
    required bool shouldBlur,
    required int index,
    SubscriptionProvider? provider,
    List<Color>? gradient,
  }) {
    final gradientColors = gradient ?? [
      theme.colorScheme.primary.withOpacity(0.2),
      theme.colorScheme.secondary.withOpacity(0.1),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: gradient != null ? gradient[0].withOpacity(1) : theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
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
              child: Text(
                content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.7,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            
            if (shouldBlur)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 48,
                              color: theme.colorScheme.primary.withOpacity(0.6),
                            )
                              .animate(onPlay: (controller) => controller.repeat())
                              .shimmer(duration: 2000.ms),
                            
                            const SizedBox(height: 16),
                            
                            Text(
                              'Pro Özellik',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Bu içeriği görmek için Pro\'ya geçin\nveya reklam izleyin',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
                .animate()
                .fadeIn(duration: 400.ms),
          ],
        ),
      ],
    )
      .animate()
      .fadeIn(delay: (200 + index * 100).ms, duration: 600.ms)
      .slideY(begin: 0.2, end: 0, delay: (200 + index * 100).ms);
  }

  Widget _buildSymbolsSection(ThemeData theme, {required int index}) {
    final symbols = widget.dream.allSymbols;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.2),
                    Colors.deepPurple.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, size: 20, color: Colors.purple),
            ),
            const SizedBox(width: 12),
            Text(
              'Rüya Sembolleri',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: symbols.asMap().entries.map((entry) {
            final symbolIndex = entry.key;
            final symbol = entry.value;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.15),
                    Colors.deepPurple.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    symbol,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.purple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
              .animate()
              .fadeIn(delay: (400 + symbolIndex * 80).ms, duration: 400.ms)
              .scale(
                delay: (400 + symbolIndex * 80).ms,
                duration: 400.ms,
                curve: Curves.elasticOut,
              );
          }).toList(),
        ),
      ],
    )
      .animate()
      .fadeIn(delay: (200 + index * 100).ms, duration: 600.ms)
      .slideY(begin: 0.2, end: 0, delay: (200 + index * 100).ms);
  }

  Widget _buildUnlockButton(SubscriptionProvider provider, ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              // ⚡ Fast transition (120ms)
              context.pushFast(const SubscriptionScreen());
            },
            icon: const Icon(Icons.workspace_premium),
            label: const Text(
              'Pro\'ya Geç - Tüm Özellikler',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        )
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            delay: 1000.ms,
            duration: 2000.ms,
            color: Colors.white.withOpacity(0.3),
          ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(child: Divider(color: theme.dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'veya',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            Expanded(child: Divider(color: theme.dividerColor)),
          ],
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _watchAdToUnlock(provider),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text(
              'Reklam İzle - Bu Rüyayı Aç',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.5),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    )
      .animate()
      .fadeIn(delay: 800.ms, duration: 600.ms)
      .slideY(begin: 0.2, end: 0);
  }
}