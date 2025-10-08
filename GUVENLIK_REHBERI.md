# 🔒 GÜVENLİK REHBERİ - OpenAI API Key

## ⚠️ ÖNEMLİ UYARI!

API anahtarınız şu anda `lib/config/openai_config.dart` dosyasında açıkça yazılı durumda. Bu dosya **.gitignore**'a eklenmiştir, ancak **dikkatli olmanız gerekiyor!**

## 🚨 Yapmanız Gerekenler

### 1. Git'e Commit YAPMAYIN!

```bash
# Bu dosyayı asla commit etmeyin
lib/config/openai_config.dart
```

Dosya zaten `.gitignore`'a eklendi ama kontrol edin:

```bash
git status
```

Eğer `openai_config.dart` görünüyorsa:

```bash
# Eğer staging area'da ise çıkarın
git reset HEAD lib/config/openai_config.dart

# Eğer daha önce commit edildiyse, git history'den kaldırın
git rm --cached lib/config/openai_config.dart
```

### 2. Eğer GitHub'a Push Etmiş İseniz!

⚠️ **DERHAL** API anahtarınızı iptal edin ve yeni bir tane alın!

1. [OpenAI Platform](https://platform.openai.com/api-keys) → API Keys
2. Eski anahtarı **REVOKE** edin
3. Yeni bir anahtar oluşturun
4. `lib/config/openai_config.dart` dosyasını yeni anahtar ile güncelleyin

### 3. Git History'de Varsa

Eğer daha önce commit edip push ettiyseniz:

```bash
# UYARI: Bu işlem tehlikelidir, yedek alın!
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch lib/config/openai_config.dart' \
  --prune-empty --tag-name-filter cat -- --all

# Force push (dikkatli olun!)
git push origin --force --all
```

**DAHA SONRA:**
- OpenAI'da eski anahtarı iptal edin
- Yeni anahtar oluşturun

## 📋 Güvenlik Kontrol Listesi

- [x] `.gitignore` dosyasına `lib/config/openai_config.dart` eklendi
- [ ] Git status'ta openai_config.dart görünmüyor
- [ ] GitHub/GitLab'da openai_config.dart yok
- [ ] API anahtarı paylaşılmadı
- [ ] API kullanım limitleri ayarlandı (OpenAI Dashboard)

## 🛡️ Production İçin Öneriler

### Seçenek 1: Environment Variables (Önerilen)

1. API anahtarını environment variable olarak geçin:

```dart
// lib/config/openai_config.dart
class OpenAIConfig {
  static String get apiKey {
    const key = String.fromEnvironment('OPENAI_API_KEY');
    if (key.isEmpty) {
      throw Exception('OPENAI_API_KEY environment variable not set');
    }
    return key;
  }
}
```

2. Çalıştırırken:

```bash
flutter run --dart-define=OPENAI_API_KEY=your-key-here
```

3. Build için:

```bash
flutter build apk --dart-define=OPENAI_API_KEY=your-key-here
```

### Seçenek 2: Backend Proxy (En Güvenli)

API anahtarını hiç mobil uygulamada tutmayın!

1. Kendi backend sunucunuzu oluşturun
2. API anahtarını sunucuda saklayın
3. Mobil uygulama → Backend → OpenAI şeklinde istek yapın

```dart
// Backend'e istek
final response = await http.post(
  'https://your-backend.com/api/transcribe',
  body: audioFile,
);
```

## 💰 Maliyet Kontrolü

OpenAI Dashboard'da kullanım limitleri ayarlayın:

1. [OpenAI Dashboard](https://platform.openai.com/usage) → Settings → Limits
2. Aylık harcama limiti belirleyin (örn: $10)
3. Email bildirimleri açın

**Whisper Maliyeti:**
- $0.006 / dakika
- 100 dakika = $0.60
- 1000 dakika = $6.00

## 🔍 API Key Sızdırma Kontrolü

### GitHub'da arama yapın:

```
site:github.com "sk-proj-wx_veNHnmEOnoODh"
```

Eğer bulunursa:
1. **DERHAL** anahtarı iptal edin
2. Repository'yi private yapın veya commit'i silin
3. Yeni anahtar oluşturun

### GitGuardian kullanın:

- [GitGuardian](https://www.gitguardian.com/) otomatik olarak sızdırılmış anahtarları bulur
- Ücretsiz hesap açın
- Repository'nizi taratın

## ✅ Şu Anki Durum

### Yapılanlar:
- ✅ API anahtarı `openai_config.dart` dosyasında
- ✅ Dosya `.gitignore`'a eklendi
- ✅ Uygulama içinde kullanıma hazır

### Yapılmalı:
- ⚠️ Git history'de API anahtarı olup olmadığını kontrol edin
- ⚠️ OpenAI Dashboard'da kullanım limitleri ayarlayın
- ⚠️ Production'da environment variable kullanmayı düşünün

## 📞 Yardım

Sorun yaşıyorsanız:

1. **API Key sızdıysa:** Derhal [OpenAI Support](https://help.openai.com/) ile iletişime geçin
2. **Git history temizleme:** [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) kullanın
3. **Güvenlik taraması:** [GitGuardian](https://www.gitguardian.com/) veya [TruffleHog](https://github.com/trufflesecurity/trufflehog)

---

## 🎯 Özet

**YAPILMASI GEREKENLER:**

1. ✅ Dosya .gitignore'da → Kontrol edildi
2. ⚠️ Git'e commit edilmemiş → **Kontrol edin!**
3. ⚠️ GitHub'da yok → **Kontrol edin!**
4. ⚠️ OpenAI limitleri ayarlandı → **Ayarlayın!**

**ŞU ANDA GÜVENLİ Mİ?**

- Local geliştirmede: ✅ EVET (git'e push etmediyseniz)
- Production'da: ⚠️ Environment variable kullanın
- Paylaşılan projede: ❌ HAYIR, backend proxy kullanın

---

**Son Kontrol:**

```bash
# Bu komutu çalıştırın ve openai_config.dart çıkmadığından emin olun
git ls-files | grep openai_config
```

Eğer çıkarsa, derhal:
```bash
git rm --cached lib/config/openai_config.dart
git commit -m "Remove sensitive config file"
```

