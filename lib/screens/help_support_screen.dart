// lib/screens/help_support_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/dreamy_background.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedFaqIndex;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  final List<FaqItem> _faqs = [
    FaqItem(
      question: 'Rüya analizi ne kadar sürer?',
      answer:
          'Rüya analizleriniz genellikle 1-3 dakika içinde tamamlanır. Yapay zeka destekli sistemimiz, rüyanızı detaylı bir şekilde analiz eder ve size özel yorumlar sunar.',
    ),
    FaqItem(
      question: 'Premium üyelik neler sağlar?',
      answer:
          'Premium üyelikle sınırsız rüya analizi, ruh sağlığı değerlendirmesi, reklamsız deneyim ve gelişmiş analiz özelliklerine erişebilirsiniz.',
    ),
    FaqItem(
      question: 'Rüyalarım güvende mi?',
      answer:
          'Evet, rüyalarınız şifrelenmiş bir şekilde saklanır ve sadece sizin erişiminize açıktır. Verileriniz KVKK uyumlu olarak korunmaktadır.',
    ),
    FaqItem(
      question: 'Sesli rüya kaydı nasıl çalışır?',
      answer:
          'Mikrofon izni vererek rüyanızı anlatabilirsiniz. Ses kaydınız otomatik olarak metne dönüştürülür ve ardından analiz edilir.',
    ),
    FaqItem(
      question: 'Aboneliğimi nasıl iptal edebilirim?',
      answer:
          'Profil > Abonelik Yönetimi bölümünden aboneliğinizi istediğiniz zaman iptal edebilirsiniz. İptal sonrası dönem sonuna kadar premium özelliklerden faydalanmaya devam edersiniz.',
    ),
    FaqItem(
      question: 'Rüya geçmişimi silebilir miyim?',
      answer:
          'Evet, rüya detay sayfasından herhangi bir rüyayı silebilirsiniz. Silinen rüyalar geri getirilemez.',
    ),
    FaqItem(
      question: 'Bildirimler nasıl çalışır?',
      answer:
          'Rüya analizi tamamlandığında bildirim alırsınız. Ayarlar > Bildirimler bölümünden bildirimleri açıp kapatabilirsiniz.',
    ),
    FaqItem(
      question: 'Birden fazla hesap kullanabilir miyim?',
      answer:
          'Her telefon numarası veya email adresi ile tek bir hesap oluşturabilirsiniz. Hesap değiştirmek için mevcut hesaptan çıkış yapmanız gerekir.',
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Yardım & Destek',
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
            // Sık Sorulan Sorular
            _buildSectionTitle(theme, 'Sık Sorulan Sorular', Icons.help_outline),
            const SizedBox(height: 16),
            _buildFaqList(theme),

            const SizedBox(height: 32),

            // İletişim Bilgileri
            _buildSectionTitle(theme, 'Bize Ulaşın', Icons.contact_support),
            const SizedBox(height: 16),
            _buildContactInfo(theme),

            const SizedBox(height: 32),

            // İletişim Formu
            _buildSectionTitle(theme, 'Mesaj Gönder', Icons.email_outlined),
            const SizedBox(height: 16),
            _buildContactForm(theme),

            const SizedBox(height: 32),

            // Sosyal Medya
            _buildSectionTitle(theme, 'Sosyal Medya', Icons.public),
            const SizedBox(height: 16),
            _buildSocialMedia(theme),
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

  Widget _buildFaqList(ThemeData theme) {
    return Column(
      children: List.generate(
        _faqs.length,
        (index) => _buildFaqItem(theme, index),
      ),
    );
  }

  Widget _buildFaqItem(ThemeData theme, int index) {
    final faq = _faqs[index];
    final isExpanded = _expandedFaqIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : Colors.white.withOpacity(0.1),
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
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _expandedFaqIndex = isExpanded ? null : index;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      faq.question,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    faq.answer,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: -0.2, end: 0),
        ],
      ),
    )
      .animate()
      .fadeIn(delay: (index * 50).ms, duration: 400.ms)
      .slideX(begin: 0.1, end: 0);
  }

  Widget _buildContactInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
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
      child: Column(
        children: [
          _buildContactInfoRow(
            theme,
            Icons.email_outlined,
            'E-posta',
            'support@ruyaapp.com',
            () => _launchEmail('support@ruyaapp.com'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildContactInfoRow(
            theme,
            Icons.access_time,
            'Çalışma Saatleri',
            'Hafta içi 09:00 - 18:00',
            null,
          ),
        ],
      ),
    )
      .animate()
      .fadeIn(delay: 100.ms, duration: 400.ms)
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildContactInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.open_in_new,
                size: 18,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactForm(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Size nasıl yardımcı olabiliriz?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // İsim
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'İsim',
                hintText: 'Adınızı girin',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'İsim gerekli';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // E-posta
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'E-posta',
                hintText: 'ornek@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'E-posta gerekli';
                }
                if (!value.contains('@')) {
                  return 'Geçerli bir e-posta girin';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Mesaj
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Mesajınız',
                hintText: 'Mesajınızı buraya yazın...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.message_outlined),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Mesaj gerekli';
                }
                if (value.trim().length < 10) {
                  return 'Mesaj en az 10 karakter olmalı';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Gönder Butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.send_rounded),
                label: const Text(
                  'Gönder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    )
      .animate()
      .fadeIn(delay: 150.ms, duration: 400.ms)
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildSocialMedia(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            theme,
            'Instagram',
            Icons.camera_alt,
            Colors.pink,
            () => _launchURL('https://instagram.com/ruyaapp'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            theme,
            'Twitter',
            Icons.alternate_email,
            Colors.blue,
            () => _launchURL('https://twitter.com/ruyaapp'),
          ),
        ),
      ],
    )
      .animate()
      .fadeIn(delay: 200.ms, duration: 400.ms)
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildSocialButton(
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
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
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();

      // TODO: Formu backend'e gönder
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('Mesaj Gönderildi'),
            ],
          ),
          content: const Text(
            'Mesajınız başarıyla gönderildi. En kısa sürede size dönüş yapacağız.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _nameController.clear();
                _emailController.clear();
                _messageController.clear();
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Rüya App Destek',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('E-posta uygulaması açılamadı: $email'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı açılamadı: $url'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class FaqItem {
  final String question;
  final String answer;

  FaqItem({
    required this.question,
    required this.answer,
  });
}
