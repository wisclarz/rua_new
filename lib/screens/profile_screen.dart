import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/glassmorphic_container.dart';
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
      subtitle: 'Rüya analizlerimi görüntüle',
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
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Profil',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              background: _buildProfileHeader(context),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < _menuItems.length) {
                    final item = _menuItems[index];
                    return _buildMenuItem(context, item, index);
                  } else {
                    return _buildLogoutButton(context);
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
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Profile Image
                  GestureDetector(
                    onTap: () => _showImagePickerDialog(context),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
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
                  
                  const SizedBox(height: 16),
                  
                  // User Name
                  Text(
                    user?.name ?? 'Kullanıcı',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                  
                  const SizedBox(height: 4),
                  
                  // User Email
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                  
                  const SizedBox(height: 16),
                  
                  // Stats Row
                  if (user != null) _buildStatsRow(context, user),
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
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, User user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          context,
          'Rüyalar',
          '${user.stats?.totalDreams ?? 0}',
          Icons.bedtime_outlined,
        ),
        _buildStatItem(
          context,
          'Analizler',
          '${user.stats?.totalAnalyses ?? 0}',
          Icons.analytics_outlined,
        ),
        _buildStatItem(
          context,
          'Gün',
          '${user.stats?.streakDays ?? 0}',
          Icons.local_fire_department_outlined,
        ),
      ],
    ).animate().slide(
      begin: const Offset(0, 0.5),
      delay: 800.ms,
      duration: 600.ms,
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, ProfileMenuItem item, int index) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicContainer(
        borderRadius: 16,
        opacityValue: 0.1,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: item.color,
              size: 24,
            ),
          ),
          title: Text(
            item.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            item.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          onTap: () {
            // Navigate to respective screen
            if (item.route != null) {
              Navigator.pushNamed(context, item.route!);
            }
          },
        ),
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
    
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: GlassmorphicContainer(
        borderRadius: 16,
        opacityValue: 0.1,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.logout,
              color: Colors.red,
              size: 24,
            ),
          ),
          title: Text(
            'Çıkış Yap',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Hesabından güvenli çıkış yap',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          onTap: () => _showLogoutConfirmDialog(context),
        ),
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
                await context.read<AuthProvider>().signOut();
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