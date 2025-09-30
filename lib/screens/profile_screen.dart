import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_interface.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<ProfileMenuItem> _menuItems = [
    ProfileMenuItem(
      icon: Icons.person_outline,
      title: 'Profil Bilgilerim',
      subtitle: 'Kişisel bilgilerimi düzenle',
      color: const Color(0xFF6366F1),
      route: '/profile-edit',
    ),
    ProfileMenuItem(
      icon: Icons.notifications_outlined,
      title: 'Bildirimler',
      subtitle: 'Bildirim ayarlarını yönet',
      color: const Color(0xFF10B981),
      route: '/notifications',
    ),
    ProfileMenuItem(
      icon: Icons.security_outlined,
      title: 'Gizlilik & Güvenlik',
      subtitle: 'Hesap güvenliği ayarları',
      color: const Color(0xFF8B5CF6),
      route: '/privacy-security',
    ),
    ProfileMenuItem(
      icon: Icons.palette_outlined,
      title: 'Tema',
      subtitle: 'Aydınlık/Karanlık mod',
      color: const Color(0xFFF59E0B),
      route: '/theme-settings',
    ),
    ProfileMenuItem(
      icon: Icons.analytics_outlined,
      title: 'İstatistikler',
      subtitle: 'Analiz sonuçlarını görüntüle',
      color: const Color(0xFF06B6D4),
      route: '/statistics',
    ),
    ProfileMenuItem(
      icon: Icons.backup_outlined,
      title: 'Yedekleme',
      subtitle: 'Verilerimi yedekle/geri yükle',
      color: const Color(0xFF84CC16),
      route: '/backup',
    ),
    ProfileMenuItem(
      icon: Icons.help_outline,
      title: 'Yardım & Destek',
      subtitle: 'SSS ve iletişim',
      color: const Color(0xFF06B6D4),
      route: '/help-support',
    ),
    ProfileMenuItem(
      icon: Icons.info_outline,
      title: 'Hakkında',
      subtitle: 'Uygulama bilgileri',
      color: const Color(0xFFEC4899),
      route: '/about',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final availableHeight = screenHeight - statusBarHeight;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: availableHeight * 0.32, // Slightly reduced height
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(context),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Added bottom padding for navigation
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < _menuItems.length) {
                    final item = _menuItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8), // Reduced spacing
                      child: _buildMenuItem(context, item, index),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildLogoutButton(context),
                    );
                  }
                },
                childCount: _menuItems.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<AuthProviderInterface>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.8),
                theme.colorScheme.secondary.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), // Optimized padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title at the top
                  Text(
                    'Profil',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 600.ms),
                  
                  const Spacer(), // Push content to bottom
                  
                  // Profile content centered
                  Center(
                    child: Column(
                      children: [
                        // Profile Image
                        GestureDetector(
                          onTap: () => _showImagePickerDialog(context),
                          child: Container(
                            width: 80, // Slightly smaller
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: user?.profileImageUrl != null
                                  ? Image.network(
                                      user!.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildDefaultAvatar(user.name),
                                    )
                                  : _buildDefaultAvatar(user?.name ?? 'User'),
                            ),
                          ),
                        ).animate().scale(delay: 200.ms, duration: 600.ms),
                        
                        const SizedBox(height: 12), // Reduced spacing
                        
                        // User Name
                        Text(
                          user?.name ?? 'Kullanıcı',
                          style: theme.textTheme.titleLarge?.copyWith( // Smaller text
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                        
                        const SizedBox(height: 2), // Reduced spacing
                        
                        // User Email
                        Text(
                          user?.email ?? '',
                          style: theme.textTheme.bodySmall?.copyWith( // Smaller text
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                        
                        const SizedBox(height: 12), // Reduced spacing
                        
                        // Stats Row
                        if (user != null) _buildStatsRow(context, user),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28, // Adjusted for smaller avatar
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, User user) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 60), // Limit height
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              'Rüyalar',
              '${user.stats?.totalDreams ?? 0}',
              Icons.bedtime_outlined,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'Analizler',
              '${user.stats?.totalAnalyses ?? 0}',
              Icons.analytics_outlined,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'Gün',
              '${user.stats?.streakDays ?? 0}',
              Icons.local_fire_department_outlined,
            ),
          ),
        ],
      ),
    ).animate().slide(
      begin: const Offset(0, 0.5),
      delay: 800.ms,
      duration: 600.ms,
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Important: prevent overflow
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 16, // Smaller icon
        ),
        const SizedBox(height: 2), // Reduced spacing
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14, // Smaller text
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10, // Smaller text
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, ProfileMenuItem item, int index) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced padding
        leading: Container(
          padding: const EdgeInsets.all(8), // Reduced padding
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            item.icon,
            color: item.color,
            size: 20, // Smaller icon
          ),
        ),
        title: Text(
          item.title,
          style: theme.textTheme.titleSmall?.copyWith( // Smaller text
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 11, // Smaller subtitle
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          size: 18, // Smaller trailing icon
        ),
        onTap: () {
          // Navigate to respective screen
          if (item.route != null) {
            Navigator.pushNamed(context, item.route!);
          }
        },
      ),
    ).animate()
        .slide(
          begin: const Offset(1, 0),
          delay: Duration(milliseconds: 100 * index),
          duration: 400.ms,
        )
        .fadeIn();
  }

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.logout,
            color: Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          'Çıkış Yap',
          style: theme.textTheme.titleSmall?.copyWith(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Hesabından güvenli çıkış yap',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        onTap: () => _showLogoutConfirmDialog(context),
      ),
    ).animate()
        .slide(
          begin: const Offset(1, 0),
          delay: Duration(milliseconds: 100 * _menuItems.length),
          duration: 400.ms,
        )
        .fadeIn();
  }

  void _showImagePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Resmi'),
        content: const Text('Profil resmi değiştirme özelliği yakında eklenecek!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<AuthProviderInterface>().signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Çıkış yapılırken hata oluştu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? route;

  ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.route,
  });
}