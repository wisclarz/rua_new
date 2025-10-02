// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../config/app_theme.dart';
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
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.name.split(' ').first ?? 'Kullanıcı',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6B4EFF).withValues(alpha: 0.8),
                      const Color(0xFF9C27B0).withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B4EFF).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: user?.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user!.profileImageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(SubscriptionProvider provider, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SubscriptionScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6B4EFF).withValues(alpha: 0.15),
              const Color(0xFF9C27B0).withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF6B4EFF).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6B4EFF).withValues(alpha: 0.8),
                    const Color(0xFF9C27B0).withValues(alpha: 0.8),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4EFF).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium\'a Geç',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reklamsız, sınırsız rüya analizi',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4EFF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward,
                color: const Color(0xFF6B4EFF),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStreakCard(
    BuildContext context,
    DreamProvider dreamProvider,
    bool todayLogged,
    int currentStreak,
    ThemeData theme,
  ) {
    final last7Days = _getLast7Days();
    final dreamsMap = _getDreamsMapForWeek(dreamProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: todayLogged
              ? [
                  const Color(0xFF6B4EFF).withValues(alpha: 0.15),
                  const Color(0xFF9C27B0).withValues(alpha: 0.15),
                ]
              : [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: todayLogged
              ? const Color(0xFF6B4EFF).withValues(alpha: 0.3)
              : theme.dividerColor,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6B4EFF).withValues(alpha: 0.2),
                      const Color(0xFF9C27B0).withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  todayLogged ? Icons.check_circle : Icons.nights_stay,
                  color: const Color(0xFF6B4EFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayLogged ? 'Bugün Tamamlandı!' : 'Bugün Rüya Gördün mü?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      todayLogged ? 'Serini sürdürüyorsun' : 'Serini devam ettir',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (currentStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withValues(alpha: 0.2),
                        Colors.deepOrange.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 18,
                        color: Colors.orange.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$currentStreak',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Weekly Calendar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: last7Days.map((date) {
              final hasDream = dreamsMap.containsKey(_dateKey(date));
              final dreams = dreamsMap[_dateKey(date)] ?? [];
              final isToday = _isToday(date);
              
              return _buildDayCircle(
                context,
                date,
                hasDream,
                isToday,
                dreams,
                theme,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCircle(
    BuildContext context,
    DateTime date,
    bool hasDream,
    bool isToday,
    List<Dream> dreams,
    ThemeData theme,
  ) {
    final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final dayName = dayNames[date.weekday - 1];

    return GestureDetector(
      onTap: hasDream && dreams.isNotEmpty
          ? () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DreamDetailWidget(dream: dreams.first),
                ),
              );
            }
          : null,
      child: Column(
        children: [
          Text(
            dayName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: hasDream
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6B4EFF).withValues(alpha: 0.8),
                        const Color(0xFF9C27B0).withValues(alpha: 0.8),
                      ],
                    )
                  : null,
              color: hasDream ? null : theme.colorScheme.surface.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isToday
                    ? const Color(0xFF6B4EFF).withValues(alpha: 0.5)
                    : theme.dividerColor.withValues(alpha: 0.3),
                width: isToday ? 2 : 1,
              ),
              boxShadow: hasDream
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6B4EFF).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: hasDream
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : Text(
                      '${date.day}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
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