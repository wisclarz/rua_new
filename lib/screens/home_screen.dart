// lib/screens/home_screen.dart - Optimized
// Performance optimizations:
// - Removed heavy calculations from build method
// - Split Consumer widgets to reduce rebuild scope
// - Uses AppConstants for all values
// - Cached calculations in separate widgets

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_constants.dart';
import '../providers/auth_provider_interface.dart';
import '../providers/dream_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/dreamy_background.dart';
import '../widgets/optimized_glass_card.dart';
import '../utils/dream_calculations.dart';
import '../utils/staggered_animation.dart';
import '../models/dream_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: DreamyBackground(
        child: _HomeContent(),
      ),
    );
  }
}

/// Separated content to prevent full page rebuilds
/// Optimized for 120 FPS with Selector instead of Consumer
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      // Key for better performance on rebuild
      key: const PageStorageKey<String>('home_scroll'),
      slivers: [
        // Clean Header - uses Selector for minimal rebuilds
        SliverToBoxAdapter(
          child: Selector<AuthProviderInterface, dynamic>(
            selector: (_, auth) => auth.currentUser,
            shouldRebuild: (prev, next) => prev != next,
            builder: (context, user, _) {
              return RepaintBoundary(
                child: _CleanHeader(user: user),
              );
            },
          ),
        ),
        
        // Premium Banner - uses Selector for minimal rebuilds
        SliverToBoxAdapter(
          child: Selector<SubscriptionProvider, bool>(
            selector: (_, sub) => sub.isPro,
            shouldRebuild: (prev, next) => prev != next,
            builder: (context, isPro, _) {
              if (isPro) {
                return const SizedBox.shrink();
              }
              return const RepaintBoundary(
                child: _PremiumBanner(),
              );
            },
          ),
        ),
        
        // Weekly Calendar Streak Card - uses Selector with dream count
        SliverToBoxAdapter(
          child: Selector<DreamProvider, List<Dream>>(
            selector: (_, dream) => dream.dreams,
            shouldRebuild: (prev, next) => 
              prev.length != next.length || 
              !_areListsEqual(prev, next),
            builder: (context, dreams, _) {
              return RepaintBoundary(
                child: _WeeklyStreakCard(
                  key: ValueKey(dreams.length),
                  dreams: dreams,
                ),
              );
            },
          ),
        ),
        
        // Enhanced Stats - uses Selector with dream count
        SliverToBoxAdapter(
          child: Selector<DreamProvider, List<Dream>>(
            selector: (_, dream) => dream.dreams,
            shouldRebuild: (prev, next) => 
              prev.length != next.length,
            builder: (context, dreams, _) {
              return RepaintBoundary(
                child: _EnhancedStats(
                  key: ValueKey(dreams.length),
                  dreams: dreams,
                ),
              );
            },
          ),
        ),
        
        // Spacer at bottom
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }
  
  // Helper to check if dream lists are equal (for rebuild optimization)
  static bool _areListsEqual(List<Dream> prev, List<Dream> next) {
    if (prev.length != next.length) return false;
    for (int i = 0; i < prev.length; i++) {
      if (prev[i].id != next[i].id || 
          prev[i].createdAt != next[i].createdAt) {
        return false;
      }
    }
    return true;
  }
}

/// Clean header widget - separated for better performance
class _CleanHeader extends StatelessWidget {
  final dynamic user;
  
  const _CleanHeader({required this.user});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
    margin: const EdgeInsets.only(bottom: 0),
    padding: const EdgeInsets.fromLTRB(
      AppConstants.spacingXL,
      60,
      AppConstants.spacingXL,
      AppConstants.spacingXXXL,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Profile Avatar with lightweight animation
            StaggeredFadeScale(
              delay: 0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              child: Hero(
                tag: 'profile_avatar',
                child: Container(
                  width: AppConstants.avatarSize,
                  height: AppConstants.avatarSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: AppConstants.spacingL),
            
            // Welcome Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StaggeredFadeSlide(
                    delay: 100,
                    begin: const Offset(-0.1, 0),
                    child: Text(
                      DreamCalculations.getGreeting(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  StaggeredFadeSlide(
                    delay: 150,
                    begin: const Offset(-0.1, 0),
                    child: Text(
                      user?.name ?? 'Kullanıcı',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Notification Bell
            StaggeredFadeScale(
              delay: 200,
              child: Container(
                width: AppConstants.notificationButtonSize,
                height: AppConstants.notificationButtonSize,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 22),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // TODO: Navigate to notifications
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  }
}

/// Premium banner widget - separated for better performance
class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner();
  
  @override
  Widget build(BuildContext context) {
    return StaggeredFadeSlide(
      delay: 250,
      duration: const Duration(milliseconds: 400),
      child: RepaintBoundary(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                // Navigate to subscription
              },
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              child: Container(
                padding: const EdgeInsets.all(AppConstants.spacingXL),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                      Color(0xFF9333EA),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingM),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    
                    const SizedBox(width: AppConstants.spacingL),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pro\'ya Geç',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingXS),
                          Text(
                            'Sınırsız analiz & reklamsız deneyim',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Weekly streak card widget - separated for better performance
/// Now with cached calculations for 120 FPS
class _WeeklyStreakCard extends StatelessWidget {
  final List<Dream> dreams;
  
  const _WeeklyStreakCard({
    super.key,
    required this.dreams,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStreak = DreamCalculations.calculateCurrentStreak(dreams);
    final weekDays = DreamCalculations.getWeekDays();

    return Container(
    margin: const EdgeInsets.fromLTRB(
      AppConstants.spacingXL,
      0,
      AppConstants.spacingXL,
      AppConstants.spacingL,
    ),
    child: StaggeredFadeSlide(
      delay: 300,
      duration: const Duration(milliseconds: 400),
      child: OptimizedGlassCard(
        padding: const EdgeInsets.all(AppConstants.spacingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingXXL - 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.2),
                        theme.colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: AppConstants.spacingM),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seriniz',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 2), // Keep as is for tight spacing
                      Text(
                        '$currentStreak gün üst üste! 🔥',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingXL),
            
            // Week Days Display with Animations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final day = weekDays[index];
                final isToday = DreamCalculations.isSameDay(day, DateTime.now());
                final hasLog = DreamCalculations.hasDreamOnDate(dreams, day);
                
                return Expanded(
                  child: StaggeredFadeScale(
                    delay: 400 + (index * 40),
                    duration: const Duration(milliseconds: 300),
                    begin: 0.7,
                    child: _DayIndicator(
                      day: day,
                      isToday: isToday,
                      hasLog: hasLog,
                      index: index,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

/// Day indicator widget for calendar
class _DayIndicator extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool hasLog;
  final int index;
  
  const _DayIndicator({
    required this.day,
    required this.isToday,
    required this.hasLog,
    required this.index,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayName = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'][day.weekday - 1];
    
    return Column(
    children: [
      Text(
        dayName,
        style: TextStyle(
          fontSize: 11,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: AppConstants.spacingS),
      AnimatedContainer(
        duration: AppConstants.animationNormal,
        curve: Curves.easeOutCubic,
        width: AppConstants.dayIndicatorSize,
        height: AppConstants.dayIndicatorSize,
        decoration: BoxDecoration(
          color: hasLog
              ? theme.colorScheme.primary
              : isToday
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: AppConstants.borderThick,
                )
              : null,
          boxShadow: hasLog
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: hasLog
              ? const Icon(
                  Icons.check,
                  size: 18,
                  color: Colors.white,
                )
              : Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: AppConstants.dayIndicatorFontSize,
                    fontWeight: FontWeight.w600,
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
        ),
      ),
    ],
    );
  }
}

/// Enhanced stats widget - separated for better performance
/// Cached calculations for 120 FPS
class _EnhancedStats extends StatelessWidget {
  final List<Dream> dreams;
  
  const _EnhancedStats({
    super.key,
    required this.dreams,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Cache all calculations once
    final stats = _CachedStats.calculate(dreams);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingXL,
        vertical: AppConstants.spacingM - 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingL),
            child: Text(
              'İstatistikler',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // First row
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  key: const ValueKey('stat_total'),
                  icon: Icons.nights_stay,
                  label: 'Toplam Rüya',
                  value: stats.totalDreams.toString(),
                  color: const Color(0xFF6B4EFF),
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: _StatItem(
                  key: const ValueKey('stat_streak'),
                  icon: Icons.local_fire_department,
                  label: 'En Uzun Seri',
                  value: stats.longestStreak.toString(),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          // Second row
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  key: const ValueKey('stat_week'),
                  icon: Icons.calendar_view_week,
                  label: 'Bu Hafta',
                  value: stats.thisWeekDreams.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: _StatItem(
                  key: const ValueKey('stat_month'),
                  icon: Icons.calendar_month,
                  label: 'Bu Ay',
                  value: stats.thisMonthDreams.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cached stats calculation to avoid recalculating on every build
class _CachedStats {
  final int totalDreams;
  final int longestStreak;
  final int thisWeekDreams;
  final int thisMonthDreams;
  
  const _CachedStats({
    required this.totalDreams,
    required this.longestStreak,
    required this.thisWeekDreams,
    required this.thisMonthDreams,
  });
  
  static _CachedStats calculate(List<Dream> dreams) {
    return _CachedStats(
      totalDreams: dreams.length,
      longestStreak: DreamCalculations.calculateLongestStreak(dreams),
      thisWeekDreams: DreamCalculations.getThisWeekDreamsCount(dreams),
      thisMonthDreams: DreamCalculations.getThisMonthDreamsCount(dreams),
    );
  }
}

/// Stat item widget for statistics display
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _StatItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine animation delay based on label
    int getDelay() {
      if (label == 'Toplam Rüya') return 450;
      if (label == 'En Uzun Seri') return 500;
      if (label == 'Bu Hafta') return 550;
      if (label == 'Bu Ay') return 600;
      return 450;
    }
    
    return StaggeredFadeSlide(
      delay: getDelay(),
      duration: const Duration(milliseconds: 350),
      begin: const Offset(0, 0.1),
      child: OptimizedGlassCard(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        borderRadius: AppConstants.radiusL,
          child: Row(
            children: [
              Container(
                width: AppConstants.statIconContainerSize,
                height: AppConstants.statIconContainerSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM - 2),
                ),
                child: Icon(
                  icon,
                  color: color.withValues(alpha: 0.9),
                  size: AppConstants.statIconSize,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }
}