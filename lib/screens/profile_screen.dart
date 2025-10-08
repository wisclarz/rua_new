// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/dream_model.dart';
import '../providers/auth_provider_interface.dart';
import '../providers/dream_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/subscription_screen.dart';
import '../widgets/decorative_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
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
      body: Consumer3<AuthProviderInterface, DreamProvider, SubscriptionProvider>(
        builder: (context, authProvider, dreamProvider, subscriptionProvider, _) {
          final user = authProvider.currentUser;
          
          return Stack(
            children: [
              // Floating background clouds
              Positioned.fill(
                child: FloatingClouds(
                  clouds: FloatingClouds.subtleClouds(theme),
                ),
              ),
              
              // Main content
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(context, user, theme),
                  ),
                  
                  // Gradient Transition
                  const SliverToBoxAdapter(
                    child: GradientTransition(),
                  ),
              
              // Subscription Card
              SliverToBoxAdapter(
                child: _buildSubscriptionCard(subscriptionProvider, theme),
              ),
              
              // Statistics
              SliverToBoxAdapter(
                child: _buildStatistics(dreamProvider, theme),
              ),
              
              // Menu Items
              SliverToBoxAdapter(
                child: _buildMenuItems(context, authProvider, subscriptionProvider, theme),
              ),
              
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, ThemeData theme) {
    return DecorativeHeader(
      decorations: DecorativeHeader.starsDecorations(theme),
      minHeight: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B4EFF),
                  const Color(0xFF9C27B0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B4EFF).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
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
                    size: 50,
                    color: Colors.white,
                  ),
          )
            .animate()
            .scale(duration: 600.ms, curve: Curves.elasticOut)
            .shimmer(delay: 600.ms, duration: 1500.ms),
          
          const SizedBox(height: 16),
          
          // Name
          Text(
            user?.name ?? user?.phoneNumber ?? 'Kullanıcı',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: 4),
          
          // Email or Phone
          Text(
            user?.email ?? user?.phoneNumber ?? 'Kullanıcı',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          )
            .animate()
            .fadeIn(delay: 300.ms, duration: 400.ms)
            .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(SubscriptionProvider provider, ThemeData theme) {
    final isPro = provider.isPro;
    final currentPlan = provider.currentPlan;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPro
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B4EFF),
                  const Color(0xFF9C27B0),
                ],
              )
            : null,
        color: isPro ? null : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isPro
            ? [
                BoxShadow(
                  color: const Color(0xFF6B4EFF).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPro ? Icons.star_rounded : Icons.info_outline_rounded,
                color: isPro ? Colors.white : theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Abonelik Planı',
                      style: TextStyle(
                        color: isPro 
                            ? Colors.white.withValues(alpha: 0.8)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // Baş harfi büyük yap
                      currentPlan.name.substring(0, 1).toUpperCase() + currentPlan.name.substring(1),
                      style: TextStyle(
                        color: isPro ? Colors.white : theme.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPro)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
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
          
          if (!isPro) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.workspace_premium, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Premium\'a Geç',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          if (isPro && provider.currentSubscription?.endDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  'Bitiş: ${_formatDate(provider.currentSubscription!.endDate!)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatistics(DreamProvider dreamProvider, ThemeData theme) {
    final totalDreams = dreamProvider.dreams.length;
    final completedDreams = dreamProvider.dreams
        .where((d) => d.status == DreamStatus.completed)
        .length;
    final processingDreams = dreamProvider.dreams
        .where((d) => d.status == DreamStatus.processing)
        .length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              theme: theme,
              title: 'Toplam Rüya',
              value: totalDreams.toString(),
              icon: Icons.nights_stay,
              color: const Color(0xFF6B4EFF),
              delay: 400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              theme: theme,
              title: 'Tamamlanan',
              value: completedDreams.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
              delay: 500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              theme: theme,
              title: 'İşleniyor',
              value: processingDreams.toString(),
              icon: Icons.hourglass_empty,
              color: Colors.orange,
              delay: 600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    int delay = 0,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
      .animate()
      .fadeIn(delay: delay.ms, duration: 600.ms)
      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic)
      .scale(
        delay: delay.ms,
        duration: 600.ms,
        begin: const Offset(0.8, 0.8),
        end: const Offset(1.0, 1.0),
        curve: Curves.easeOutCubic,
      );
  }

  Widget _buildMenuItems(
    BuildContext context,
    AuthProviderInterface authProvider,
    SubscriptionProvider subscriptionProvider,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // Subscription Management (if Pro)
          if (subscriptionProvider.isPro)
            _buildMenuItem(
              theme: theme,
              icon: Icons.card_membership,
              title: 'Abonelik Yönetimi',
              subtitle: 'Planını yönet ve değiştir',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
            ),
          
          // Settings
          _buildMenuItem(
            theme: theme,
            icon: Icons.settings,
            title: 'Ayarlar',
            subtitle: 'Uygulama ayarlarını düzenle',
            onTap: () {
              // TODO: Navigate to settings
            },
          ),
          
          // Help & Support
          _buildMenuItem(
            theme: theme,
            icon: Icons.help_outline,
            title: 'Yardım & Destek',
            subtitle: 'SSS ve iletişim',
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          
          // Privacy Policy
          _buildMenuItem(
            theme: theme,
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik Politikası',
            subtitle: 'Verilerinizin korunması',
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
          
          const SizedBox(height: 20),
          
          // Logout
          _buildMenuItem(
            theme: theme,
            icon: Icons.logout,
            title: 'Çıkış Yap',
            subtitle: 'Hesaptan çıkış yap',
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await authProvider.signOut();
              }
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDestructive 
                ? Colors.red.withValues(alpha: 0.1)
                : theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : theme.colorScheme.primary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDestructive 
                ? Colors.red 
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}