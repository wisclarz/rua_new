// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider_interface.dart';
import '../widgets/dreamy_background.dart';
import '../utils/navigation_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _selectedTheme = ThemeMode.system;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'tr';
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProviderInterface>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Ayarlar',
          style: TextStyle(fontWeight: FontWeight.w600),
        )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideX(begin: -0.2, end: 0),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      body: DreamyBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 72,
            16,
            32,
          ),
          children: [
            // Görünüm Ayarları
            _buildSectionTitle(theme, 'Görünüm', Icons.palette),
            const SizedBox(height: 12),
            _buildThemeSelectorCard(theme),

            const SizedBox(height: 32),

            // Bildirimler
            _buildSectionTitle(theme, 'Bildirimler', Icons.notifications),
            const SizedBox(height: 12),
            _buildNotificationCard(theme),

            const SizedBox(height: 32),

            // Dil Ayarları
            _buildSectionTitle(theme, 'Dil', Icons.language),
            const SizedBox(height: 12),
            _buildLanguageCard(theme),

            const SizedBox(height: 32),

            // Hesap
            _buildSectionTitle(theme, 'Hesap', Icons.person),
            const SizedBox(height: 12),
            _buildAccountCard(theme, authProvider),

            const SizedBox(height: 32),

            // Hakkında
            _buildSectionTitle(theme, 'Hakkında', Icons.info),
            const SizedBox(height: 12),
            _buildAboutCard(theme),

            const SizedBox(height: 32),

            // Tehlikeli Alan
            _buildDangerZone(theme, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    )
      .animate()
      .fadeIn(duration: 400.ms)
      .slideX(begin: -0.1, end: 0);
  }

  Widget _buildThemeSelectorCard(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tema Seçimi',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildThemeOption(theme, 'Açık Tema', ThemeMode.light, Icons.wb_sunny),
          const SizedBox(height: 8),
          _buildThemeOption(theme, 'Koyu Tema', ThemeMode.dark, Icons.nightlight_round),
          const SizedBox(height: 8),
          _buildThemeOption(theme, 'Sistem', ThemeMode.system, Icons.phone_android),
        ],
      ),
    )
      .animate()
      .fadeIn(delay: 100.ms, duration: 400.ms)
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildThemeOption(ThemeData theme, String label, ThemeMode mode, IconData icon) {
    final isSelected = _selectedTheme == mode;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTheme = mode;
        });
        // TODO: Tema değişikliğini kaydet ve uygula
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label seçildi (Yakında aktif olacak)'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(
            _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bildirimler',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rüya analiz sonuçları ve güncellemeler',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _notificationsEnabled,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() {
                _notificationsEnabled = value;
              });
              // TODO: Bildirim ayarını kaydet
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'Bildirimler açıldı'
                        : 'Bildirimler kapatıldı',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    )
      .animate()
      .fadeIn(delay: 150.ms, duration: 400.ms)
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildLanguageCard(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dil Seçimi',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildLanguageOption(theme, 'Türkçe', 'tr', '🇹🇷'),
          const SizedBox(height: 8),
          _buildLanguageOption(theme, 'English', 'en', '🇬🇧'),
        ],
      ),
    )
      .animate()
      .fadeIn(delay: 200.ms, duration: 400.ms)
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildLanguageOption(ThemeData theme, String label, String code, String flag) {
    final isSelected = _selectedLanguage == code;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedLanguage = code;
        });
        // TODO: Dil değişikliğini kaydet ve uygula
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label seçildi (Yakında aktif olacak)'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(ThemeData theme, AuthProviderInterface authProvider) {
    final user = authProvider.currentUser;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hesap Bilgileri',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // İsim
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İsim',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      user?.name ?? user?.phoneNumber ?? 'Kullanıcı',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showEditNameDialog(theme, user?.name ?? '');
                },
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Telefon/Email
          Row(
            children: [
              Icon(
                user?.email != null ? Icons.email_outlined : Icons.phone_outlined,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.email != null ? 'E-posta' : 'Telefon',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      user?.email ?? user?.phoneNumber ?? 'Bilinmiyor',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    )
      .animate()
      .fadeIn(delay: 250.ms, duration: 400.ms)
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildAboutCard(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.nights_stay,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rüya',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Versiyon $_appVersion',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Rüya analizi uygulaması. Yapay zeka destekli rüya yorumlama ve ruh sağlığı değerlendirmesi.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    )
      .animate()
      .fadeIn(delay: 300.ms, duration: 400.ms)
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildDangerZone(ThemeData theme, AuthProviderInterface authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tehlikeli Alan',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _showDeleteAccountDialog(theme, authProvider);
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Hesabı Sil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[700],
                side: BorderSide(color: Colors.red[700]!, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    )
      .animate()
      .fadeIn(delay: 350.ms, duration: 400.ms)
      .slideY(begin: 0.1, end: 0);
  }

  void _showEditNameDialog(ThemeData theme, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İsmi Düzenle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'İsim',
            hintText: 'Adınızı girin',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              // TODO: İsim güncellemesini kaydet
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('İsim güncellendi (Yakında aktif olacak)'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(ThemeData theme, AuthProviderInterface authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
            const SizedBox(width: 12),
            const Text('Hesabı Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu işlem geri alınamaz!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Hesabınız ve tüm rüyalarınız kalıcı olarak silinecektir.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // TODO: Hesap silme işlemini gerçekleştir
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              await Future.delayed(const Duration(seconds: 2));

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hesap silme özelliği yakında aktif olacak'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[700],
            ),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );
  }
}

// GlassCard Widget (mevcut yapıyla uyumlu)
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
