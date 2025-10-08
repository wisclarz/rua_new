# OpenAI Transkripsiyon Özelliği - Kullanım Kılavuzu

## 🎯 Özellikler

Artık ses kayıtlarınız OpenAI Whisper API ile otomatik olarak metne dönüştürülüyor ve size önizleme olarak gösteriliyor. Kullanıcı metni kontrol edip düzenledikten sonra analize gönderilebiliyor.

## 🔧 Kurulum ve Yapılandırma

### 1. OpenAI API Key Alın

1. [OpenAI Platform](https://platform.openai.com/) hesabınıza giriş yapın
2. API Keys bölümünden yeni bir API key oluşturun
3. API key'i güvenli bir yerde saklayın

### 2. API Key'i Yapılandırın

**Seçenek 1: Environment Variable (Önerilen - Üretim için)**

```bash
flutter run --dart-define=OPENAI_API_KEY=sk-your-api-key-here
```

**Seçenek 2: Config Dosyasına Ekle (Sadece Geliştirme için)**

`lib/config/openai_config.dart` dosyasını açın ve `defaultValue` kısmına API key'inizi ekleyin:

```dart
static const String apiKey = String.fromEnvironment(
  'OPENAI_API_KEY',
  defaultValue: 'sk-your-api-key-here', // Buraya ekleyin
);
```

⚠️ **Uyarı:** Production'da asla config dosyasına API key koymayın!

### 3. Paketleri Yükleyin

```bash
flutter pub get
```

## 📱 Kullanım

### Ses Kaydı ile Kullanım

1. **Rüya Kaydet** ekranına gidin
2. **Sesli** sekmesini seçin
3. Kırmızı mikrofon butonuna basarak kaydı başlatın
4. Rüyanızı anlatın
5. Durdur butonuna basın
6. **"Kaydet ve Gönder"** butonuna tıklayın

### Transkripsiyon Süreci

1. **Yükleniyor:** Ses dosyanız Firebase Storage'a yüklenir
2. **Transkripsiyon:** OpenAI Whisper API ile ses metne çevrilir (5-15 saniye)
3. **Önizleme:** Size transkripsiyon metni gösterilir
4. **Düzenleme:** Metni istediğiniz gibi düzenleyebilirsiniz
5. **Onay:** "Onayla ve Kaydet" butonuna tıklayarak analize gönderin

## 🎨 UI/UX Özellikleri

### 1. Transkripsiyon Loading Ekranı
- Animasyonlu ikon
- İlerleme göstergesi
- Bilgilendirici mesajlar

### 2. Transkripsiyon Önizleme Ekranı
- Başarı mesajı
- Düzenlenebilir metin alanı
- Karakter sayacı
- İptal ve Onayla butonları
- Smooth animasyonlar

## 🏗️ Teknik Detaylar

### Dosya Yapısı

```
lib/
├── config/
│   └── openai_config.dart          # OpenAI yapılandırması
├── services/
│   └── openai_service.dart         # OpenAI API servisi
├── providers/
│   └── dream_provider.dart         # Güncellenmiş (OpenAI entegrasyonu)
└── screens/
    └── add_dream_screen.dart       # Güncellenmiş (Transkripsiyon UI)
```

### Akış Diyagramı

```
Ses Kaydı → Firebase Upload → OpenAI Transcription
                                      ↓
                              Önizleme Göster
                                      ↓
                         Kullanıcı Onayı/Düzenleme
                                      ↓
                              Analize Gönder
                                      ↓
                             N8N Workflow → GPT Analizi
```

### OpenAI Servis Metodları

#### `transcribeAudio()`
Yerel ses dosyasını transkribe eder.

```dart
final transcription = await openAIService.transcribeAudio(
  audioFile: File('path/to/audio.m4a'),
  language: 'tr',
  model: 'whisper-1',
);
```

#### `transcribeAudioFromUrl()`
URL'den ses dosyasını indirip transkribe eder.

```dart
final transcription = await openAIService.transcribeAudioFromUrl(
  audioUrl: 'https://firebase.storage/audio.m4a',
  language: 'tr',
);
```

### DreamProvider Güncellemeleri

#### Yeni Metodlar

1. **`uploadAudioFile()`** - Transkripsiyon callback'i ile güncellendi
   ```dart
   await dreamProvider.uploadAudioFile(
     audioFile,
     onTranscriptionReady: (transcription) {
       // Transkripsiyon hazır, kullanıcıya göster
     },
   );
   ```

2. **`createDreamWithTranscription()`** - Onaylanmış transkripsiyon ile rüya oluşturur
   ```dart
   await dreamProvider.createDreamWithTranscription(
     audioUrl: audioUrl,
     transcription: userEditedTranscription,
     title: title,
   );
   ```

## 🔒 Güvenlik ve Maliyet

### API Key Güvenliği
- ✅ Environment variable kullanın
- ✅ `.env` dosyalarını `.gitignore`'a ekleyin
- ❌ Asla API key'i git'e commit etmeyin
- ❌ Public repository'lerde API key bırakmayın

### Maliyet Optimizasyonu

**OpenAI Whisper Pricing (Ocak 2025):**
- $0.006 / dakika ses

**Örnek Maliyetler:**
- 1 dakikalık ses: $0.006
- 5 dakikalık ses: $0.030
- 100 kullanıcı x 5 dk/gün: ~$15/gün

**Optimizasyon İpuçları:**
1. Ses kalitesini optimize edin (128kbps yeterli)
2. Sessiz kısımları kırpın
3. Maksimum kayıt süresi belirleyin
4. Rate limiting uygulayın

## 🐛 Hata Ayıklama

### Transkripsiyon Çalışmıyor

**Kontrol Listesi:**
- [ ] API key doğru mu?
- [ ] Internet bağlantısı var mı?
- [ ] Ses dosyası geçerli mi? (M4A, AAC, OGG)
- [ ] OpenAI hesabında kredi var mı?
- [ ] Console'da hata mesajları var mı?

**Debug Logları:**
```dart
debugPrint('🎙️ Starting transcription...');  // Başlatma
debugPrint('✅ Transcription successful');    // Başarılı
debugPrint('❌ Transcription failed');        // Hata
```

### Yaygın Hatalar

#### 401 Unauthorized
- API key yanlış veya geçersiz
- Environment variable doğru ayarlanmamış

#### 429 Rate Limit
- Çok fazla istek gönderildi
- Birkaç saniye bekleyip tekrar deneyin

#### Timeout
- Ses dosyası çok büyük (>10 MB)
- İnternet bağlantısı yavaş

## 📊 Test Senaryoları

### 1. Normal Akış
1. ✅ Ses kaydı başlat
2. ✅ 30 saniye konuş
3. ✅ Kaydı durdur
4. ✅ Transkripsiyon yükleniyor ekranı göster
5. ✅ Transkripsiyon önizleme ekranı göster
6. ✅ Metni düzenle
7. ✅ Onayla ve kaydet
8. ✅ Analize gönder

### 2. Hata Senaryoları
1. ⚠️ API key yok → Hata mesajı göster
2. ⚠️ Internet yok → Timeout hatası
3. ⚠️ Çok kısa kayıt → Validasyon hatası

### 3. Edge Cases
1. Çok uzun ses (>10 dakika)
2. Çok kısa ses (<2 saniye)
3. Gürültülü ses
4. Sessiz kayıt

## 🚀 İleriye Dönük Geliştirmeler

### Önerilen İyileştirmeler
- [ ] Offline transkripsiyon desteği
- [ ] Çoklu dil desteği
- [ ] Konuşmacı tanıma
- [ ] Otomatik noktalama düzeltme
- [ ] Ses hızlandırma/yavaşlatma
- [ ] Transkripsiyon geçmişi
- [ ] Favorilere ekleme
- [ ] Sesli okuma (TTS)

### Alternatif Servisler
- Google Cloud Speech-to-Text
- Azure Cognitive Services
- AWS Transcribe
- AssemblyAI

## 📞 Destek

Sorun yaşıyorsanız:
1. Console loglarını kontrol edin
2. API key'i doğrulayın
3. Internet bağlantısını test edin
4. [OpenAI Status](https://status.openai.com/) sayfasını kontrol edin

## 📝 Lisans

Bu özellik MIT lisansı altında geliştirilmiştir.

---

**Geliştirici Notu:** Bu özellik OpenAI Whisper API'yi kullanır. Kullanım ücretleri OpenAI hesabınızdan tahsil edilecektir.

