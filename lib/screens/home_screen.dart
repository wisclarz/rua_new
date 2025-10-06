// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../config/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../models/dream_model.dart';
import '../providers/auth_provider_interface.dart';
import '../providers/dream_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/subscription_screen.dart';
import '../widgets/dream_detail_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer3<AuthProviderInterface, DreamProvider, SubscriptionProvider>(
        builder: (context, authProvider, dreamProvider, subscriptionProvider, _) {
          final user = authProvider.currentUser;
          final todayLogged = _checkTodayDreamLogged(dreamProvider);
          final currentStreak = _calculateCurrentStreak(dreamProvider);
          final longestStreak = _calculateLongestStreak(dreamProvider);
          
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Clean Header
              SliverToBoxAdapter(
                child: _buildCleanHeader(context, user, theme),
              ),
              
              // Premium Banner (if not pro)
              if (!subscriptionProvider.isPro)
                SliverToBoxAdapter(
                  child: _buildPremiumBanner(subscriptionProvider, theme),
                ),
              
              // Weekly Calendar Streak Card
              SliverToBoxAdapter(
                child: _buildWeeklyStreakCard(context, dreamProvider, todayLogged, currentStreak, theme),
              ),
              
              // Enhanced Stats
              SliverToBoxAdapter(
                child: _buildEnhancedStats(context, dreamProvider, currentStreak, longestStreak, theme),
              ),
              
              // Spacer at bottom
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCleanHeader(BuildContext context, dynamic user, ThemeData theme) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.surface.withOpacity(0.08),
          theme.colorScheme.secondary.withOpacity(0.05),
        ],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Profile Avatar with Ripple Effect
            Hero(
              tag: 'profile_avatar',
              child: Container(
                width: 56,
                height: 56,
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
            )
              .animate()
              .scale(
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .shimmer(
                delay: 600.ms,
                duration: 1500.ms,
              ),
            
            const SizedBox(width: 16),
            
            // Welcome Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideX(begin: -0.2, end: 0),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    user?.name ?? 'Kullanıcı',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideX(begin: -0.2, end: 0),
                ],
              ),
            ),
            
            // Notification Bell with Pulse
            Container(
              width: 44,
              height: 44,
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
            )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(delay: 400.ms, duration: 400.ms)
              .scale(duration: 400.ms, curve: Curves.elasticOut)
              .then(delay: 3000.ms)
              .shake(duration: 400.ms, hz: 2),
          ],
        ),
      ],
    ),
  );
}
String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Günaydın';
  if (hour < 18) return 'İyi günler';
  return 'İyi akşamlar';
}

  Widget _buildPremiumBanner(dynamic subscriptionProvider, ThemeData theme) {
  return Container(
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          // Navigate to subscription
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
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
            borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 28,
                ),
              )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .rotate(duration: 2000.ms, begin: -0.02, end: 0.02)
                .scale(
                  duration: 2000.ms,
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                ),
              
              const SizedBox(width: 16),
              
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
                    const SizedBox(height: 4),
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
  )
    .animate()
    .fadeIn(delay: 400.ms, duration: 600.ms)
    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic)
    .shimmer(
      delay: 1000.ms,
      duration: 2000.ms,
      color: Colors.white.withOpacity(0.3),
    );
}


 Widget _buildWeeklyStreakCard(
  BuildContext context,
  dynamic dreamProvider,
  bool todayLogged,
  int currentStreak,
  ThemeData theme,
) {
  final now = DateTime.now();
  final weekDays = List.generate(7, (index) {
    return now.subtract(Duration(days: 6 - index));
  });

  return Container(
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      color: theme.colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.2),
                        theme.colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2000.ms, color: Colors.orange.withOpacity(0.3)),
                
                const SizedBox(width: 12),
                
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
                      const SizedBox(height: 2),
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
            
            const SizedBox(height: 20),
            
            // Week Days Display with Animations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final day = weekDays[index];
                final isToday = _isSameDay(day, now);
                final hasLog = _hasDreamOnDate(dreamProvider, day);
                
                return Expanded(
                  child: _buildDayIndicator(
                    day: day,
                    isToday: isToday,
                    hasLog: hasLog,
                    theme: theme,
                    index: index,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    ),
  )
    .animate()
    .fadeIn(delay: 500.ms, duration: 600.ms)
    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
}
Widget _buildShimmerCard(ThemeData theme) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surface,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
  );
}

  Widget _buildDayIndicator({
  required DateTime day,
  required bool isToday,
  required bool hasLog,
  required ThemeData theme,
  required int index,
}) {
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
      const SizedBox(height: 8),
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 36,
        height: 36,
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
                  width: 2,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
        ),
      )
        .animate()
        .fadeIn(delay: (600 + index * 50).ms, duration: 400.ms)
        .scale(
          delay: (600 + index * 50).ms,
          duration: 400.ms,
          curve: Curves.elasticOut,
        ),
    ],
  );
}
bool _isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

bool _hasDreamOnDate(dynamic dreamProvider, DateTime date) {
  return dreamProvider.dreams.any((dream) => _isSameDay(dream.createdAt, date));
}
  Widget _buildEnhancedStats(
    BuildContext context,
    DreamProvider dreamProvider,
    int currentStreak,
    int longestStreak,
    ThemeData theme,
  ) {
    final totalDreams = dreamProvider.dreams.length;
    final thisWeekDreams = _getThisWeekDreamsCount(dreamProvider);
    final thisMonthDreams = _getThisMonthDreamsCount(dreamProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
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
                child: _buildStatItem(
                  theme: theme,
                  icon: Icons.nights_stay,
                  label: 'Toplam Rüya',
                  value: totalDreams.toString(),
                  color: const Color(0xFF6B4EFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  theme: theme,
                  icon: Icons.local_fire_department,
                  label: 'En Uzun Seri',
                  value: longestStreak.toString(),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme: theme,
                  icon: Icons.calendar_view_week,
                  label: 'Bu Hafta',
                  value: thisWeekDreams.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  theme: theme,
                  icon: Icons.calendar_month,
                  label: 'Bu Ay',
                  value: thisMonthDreams.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color.withValues(alpha: 0.9), size: 22),
          ),
          const SizedBox(width: 12),
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
    );
  }

  // Helper methods
  List<DateTime> _getLast7Days() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });
  }

  Map<String, List<Dream>> _getDreamsMapForWeek(DreamProvider provider) {
    final map = <String, List<Dream>>{};
    final last7Days = _getLast7Days();
    
    for (final dream in provider.dreams) {
      final dreamDate = DateTime(
        dream.createdAt.year,
        dream.createdAt.month,
        dream.createdAt.day,
      );
      
      for (final day in last7Days) {
        final checkDate = DateTime(day.year, day.month, day.day);
        if (dreamDate == checkDate) {
          final key = _dateKey(day);
          map[key] = [...(map[key] ?? []), dream];
        }
      }
    }
    
    return map;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _checkTodayDreamLogged(DreamProvider provider) {
    final today = DateTime.now();
    return provider.dreams.any((dream) {
      final dreamDate = dream.createdAt;
      return dreamDate.year == today.year &&
          dreamDate.month == today.month &&
          dreamDate.day == today.day;
    });
  }

  int _calculateCurrentStreak(DreamProvider provider) {
    if (provider.dreams.isEmpty) return 0;

    final sortedDreams = provider.dreams.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    final latestDream = sortedDreams.first;
    final latestDate = DateTime(
      latestDream.createdAt.year,
      latestDream.createdAt.month,
      latestDream.createdAt.day,
    );
    
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
    
    if (latestDate != todayDate && latestDate != yesterdayDate) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = todayDate;
    
    for (var dream in sortedDreams) {
      final dreamDate = DateTime(
        dream.createdAt.year,
        dream.createdAt.month,
        dream.createdAt.day,
      );
      
      if (dreamDate == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (dreamDate.isBefore(checkDate)) {
        final daysDiff = checkDate.difference(dreamDate).inDays;
        if (daysDiff > 1) break;
        checkDate = dreamDate.subtract(const Duration(days: 1));
      }
    }
    
    return streak;
  }

  int _calculateLongestStreak(DreamProvider provider) {
    if (provider.dreams.isEmpty) return 0;

    final sortedDreams = provider.dreams.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int maxStreak = 0;
    int currentStreak = 1;
    
    for (int i = 0; i < sortedDreams.length - 1; i++) {
      final current = DateTime(
        sortedDreams[i].createdAt.year,
        sortedDreams[i].createdAt.month,
        sortedDreams[i].createdAt.day,
      );
      final next = DateTime(
        sortedDreams[i + 1].createdAt.year,
        sortedDreams[i + 1].createdAt.month,
        sortedDreams[i + 1].createdAt.day,
      );
      
      final diff = current.difference(next).inDays;
      
      if (diff == 1) {
        currentStreak++;
      } else {
        maxStreak = math.max(maxStreak, currentStreak);
        currentStreak = 1;
      }
    }
    
    return math.max(maxStreak, currentStreak);
  }

  int _getThisWeekDreamsCount(DreamProvider provider) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    return provider.dreams.where((dream) {
      return dream.createdAt.isAfter(weekStartDate);
    }).length;
  }

  int _getThisMonthDreamsCount(DreamProvider provider) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    return provider.dreams.where((dream) {
      return dream.createdAt.isAfter(monthStart);
    }).length;
  }
}