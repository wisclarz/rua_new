# 🔄 Firebase Yeniden Kurulum Adımları

## 1. Firebase Console'da Yeni Proje Oluşturun

[Firebase Console](https://console.firebase.google.com/) > "Add project"

### Proje Ayarları:
- **Proje Adı:** `RUA Dream App 2024`
- **Proje ID'si:** `rua-dream-app-2024` (benzersiz olmalı)
- **Google Analytics:** Etkinleştir (önerilen)
- **Analytics hesabı:** Default veya yeni oluştur

## 2. Firebase Servislerini Etkinleştirin

### 🔐 Authentication
- Sol menü > **Authentication** > **Get started**
- **Sign-in method** tab'ı > Şunları etkinleştirin:
  - ✅ **Email/Password** 
  - ✅ **Google** (Google Cloud projesi gerekebilir)

### 🗄️ Firestore Database
- Sol menü > **Firestore Database** > **Create database**
- **Start in test mode** seçin
- **Konum:** `europe-west3 (Frankfurt)` seçin
- **Done** tıklayın

### 📁 Storage (ÜCRETSİZ AYARLARI)
- Sol menü > **Storage** > **Get started**
- **Start in test mode** seçin
- **Konum:** `europe-west3 (Frankfurt)` seçin
- **Done** tıklayın

### 🔔 Cloud Messaging
- Sol menü > **Cloud Messaging** (otomatik etkin olmalı)

## 3. Güvenlik Kurallarını Ayarlayın

### Firestore Rules (Test Mode):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2024, 12, 31);
    }
  }
}
```

### Storage Rules (Test Mode):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.time < timestamp.date(2024, 12, 31);
    }
  }
}
```

## 4. Proje ID'sini Öğrenin

Firebase Console > Project Settings > General tab'ında **Project ID**'yi not edin.

## 5. Flutter Projesini Yapılandırın

Bu adımları tamamladıktan sonra:

```bash
flutterfire configure --project=YOUR_PROJECT_ID
```

komutunu çalıştırın.

---

**⚠️ ÖNEMLİ:** Test mode kuralları sadece geliştirme için uygundur. Production'da güvenlik kurallarını güçlendirin!

