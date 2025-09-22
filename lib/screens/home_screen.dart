import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dream_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _greetingController;
  late AnimationController _cardController;

  @override
  void initState() {
    super.initState();
    _greetingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Load dreams after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDreams();
    });
    
    _greetingController.forward();
    _cardController.forward();
  }

  @override
  void dispose() {
    _greetingController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadDreams() async {
    try {
      final dreamProvider = Provider.of<DreamProvider>(context, listen: false);
      await dreamProvider.fetchDreams();
    } catch (e) {
      debugPrint('Error loading dreams: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Günaydın';
    } else if (hour < 18) {
      return 'İyi günler';
    } else {
      return 'İyi akşamlar';
    }
  }

  String _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '🌅';
    } else if (hour < 18) {
      return '☀️';
    } else {
      return '🌙';
    }
  }

  String _getDateText() {
    final now = DateTime.now();
    final weekdays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 
                    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Consumer2<AuthProvider, DreamProvider>(
        builder: (context, authProvider, dreamProvider, child) {
          final user = authProvider.currentUser;
          
          return CustomScrollView(
            slivers: [
              // Modern Header
              SliverToBoxAdapter(
                child: _buildModernHeader(context, user),
              ),
              
              // Recent Dreams Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Son Rüyalarım',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to all dreams
                        },
                        child: const Text('Tümünü Gör'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms),
                ),
              ),
              
              // Dreams List or Empty State
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: dreamProvider.isLoading
                    ? SliverToBoxAdapter(
                        child: Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        ),
                      )
                    : dreamProvider.dreams.isEmpty
                        ? SliverToBoxAdapter(
                            child: _buildEmptyState(context),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= dreamProvider.dreams.length) return null;
                                
                                final dream = dreamProvider.dreams[index];
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 375),
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        child: _buildDreamCard(context, dream),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: dreamProvider.dreams.length > 5 
                                  ? 5 
                                  : dreamProvider.dreams.length,
                            ),
                          ),
              ),
              
              // Modern Stats Section
              if (user?.stats != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Detaylı İstatistikler',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to detailed stats
                              },
                              child: Text(
                                'Tümünü Gör',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailedStatsGrid(context, user!),
                      ],
                    ).animate().fadeIn(delay: 700.ms),
                  ),
                ),
              
              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, user) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.secondary.withOpacity(0.02),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with greeting and profile
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onBackground,
                        letterSpacing: -1,
                      ),
                    ).animate().slideX(
                      delay: 100.ms,
                      duration: 600.ms,
                      begin: -0.5,
                      curve: Curves.easeOutCubic,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.name ?? 'Kullanıcı',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().slideX(
                      delay: 200.ms,
                      duration: 600.ms,
                      begin: -0.5,
                      curve: Curves.easeOutCubic,
                    ),
                  ],
                ),
              ),
              // Profile Avatar
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty
                        ? Image.network(
                            user.profileImageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultAvatar(user.name),
                          )
                        : _buildDefaultAvatar(user?.name ?? 'U'),
                  ),
                ),
              ).animate().scale(
                delay: 300.ms,
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
            ],
          ),
          
          const SizedBox(height: 25),
          
          // Date and weather-like info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getGreetingIcon(),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDateText(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Rüya yolculuğuna devam et',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ).animate().slideY(
            delay: 400.ms,
            duration: 600.ms,
            begin: 0.3,
            curve: Curves.easeOutCubic,
          ),
          
          const SizedBox(height: 25),
          
          // Quick stats row
          _buildQuickStats(context, user),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, user) {
    final theme = Theme.of(context);
    final stats = user?.stats;
    
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatItem(
            context,
            'Rüyalar',
            '${stats?.totalDreams ?? 0}',
            Icons.bedtime_rounded,
            theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatItem(
            context,
            'Analizler',
            '${stats?.totalAnalyses ?? 0}',
            Icons.analytics_rounded,
            theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatItem(
            context,
            'Seri',
            '${stats?.currentStreak ?? 0}',
            Icons.local_fire_department_rounded,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    ).animate().scale(
      delay: Duration(milliseconds: 500 + (label.hashCode % 3) * 100),
      duration: 600.ms,
      curve: Curves.elasticOut,
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
      ),
      child: Center(
        child: Text(
          (name.isNotEmpty) ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 300,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.secondary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.nights_stay_rounded,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ).animate().scale(
            delay: 200.ms,
            duration: 800.ms,
            curve: Curves.elasticOut,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Rüya Yolculuğuna Başla',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
          
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Henüz rüya kaydın yok. İlk rüyanı kaydetmek için aşağıdaki mikrofon butonuna tıkla ve rüya analizine başla!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.tertiary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mic_rounded,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mikrofon butonuna tıkla',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().slideY(
            delay: 800.ms,
            duration: 600.ms,
            begin: 0.3,
            curve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _buildDreamCard(BuildContext context, dream) {
    final theme = Theme.of(context);
    final moodColor = _getMoodColor(dream?.mood ?? 'belirsiz');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.8),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to dream detail with animation
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: moodColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: moodColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getMoodIcon(dream?.mood ?? 'belirsiz'),
                        size: 22,
                        color: moodColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dream?.displayTitle ?? 'Başlıksız Rüya',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(dream?.date ?? dream?.createdAt ?? DateTime.now()),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildModernStatusChip(dream?.statusName ?? 'unknown', theme),
                  ],
                ),
                
                // Content Preview
                if (dream?.displayContent != null && dream!.displayContent!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      dream.displayContent!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                
                // Action Row
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: moodColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.psychology_rounded,
                              size: 16,
                              color: moodColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dream?.mood ?? 'Belirsiz',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: moodColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatusChip(String status, ThemeData theme) {
    Color color;
    String text;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        text = 'Tamamlandı';
        icon = Icons.check_circle_rounded;
        break;
      case 'processing':
        color = Colors.orange;
        text = 'İşleniyor';
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'pending':
        color = Colors.blue;
        text = 'Bekliyor';
        icon = Icons.schedule_rounded;
        break;
      default:
        color = Colors.grey;
        text = 'Bilinmiyor';
        icon = Icons.help_outline_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDetailedStatsGrid(BuildContext context, user) {
    final theme = Theme.of(context);
    final stats = user.stats;
    
    // List of stats to display
    final statsList = [
      {
        'title': 'Toplam Rüya',
        'value': '${stats?.totalDreams ?? 0}',
        'icon': Icons.bedtime_rounded,
        'color': theme.colorScheme.primary,
      },
      {
        'title': 'Analiz Edilen',
        'value': '${stats?.totalAnalyses ?? 0}',
        'icon': Icons.analytics_rounded,
        'color': Colors.green,
      },
      {
        'title': 'Mevcut Seri',
        'value': '${stats?.currentStreak ?? 0} gün',
        'icon': Icons.local_fire_department_rounded,
        'color': Colors.orange,
      },
      {
        'title': 'Ortalama Puan',
        'value': '${stats?.averageRating?.toStringAsFixed(1) ?? '0.0'}',
        'icon': Icons.star_rounded,
        'color': Colors.amber,
      },
    ];
    
    return Column(
      children: statsList.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (stat['color'] as Color).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (stat['color'] as Color).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat['title'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stat['value'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: stat['color'] as Color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ).animate(delay: Duration(milliseconds: 100 * index))
          .slideX(begin: 0.2, duration: 400.ms)
          .fadeIn();
      }).toList(),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'mutlu':
      case 'happy':
        return Colors.green;
      case 'üzgün':
      case 'sad':
        return Colors.blue;
      case 'kaygılı':
      case 'anxious':
        return Colors.orange;
      case 'korkmuş':
      case 'scared':
        return Colors.red;
      case 'huzurlu':
      case 'peaceful':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'mutlu':
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'üzgün':
      case 'sad':
        return Icons.sentiment_very_dissatisfied;
      case 'kaygılı':
      case 'anxious':
        return Icons.sentiment_neutral;
      case 'korkmuş':
      case 'scared':
        return Icons.sentiment_dissatisfied;
      case 'huzurlu':
      case 'peaceful':
        return Icons.sentiment_satisfied;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Bugün';
    } else if (difference == 1) {
      return 'Dün';
    } else if (difference < 7) {
      return '$difference gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

}