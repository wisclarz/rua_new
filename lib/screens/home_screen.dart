import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_interface.dart';
import '../providers/dream_provider.dart';
import '../models/dream_model.dart';
import '../widgets/dream_detail_widget.dart';

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
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  String _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅';
    if (hour < 18) return '☀️';
    return '🌙';
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
      body: Consumer2<AuthProviderInterface, DreamProvider>(
        builder: (context, authProvider, dreamProvider, child) {
          final user = authProvider.currentUser;
          
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildModernHeader(context, user),
              ),
              
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
                          Navigator.pushNamed(context, '/history');
                        },
                        child: const Text('Tümünü Gör'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms),
                ),
              ),
              
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
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      width: 60,
      height: 60,
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
            fontSize: 24,
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

  Widget _buildDreamCard(BuildContext context, Dream dream) {
    final theme = Theme.of(context);
    final moodColor = _getMoodColor(dream.mood);
    final moodEmoji = _getMoodEmoji(dream.mood);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: moodColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDreamDetail(dream),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: moodColor.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Emoji Badge
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: moodColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          moodEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _capitalizeFirst(dream.title),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dream.formattedDate,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Status & Mood Row
                Row(
                  children: [
                    // Mood Chip
                    if (dream.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: moodColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: moodColor,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _capitalizeFirst(dream.mood),
                          style: TextStyle(
                            color: moodColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    
                    const Spacer(),
                    
                    // Status Chip
                    _buildStatusChip(dream, theme),
                  ],
                ),
                
                // Content Preview
                if (dream.isCompleted && 
                    dream.interpretation != null && 
                    dream.interpretation!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dream.interpretation!.length > 80
                                ? '${dream.interpretation!.substring(0, 80)}...'
                                : dream.interpretation!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (dream.isProcessing) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rüyanız analiz ediliyor...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Symbols
                if (dream.isCompleted && 
                    dream.symbols != null && 
                    dream.symbols!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dream.symbols!.take(3).map((symbol) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.purple[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              _capitalizeFirst(symbol),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Dream dream, ThemeData theme) {
    Color color;
    String text;
    IconData icon;
    
    if (dream.isCompleted) {
      color = Colors.green;
      text = 'Tamamlandı';
      icon = Icons.check_circle;
    } else if (dream.isProcessing) {
      color = Colors.orange;
      text = 'Analiz Ediliyor';
      icon = Icons.hourglass_empty;
    } else {
      color = Colors.red;
      text = 'Başarısız';
      icon = Icons.error;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
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

  void _openDreamDetail(Dream dream) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DreamDetailWidget(dream: dream),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'mutlu':
      case 'heyecanlı':
        return const Color(0xFF10B981);
      case 'kaygılı':
        return const Color(0xFFF59E0B);
      case 'korkulu':
        return const Color(0xFFEF4444);
      case 'huzurlu':
        return const Color(0xFF3B82F6);
      case 'şaşkın':
        return const Color(0xFFFBBF24);
      case 'huzursuz':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'mutlu':
        return '😊';
      case 'kaygılı':
        return '😰';
      case 'huzurlu':
        return '😌';
      case 'korkulu':
        return '😨';
      case 'heyecanlı':
        return '🤩';
      case 'şaşkın':
        return '😲';
      case 'huzursuz':
        return '😟';
      default:
        return '😐';
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'mutlu':
        return Icons.sentiment_very_satisfied;
      case 'kaygılı':
        return Icons.sentiment_neutral;
      case 'huzurlu':
        return Icons.sentiment_satisfied;
      case 'korkulu':
        return Icons.sentiment_very_dissatisfied;
      case 'heyecanlı':
        return Icons.emoji_emotions;
      case 'şaşkın':
        return Icons.sentiment_neutral_outlined;
      case 'huzursuz':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.help_outline;
    }
  }
}