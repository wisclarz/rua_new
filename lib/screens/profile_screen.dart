import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/mock_auth_provider.dart';
import '../widgets/glassmorphic_container.dart';

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
    ),
    ProfileMenuItem(
      icon: Icons.notifications_outlined,
      title: 'Bildirimler',
      subtitle: 'Bildirim ayarlarını yönet',
      color: const Color(0xFF10B981),
    ),
    ProfileMenuItem(
      icon: Icons.security_outlined,
      title: 'Gizlilik & Güvenlik',
      subtitle: 'Hesap güvenliği ayarları',
      color: const Color(0xFF8B5CF6),
    ),
    ProfileMenuItem(
      icon: Icons.palette_outlined,
      title: 'Tema',
      subtitle: 'Aydınlık/Karanlık mod',
      color: const Color(0xFFF59E0B),
    ),
    ProfileMenuItem(
      icon: Icons.help_outline,
      title: 'Yardım & Destek',
      subtitle: 'SSS ve iletişim',
      color: const Color(0xFF06B6D4),
    ),
    ProfileMenuItem(
      icon: Icons.info_outline,
      title: 'Hakkında',
      subtitle: 'Uygulama bilgileri',
      color: const Color(0xFFEC4899),
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
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Profil',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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
    final authProvider = Provider.of<MockAuthProvider>(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.2),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ).animate()
              .scale(duration: const Duration(milliseconds: 600), curve: Curves.elasticOut),
            
            const SizedBox(height: 16),
            
            Text(
              authProvider.currentUser?.email?.split('@').first ?? 'Kullanıcı',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ).animate(delay: const Duration(milliseconds: 200))
              .fadeIn(duration: const Duration(milliseconds: 600))
              .slideY(begin: 0.3, duration: const Duration(milliseconds: 600)),
            
            Text(
              authProvider.currentUser?.email ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ).animate(delay: const Duration(milliseconds: 400))
              .fadeIn(duration: const Duration(milliseconds: 600))
              .slideY(begin: 0.3, duration: const Duration(milliseconds: 600)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, ProfileMenuItem item, int index) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _handleMenuTap(context, item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
      .fadeIn(duration: const Duration(milliseconds: 600))
      .slideX(begin: 0.3, duration: const Duration(milliseconds: 600));
  }

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Card(
        elevation: 2,
        color: Colors.red[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Çıkış Yap',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hesabınızdan güvenli çıkış yapın',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: const Duration(milliseconds: 600))
      .fadeIn(duration: const Duration(milliseconds: 600))
      .slideY(begin: 0.3, duration: const Duration(milliseconds: 600));
  }

  void _showModernSnackBar(BuildContext context, String message, Color color, IconData icon) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 80,
            borderRadius: 16,
            blur: 20,
            alignment: Alignment.center,
            border: 2,
            linearGradient: LinearGradient(
              colors: [
                color.withOpacity(0.9),
                color.withOpacity(0.8),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate()
            .slideY(begin: -1.0, duration: const Duration(milliseconds: 500), curve: Curves.elasticOut)
            .fadeIn(duration: const Duration(milliseconds: 300)),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void _handleMenuTap(BuildContext context, ProfileMenuItem item) {
    switch (item.title) {
      case 'Tema':
        _showThemeDialog(context);
        break;
      default:
        _showModernSnackBar(
          context,
          '${item.title} yakında gelecek! ⚡',
          Theme.of(context).colorScheme.primary,
          item.icon,
        );
    }
  }

  void _showThemeDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Tema Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Aydınlık Tema'),
              onTap: () {
                Navigator.pop(context);
                // Implement theme change
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Karanlık Tema'),
              onTap: () {
                Navigator.pop(context);
                // Implement theme change
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_system_daydream),
              title: const Text('Sistem Teması'),
              onTap: () {
                Navigator.pop(context);
                // Implement theme change
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<MockAuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Çıkış Yap'),
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

  ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
