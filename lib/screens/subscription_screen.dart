// lib/screens/subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription_model.dart';
import 'package:flutter/services.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<SubscriptionProvider>(
          builder: (context, provider, _) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(theme),
                  ),
                  
                  // Current Plan Info
                  SliverToBoxAdapter(
                    child: _buildCurrentPlanInfo(provider, theme),
                  ),
                  
                  // Plans
                  SliverToBoxAdapter(
                    child: _buildPlans(provider, theme),
                  ),
                  
                  // Features Comparison
                  SliverToBoxAdapter(
                    child: _buildFeaturesComparison(theme),
                  ),
                  
                  // Restore Purchases Button
                  SliverToBoxAdapter(
                    child: _buildRestoreButton(provider, theme),
                  ),
                  
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '✨ Premium\'a Geç',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reklamsız deneyim ve tüm özelliklere sınırsız erişim',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanInfo(SubscriptionProvider provider, ThemeData theme) {
    final currentPlan = provider.currentPlan;
    final isPro = provider.isPro;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPro 
            ? const Color(0xFF6B4EFF).withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPro 
              ? const Color(0xFF6B4EFF).withValues(alpha: 0.3)
              : theme.dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPro ? const Color(0xFF6B4EFF) : theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPro ? Icons.star_rounded : Icons.info_outline_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktif Plan',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentPlan.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (isPro)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4EFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlans(SubscriptionProvider provider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planları Seç',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          
          // Free Plan
          _buildPlanCard(
            plan: SubscriptionPlan.free,
            provider: provider,
            theme: theme,
            isSelected: provider.currentPlan == SubscriptionPlan.free,
          ),
          
          const SizedBox(height: 12),
          
          // Weekly Pro Plan
          _buildPlanCard(
            plan: SubscriptionPlan.weeklyPro,
            provider: provider,
            theme: theme,
            isSelected: provider.currentPlan == SubscriptionPlan.weeklyPro,
          ),
          
          const SizedBox(height: 12),
          
          // Monthly Pro Plan (Popular)
          _buildPlanCard(
            plan: SubscriptionPlan.monthlyPro,
            provider: provider,
            theme: theme,
            isSelected: provider.currentPlan == SubscriptionPlan.monthlyPro,
            isPopular: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required SubscriptionPlan plan,
    required SubscriptionProvider provider,
    required ThemeData theme,
    required bool isSelected,
    bool isPopular = false,
  }) {
    final isPro = plan.isPro;
    
    return GestureDetector(
      onTap: () async {
        if (plan == SubscriptionPlan.free) return;
        if (isSelected) return;
        
        HapticFeedback.mediumImpact();
        await provider.purchaseSubscription(plan);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF6B4EFF).withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF6B4EFF)
                : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB800),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '🔥 POPÜLER',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.priceText,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPro 
                            ? const Color(0xFF6B4EFF)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (plan == SubscriptionPlan.monthlyPro)
                      Text(
                        '30 TL tasarruf',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF00C853),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            if (!isPro) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Her analiz için 1 dakika reklam izle',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (isSelected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4EFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF6B4EFF),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Aktif Plan',
                      style: TextStyle(
                        color: const Color(0xFF6B4EFF),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesComparison(ThemeData theme) {
    final features = [
      {
        'title': 'Rüya Analizi',
        'free': true,
        'pro': true,
      },
      {
        'title': 'Reklamsız Deneyim',
        'free': false,
        'pro': true,
      },
      {
        'title': 'Sınırsız Rüya Kaydı',
        'free': true,
        'pro': true,
      },
      {
        'title': 'Detaylı İstatistikler',
        'free': false,
        'pro': true,
      },
      {
        'title': 'Rüya Sembolleri',
        'free': true,
        'pro': true,
      },
      {
        'title': 'Öncelikli Destek',
        'free': false,
        'pro': true,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Özellik Karşılaştırması',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          
          // Header Row
          Row(
            children: [
              const Expanded(flex: 2, child: SizedBox()),
              Expanded(
                child: Center(
                  child: Text(
                    'Ücretsiz',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Pro',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6B4EFF),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          
          // Feature Rows
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    feature['title'] as String,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Icon(
                      (feature['free'] as bool)
                          ? Icons.check_circle
                          : Icons.remove_circle_outline,
                      size: 20,
                      color: (feature['free'] as bool)
                          ? Colors.green
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Icon(
                      (feature['pro'] as bool)
                          ? Icons.check_circle
                          : Icons.remove_circle_outline,
                      size: 20,
                      color: (feature['pro'] as bool)
                          ? const Color(0xFF6B4EFF)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRestoreButton(SubscriptionProvider provider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextButton(
        onPressed: provider.isLoading 
            ? null
            : () async {
                HapticFeedback.lightImpact();
                await provider.restorePurchases();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Satın almalar geri yüklendi'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
        child: Text(
          'Satın Almaları Geri Yükle',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}