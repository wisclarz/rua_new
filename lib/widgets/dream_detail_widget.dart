// lib/widgets/dream_detail_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/dream_model.dart';
import '../providers/subscription_provider.dart';
import '../screens/subscription_screen.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _watchAdToUnlock(SubscriptionProvider provider) async {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    if (!provider.isAdLoaded) {
      await provider.loadRewardedAd();
    }

    Navigator.pop(context);

    final success = await provider.showRewardedAd();
    
    if (success) {
      setState(() {
        _isUnlocked = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Rüya analizi açıldı!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reklam yüklenemedi. Lütfen tekrar deneyin.'),
            duration: Duration(seconds: 2),
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

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Rüya Detayları'),
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            actions: [
              if (!isPro && !_isUnlocked)
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.workspace_premium, size: 18),
                  label: const Text('Pro'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber,
                  ),
                ),
            ],
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.1),
                        theme.colorScheme.secondary.withOpacity(0.05),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.dream.title,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          _buildStatusChip(theme),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Metadata Row
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildMetaItem(
                            icon: Icons.calendar_today,
                            text: widget.dream.formattedDate,
                            theme: theme,
                          ),
                          if (widget.dream.mood != 'Belirsiz')
                            _buildMetaItem(
                              icon: Icons.mood,
                              text: widget.dream.mood,
                              theme: theme,
                            ),
                          if (widget.dream.symbols != null && 
                              widget.dream.symbols!.isNotEmpty)
                            _buildMetaItem(
                              icon: Icons.auto_awesome,
                              text: '${widget.dream.symbols!.length} Simge',
                              theme: theme,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Content Sections
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    
                    if (widget.dream.dreamText != null && 
                        widget.dream.dreamText!.isNotEmpty) ...[
                      _buildContentSection(
                        theme: theme,
                        title: '📝 Rüyanız',
                        icon: Icons.description,
                        content: widget.dream.dreamText!,
                        shouldBlur: false, // User's own dream text is always visible
                      ),
                      const SizedBox(height: 20),
                    ],
// Rüya Analizi (analysis)
                    if (widget.dream.analysis != null && 
                        widget.dream.analysis!.isNotEmpty) ...[
                      _buildContentSection(
                        theme: theme,
                        title: '🌙 Rüya Analizi',
                        icon: Icons.psychology,
                        content: widget.dream.analysis!,
                        shouldBlur: false, // Analysis is always visible
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Psikolojik Analiz (interpretation) - with blur
                    if (widget.dream.interpretation != null && 
                        widget.dream.interpretation!.isNotEmpty) ...[
                      _buildContentSection(
                        theme: theme,
                        title: '🧠 Psikolojik Analiz',
                        icon: Icons.psychology,
                        content: widget.dream.interpretation!,
                        shouldBlur: shouldBlur,
                        provider: provider,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Geçmişle Bağlantı (connectionToPast) - with blur
                    if (widget.dream.connectionToPast != null && 
                        widget.dream.connectionToPast!.trim().isNotEmpty) ...[
                      _buildContentSection(
                        theme: theme,
                        title: '🔗 Geçmiş Rüyalarınızla Bağlantı',
                        icon: Icons.timeline,
                        content: widget.dream.connectionToPast!,
                        shouldBlur: shouldBlur,
                        provider: provider,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Symbols Section
                    if (widget.dream.symbols != null && 
                        widget.dream.symbols!.isNotEmpty) ...[
                      _buildSymbolsSection(theme),
                      const SizedBox(height: 20),
                    ],

                    // Unlock Button (if needed)
                    if (shouldBlur) ...[
                      const SizedBox(height: 20),
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
        );
      },
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String text,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required String content,
    required bool shouldBlur,
    SubscriptionProvider? provider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Content
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
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.7,
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
            ),
            
            // Blur Overlay
            if (shouldBlur)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 48,
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Pro Özellik',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bu içeriği görmek için Pro\'ya geçin\nveya reklam izleyin',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSymbolsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 20,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '✨ Rüya Simgeleri',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: widget.dream.symbols!.map((symbol) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.1),
                    Colors.deepPurple.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    symbol,
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUnlockButton(SubscriptionProvider provider, ThemeData theme) {
    return Column(
      children: [
        // Pro Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.workspace_premium),
            label: const Text(
              'Pro\'ya Geç - Sınırsız Erişim',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: theme.dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'veya',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(child: Divider(color: theme.dividerColor)),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Ad Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _watchAdToUnlock(provider),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text(
              'Reklam İzle - Bu Rüyayı Aç',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
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
    );
  }
}