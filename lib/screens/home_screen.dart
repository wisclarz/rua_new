import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../config/app_theme.dart';
import '../models/dream_model.dart';
import '../providers/auth_provider_interface.dart';
import '../providers/dream_provider.dart';
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
      body: Consumer2<AuthProviderInterface, DreamProvider>(
        builder: (context, authProvider, dreamProvider, _) {
          final user = authProvider.currentUser;
          final recentDreams = dreamProvider.dreams;
          
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Clean Header
              SliverToBoxAdapter(
                child: _buildCleanHeader(context, user, theme),
              ),
              
              // Minimal Stats
              SliverToBoxAdapter(
                child: _buildMinimalStats(context, dreamProvider, theme),
              ),
              
              // Recent Dreams Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Son Rüyalar',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${recentDreams.length} rüya',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      if (recentDreams.length > 5)
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(
                            'Tümünü Gör',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Dreams List
              if (recentDreams.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(context, theme),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final dream = recentDreams[index];
                        return _buildCleanDreamCard(context, dream, theme);
                      },
                      childCount: recentDreams.length > 5 ? 5 : recentDreams.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCleanHeader(BuildContext context, dynamic user, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.brightness == Brightness.light
              ? [
                  AppTheme.deepPurple.withValues(alpha: 0.05),
                  AppTheme.lightBackground,
                ]
              : [
                  AppTheme.darkBackground,
                  AppTheme.darkBackground,
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting with Profile
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _getGreeting(),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
              ),
              Text(
                _getGreetingIcon(),
                style: const TextStyle(fontSize: 48),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            user?.name ?? 'Rüya Yolcusu',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStats(BuildContext context, DreamProvider dreamProvider, ThemeData theme) {
    final totalDreams = dreamProvider.dreams.length;
    final completedDreams = dreamProvider.dreams.where((d) => d.isCompleted).length;
    final thisWeekDreams = dreamProvider.dreams.where((d) {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      return d.createdAt.isAfter(weekAgo);
    }).length;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          // First Row - 2 cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'Bu Hafta',
                  value: '$thisWeekDreams Rüya',
                  color: AppTheme.deepPurple,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.nightlight_round,
                  label: 'Toplam',
                  value: '$totalDreams Rüya',
                  color: AppTheme.richPurple,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.white
            : AppTheme.darkSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? AppTheme.lightOutline
              : const Color(0xFF3D2A5C),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.brightness == Brightness.light
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                  : const Color(0xFF9CA3AF),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanDreamCard(BuildContext context, Dream dream, ThemeData theme) {
    final moodColor = AppTheme.getMoodColor(dream.mood);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openDreamDetail(dream),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light
                ? Colors.white
                : AppTheme.darkSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.brightness == Brightness.light
                  ? AppTheme.lightOutline
                  : const Color(0xFF3D2A5C),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dream.isCompleted 
                          ? AppTheme.successGreen 
                          : theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dream.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: const Color(0xFF6B7280),
                    size: 18,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Date
              Text(
                _formatDate(dream.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
              
              // Mood Badge
              if (dream.mood != 'Belirsiz') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
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
                          color: moodColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Preview
              if (dream.isCompleted && dream.interpretation != null) ...[
                const SizedBox(height: 12),
                Text(
                  dream.interpretation!.length > 80
                      ? '${dream.interpretation!.substring(0, 80)}...'
                      : dream.interpretation!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF9CA3AF),
                    height: 1.5,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.nightlight_round,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz Rüya Kaydın Yok',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'İlk rüyanı kaydetmek için + butonuna tıkla',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
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
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Rüya Detayları'),
          ),
          body: DreamDetailWidget(dream: dream),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi Günler';
    return 'İyi Akşamlar';
  }

  String _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅';
    if (hour < 18) return '☀️';
    return '🌙';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) return 'Bugün';
    if (difference.inDays == 1) return 'Dün';
    if (difference.inDays < 7) return '${difference.inDays} gün önce';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'mutlu': return '😊';
      case 'kaygılı': return '😰';
      case 'huzurlu': return '😌';
      case 'korkulu': return '😨';
      case 'heyecanlı': return '🤩';
      case 'şaşkın': return '😲';
      case 'huzursuz': return '😟';
      default: return '😐';
    }
  }
}