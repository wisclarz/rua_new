// lib/screens/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/dreamy_background.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          'Gizlilik & Koşullar',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          tabs: const [
            Tab(text: 'Gizlilik Politikası'),
            Tab(text: 'Kullanım Koşulları'),
          ],
        ),
      ),
      body: DreamyBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPrivacyPolicy(theme),
            _buildTermsOfService(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicy(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 112,
        20,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(theme),
          const SizedBox(height: 24),
          _buildSection(
            theme,
            'Toplanan Veriler',
            '''
Rüya uygulaması olarak, size daha iyi hizmet sunabilmek için aşağıdaki verileri topluyoruz:

• Hesap Bilgileri: Telefon numarası, e-posta adresi, isim
• Rüya İçerikleri: Yazdığınız veya sesli kaydettiğiniz rüyalar
• Kullanım Verileri: Uygulama kullanım istatistikleri, tercihler
• Cihaz Bilgileri: Cihaz modeli, işletim sistemi, uygulama versiyonu

Bu veriler, güvenli ve şifrelenmiş bir şekilde Firebase sunucularında saklanmaktadır.
            ''',
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'Verilerin Kullanımı',
            '''
Topladığımız veriler şu amaçlarla kullanılır:

• Rüya analizi ve yorumlama hizmeti sunmak
• Kullanıcı deneyimini iyileştirmek
• Hesap güvenliğini sağlamak
• İstatistiksel analiz ve geliştirme çalışmaları
• Teknik destek ve müşteri hizmetleri

Verileriniz, izniniz olmadan üçüncü şahıslarla paylaşılmaz.
            ''',
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'Veri Güvenliği',
            '''
Verilerinizin güvenliği bizim için önceliklidir:

• Tüm veriler SSL/TLS şifreleme ile korunur
• Firebase güvenlik kuralları ile erişim kontrolü
• Düzenli güvenlik denetimleri ve güncellemeler
• KVKK (Kişisel Verilerin Korunması Kanunu) uyumluluğu

Hassas verileriniz (rüya içerikleri) sadece sizin erişiminize açıktır.
            ''',
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'Çerez Kullanımı',
            '''
Uygulamamız, kullanıcı deneyimini iyileştirmek için şu teknolojileri kullanır:

• Oturum yönetimi için kimlik doğrulama token'ları
• Tercih ve ayarlarınızı kaydetmek için yerel depolama
• Analitik ve performans izleme

Bu veriler sadece uygulama içinde kullanılır ve kişisel kimlik bilgisi içermez.
            ''',
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'Haklarınız',
            '''
KVKK kapsamında sahip olduğunuz haklar:

• Verilerinize erişim hakkı
• Verilerin düzeltilmesini talep etme hakkı
• Verilerin silinmesini talep etme hakkı (unutulma hakkı)
• Veri işleme faaliyetlerine itiraz etme hakkı

Bu haklarınızı kullanmak için support@ruyaapp.com adresinden bize ulaşabilirsiniz.
            ''',
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'Değişiklikler',
            '''
Bu gizlilik politikası gerektiğinde güncellenebilir. Önemli değişiklikler olduğunda:

• Uygulama içi bildirim gönderilir
• E-posta ile bilgilendirilirsiniz
• Bu sayfada güncelleme tarihi belirtilir

Son Güncelleme: 14 Ekim 2025
            ''',
          ),
        ],
      ),
    )
      .animate()
      .fadeIn(duration: 400.ms);
  }

  Widget _buildTermsOfService(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 112,
        20,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(theme),
          const SizedBox(height: 24),
          _buildSection(
            theme,
            'Hizmet Şartları',
            '''
Rüya uygulamasını kullanarak aşağıdaki koşulları kabul etmiş olursunuz:

• Bu uygulama 18 yaş ve üzeri kullanıcılar içindir
• Hesabınızın güvenliğinden siz sorumlusunuz
• Yanıltıcı veya sahte bilgi paylaşamazsınız
• Uygulamayı yasalara uygun şekilde kullanmalısınız
            ''',
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'İçerik Politikası',
            '''
Rüya içerikleriniz için uymanız gereken kurallar:

• Şiddet, nefret söylemi veya yasadışı içerik yasaktır
• Başkalarının haklarını ihlal edemezsiniz
• Reklam veya spam içerik paylaşamazsınız
• Telif hakkı korumalı içerik kullanamazsınız

Kurallara uymayan içerikler kaldırılabilir ve hesabınız askıya alınabilir.
            ''',
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'Abonelik ve Ödeme',
            '''
Premium üyelik için geçerli kurallar:

• Abonelik, belirlenen periyotta (aylık/yıllık) otomatik yenilenir
• İptal edilene kadar ödemeler devam eder
• İptal sonrası dönem sonuna kadar hizmet devam eder
• İade politikası uygulama mağazası kurallarına tabidir
• Fiyat değişiklikleri önceden bildirilir

Ödeme işlemleri Google Play Store / App Store üzerinden güvenle gerçekleştirilir.
            ''',
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'Hizmet Kesintileri',
            '''
Aşağıdaki durumlarda hizmet kesintisi yaşanabilir:

• Planlı bakım çalışmaları (önceden duyurulur)
• Teknik arızalar ve güncelleme gereksinimleri
• Güvenlik tehditleri veya yasal zorunluluklar
• Mücbir sebepler (doğal afetler, savaş, vb.)

Kesintilerden dolayı oluşabilecek zararlardan sorumlu değiliz.
            ''',
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'Sorumluluk Reddi',
            '''
Önemli: Rüya analizleri bilgilendirme amaçlıdır.

• Tıbbi, psikolojik veya profesyonel tavsiye yerine geçmez
• Yapay zeka destekli analiz sonuçları yoruma açıktır
• Rüya yorumları kesin doğruluk iddiası taşımaz
• Ciddi ruh sağlığı sorunları için uzman desteği alınmalıdır

Analiz sonuçlarına dayanarak alınan kararlardan sorumluluk kabul etmiyoruz.
            ''',
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'Hesap Sonlandırma',
            '''
Hesabınızı istediğiniz zaman silebilirsiniz:

• Ayarlar > Hesabı Sil seçeneğinden
• Silme işlemi geri alınamaz
• Tüm rüya içerikleriniz kalıcı olarak silinir
• Aboneliğinizi ayrıca iptal etmelisiniz

Kural ihlallerinde hesabınız bizim tarafımızdan sonlandırılabilir.
            ''',
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'İletişim',
            '''
Kullanım koşulları hakkında sorularınız için:

E-posta: support@ruyaapp.com
İletişim: Yardım & Destek sayfası

Son Güncelleme: 14 Ekim 2025
            ''',
          ),
        ],
      ),
    )
      .animate()
      .fadeIn(duration: 400.ms);
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Verilerinizin gizliliği ve güvenliği bizim için önceliklidir.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    )
      .animate()
      .fadeIn(delay: 100.ms, duration: 400.ms)
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.7,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
