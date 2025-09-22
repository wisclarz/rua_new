import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dream_provider.dart';
import '../widgets/glassmorphic_container.dart';

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
    final dreamProvider = Provider.of<DreamProvider>(context, listen: false);
    await dreamProvider.fetchDreams();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Consumer2<AuthProvider, DreamProvider>(
          builder: (context, authProvider, dreamProvider, child) {
            final user = authProvider.currentUser;
            
            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeader(context, user?.name ?? 'Kullanıcı'),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, '/profile'),
                      icon: CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primary,
                        child: user?.profileImageUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.profileImageUrl!,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                (user?.name?.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                
                // Quick Action Card
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: GlassmorphicContainer(
                      borderRadius: 20,
                      blurValue: 20,
                      opacityValue: 0.15,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.mic,
                                    color: theme.colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Yeni Rüya Kaydet',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Ses kaydı ile rüyanı anlat',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _startRecording(context, dreamProvider),
                                icon: const Icon(Icons.fiber_manual_record, color: Colors.red),
                                label: const Text('Kayıt Başlat'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().slide(delay: 300.ms, duration: 600.ms, begin: const Offset(0, 1)),
                  ),
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
                
                // Dreams List
                if (dreamProvider.isLoading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (dreamProvider.dreams.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
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
                
                // Stats Section
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bu Haftaki İstatistikler',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (user?.stats != null) _buildStatsGrid(context, user!),
                      ],
                    ).animate().fadeIn(delay: 700.ms),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String? userName) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.secondary.withOpacity(0.6),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                Text(
                  _getGreetingIcon(),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 500.ms, duration: 1000.ms),
                      const SizedBox(height: 4),
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            userName ?? 'Kullanıcı',
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                            speed: const Duration(milliseconds: 100),
                          ),
                        ],
                        repeatForever: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.bedtime_outlined,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz rüya kaydın yok',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk rüyanı kaydetmek için yukarıdaki butona tıkla!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDreamCard(BuildContext context, dream) {
    final theme = Theme.of(context);
    
    return GlassmorphicContainer(
      borderRadius: 16,
      blurValue: 15,
      opacityValue: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getMoodColor(dream.mood ?? 'belirsiz').withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getMoodIcon(dream.mood ?? 'belirsiz'),
                    size: 16,
                    color: _getMoodColor(dream.mood ?? 'belirsiz'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dream.title ?? 'Başlıksız Rüya',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDate(dream.date ?? DateTime.now()),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(dream.status?.name ?? 'unknown'),
              ],
            ),
            if (dream.dreamText != null) ...[
              const SizedBox(height: 12),
              Text(
                dream.dreamText!,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        text = 'Tamamlandı';
        break;
      case 'processing':
        color = Colors.orange;
        text = 'İşleniyor';
        break;
      case 'pending':
        color = Colors.blue;
        text = 'Bekliyor';
        break;
      default:
        color = Colors.grey;
        text = 'Bilinmiyor';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, user) {
    final theme = Theme.of(context);
    final stats = user.stats;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Toplam Rüya',
          '${stats?.totalDreams ?? 0}',
          Icons.bedtime_outlined,
          theme.colorScheme.primary,
        ),
        _buildStatCard(
          context,
          'Analiz Edilen',
          '${stats?.totalAnalyses ?? 0}',
          Icons.analytics_outlined,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Mevcut Seri',
          '${stats?.currentStreak ?? 0} gün',
          Icons.local_fire_department_outlined,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Ortalama Puan',
          '${stats?.averageRating?.toStringAsFixed(1) ?? '0.0'}',
          Icons.star_outline,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return AnimationConfiguration.staggeredList(
      position: 0,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: GlassmorphicContainer(
            borderRadius: 16,
            blurValue: 15,
            opacityValue: 0.1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

  void _startRecording(BuildContext context, DreamProvider dreamProvider) {
    // Show recording dialog or navigate to recording screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rüya Kaydı'),
        content: const Text('Ses kaydı özelliği yakında eklenecek!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}