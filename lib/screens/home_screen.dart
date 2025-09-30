import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_interface.dart';
import '../providers/dream_provider.dart';
import '../models/dream_model.dart';
import '../widgets/dream_detail_widget.dart';
import 'dream_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _greetingController;
  late AnimationController _cardController;

  // ✅ EKLEME: AutomaticKeepAliveClientMixin ile state'i koru
  @override
  bool get wantKeepAlive => true;

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
    
    // ✅ DÜZELTME: Real-time listener'ı başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDreamListener();
    });
    
    _greetingController.forward();
    _cardController.forward();
  }

  // ✅ YENİ METOD: Real-time listener'ı başlat
  void _initializeDreamListener() {
    try {
      final dreamProvider = Provider.of<DreamProvider>(context, listen: false);
      
      // Real-time listener'ı başlat
      dreamProvider.startListeningToDreams();
      
      debugPrint('✅ HomeScreen: Real-time dream listener initialized');
    } catch (e) {
      debugPrint('❌ HomeScreen: Error initializing listener: $e');
    }
  }

  @override
  void dispose() {
    _greetingController.dispose();
    _cardController.dispose();
    super.dispose();
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

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Color _getMoodColor(String mood) {
    final moodLower = mood.toLowerCase();
    if (moodLower.contains('mutlu') || moodLower.contains('huzurlu')) {
      return Colors.green;
    } else if (moodLower.contains('üzgün') || moodLower.contains('korkmuş')) {
      return Colors.orange;
    } else if (moodLower.contains('kaygılı') || moodLower.contains('endişeli')) {
      return Colors.red;
    }
    return Colors.blue;
  }

  IconData _getMoodIcon(String mood) {
    final moodLower = mood.toLowerCase();
    if (moodLower.contains('mutlu') || moodLower.contains('huzurlu')) {
      return Icons.sentiment_very_satisfied;
    } else if (moodLower.contains('üzgün')) {
      return Icons.sentiment_dissatisfied;
    } else if (moodLower.contains('korkmuş')) {
      return Icons.sentiment_very_dissatisfied;
    } else if (moodLower.contains('kaygılı') || moodLower.contains('endişeli')) {
      return Icons.sentiment_neutral;
    }
    return Icons.sentiment_satisfied;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ EKLEME: AutomaticKeepAliveClientMixin için gerekli
    
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Consumer2<AuthProviderInterface, DreamProvider>(
        builder: (context, authProvider, dreamProvider, child) {
          final user = authProvider.currentUser;
          final recentDreams = dreamProvider.dreams.take(5).toList();

          return RefreshIndicator(
            onRefresh: () async {
              // ✅ DÜZELTME: Pull-to-refresh ile real-time listener'ı yenile
              await dreamProvider.refreshDreams();
            },
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildModernHeader(context, user),
                ),
                
                // Recent Dreams Section
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                          theme.colorScheme.secondaryContainer.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.auto_stories_rounded,
                                          size: 20,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                  Text(
                                    'Son Rüyalarım',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dreamProvider.dreams.length} rüya kaydedildi',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Tümünü Gör Butonu
                            if (dreamProvider.dreams.isNotEmpty)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    // Navigate to DreamHistoryScreen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const DreamHistoryScreen(),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary.withValues(alpha: 0.1),
                                          theme.colorScheme.secondary.withValues(alpha: 0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Tümünü Gör',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (dreamProvider.dreams.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  theme.colorScheme.outline.withValues(alpha: 0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().slideY(
                    delay: 300.ms,
                    duration: 700.ms,
                    begin: 0.3,
                    curve: Curves.easeOutCubic,
                  ).fadeIn(
                    delay: 200.ms,
                    duration: 600.ms,
                  ),
                ),
                
                // Dreams List
                if (dreamProvider.isLoading && dreamProvider.dreams.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withValues(alpha: 0.1),
                                  theme.colorScheme.secondary.withValues(alpha: 0.05),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ).animate(
                            onPlay: (controller) => controller.repeat(),
                          ).rotate(
                            duration: 2000.ms,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Rüyalarınız yükleniyor...',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ).animate().fadeIn(
                            delay: 500.ms,
                            duration: 800.ms,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (dreamProvider.dreams.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(40),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              theme.colorScheme.surface.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withValues(alpha: 0.1),
                                    theme.colorScheme.secondary.withValues(alpha: 0.05),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.auto_stories_outlined,
                                size: 64,
                                color: theme.colorScheme.primary.withValues(alpha: 0.7),
                              ),
                            ).animate().scale(
                              duration: 1000.ms,
                              curve: Curves.elasticOut,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Rüya Yolculuğunuz Başlasın',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().slideY(
                              delay: 200.ms,
                              duration: 600.ms,
                              begin: 0.3,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Henüz hiç rüya kaydetmediniz.\nİlk rüyanızı kaydetmek için mikrofon\nbutonuna dokunun ve anlatmaya başlayın.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ).animate().slideY(
                              delay: 300.ms,
                              duration: 600.ms,
                              begin: 0.3,
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.mic_rounded,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mikrofona dokunarak başlayın',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().slideY(
                              delay: 400.ms,
                              duration: 600.ms,
                              begin: 0.3,
                            ).shimmer(
                              delay: 1000.ms,
                              duration: 2000.ms,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 400),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _buildDreamCard(
                                  recentDreams[index],
                                  context,
                                  theme,
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: recentDreams.length > 5 
                            ? 5 
                            : recentDreams.length,
                      ),
                    ),
                  ),
                
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
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
            theme.colorScheme.primary.withValues(alpha: 0.05),
            theme.colorScheme.secondary.withValues(alpha: 0.02),
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
                        color: theme.colorScheme.onSurface,
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
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
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
              Text(
                _getGreetingIcon(),
                style: const TextStyle(fontSize: 48),
              ).animate().scale(
                delay: 300.ms,
                duration: 800.ms,
                begin: const Offset(0.5, 0.5),
                curve: Curves.elasticOut,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDateText(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Rüyalarınızı takip edin',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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

  Widget _buildDreamCard(Dream dream, BuildContext context, ThemeData theme) {
    final moodColor = _getMoodColor(dream.mood);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.02),
            blurRadius: 32,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DreamDetailWidget(dream: dream),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Mood Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            moodColor.withValues(alpha: 0.15),
                            moodColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: moodColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getMoodIcon(dream.mood),
                        color: moodColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dream.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(dream.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Status Chip
                    _buildModernStatusChip(dream, theme),
                  ],
                ),
                
                // Mood Badge
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: moodColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child:                   Text(
                    _capitalizeFirst(dream.mood),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: moodColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // Analysis Preview
                if (dream.isCompleted && dream.analysis != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.psychology_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Analiz',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                          Text(
                            dream.analysis!.length > 120
                                ? '${dream.analysis!.substring(0, 120)}...'
                                : dream.analysis!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
                
                // Tap Indicator
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
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

  Widget _buildModernStatusChip(Dream dream, ThemeData theme) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    List<Color> gradientColors;

    switch (dream.status) {
      case DreamStatus.completed:
        statusColor = Colors.green.shade600;
        statusText = 'Tamamlandı';
        statusIcon = Icons.check_circle_rounded;
        gradientColors = [Colors.green.shade100, Colors.green.shade50];
        break;
      case DreamStatus.processing:
        statusColor = Colors.amber.shade600;
        statusText = 'İşleniyor';
        statusIcon = Icons.hourglass_top_rounded;
        gradientColors = [Colors.amber.shade100, Colors.orange.shade50];
        break;
      case DreamStatus.failed:
        statusColor = Colors.red.shade600;
        statusText = 'Başarısız';
        statusIcon = Icons.error_rounded;
        gradientColors = [Colors.red.shade100, Colors.pink.shade50];
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 6),
            Text(
              statusText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }


  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}