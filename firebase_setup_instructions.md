# Firebase Kurulumu Tamamlandı! ✅

## Firebase Servisleri Etkinleştirme

Şimdi Firebase Console'da gerekli servisleri etkinleştirin:

### 1. Firebase Console'a Gidin
[Firebase Console](https://console.firebase.google.com/) > dreamy-2e75c projesi

### 2. Authentication'ı Etkinleştirin
- Sol menüden **Authentication** > **Get started**
- **Sign-in method** tab'ına gidin
- **Email/Password** ve **Google** sign-in metodlarını etkinleştirin

### 3. Firestore Database'i Oluşturun
- Sol menüden **Firestore Database** > **Create database**
- **Start in test mode** seçin (şimdilik)
- Konum: **europe-west3** (Frankfurt) seçin

### 4. Firebase Storage'ı Etkinleştirin
- Sol menüden **Storage** > **Get started**
- **Start in test mode** seçin

### 5. Cloud Messaging'i Kontrol Edin
- Sol menüden **Cloud Messaging** (otomatik etkin olmalı)

## Güvenlik Kuralları

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Dreams can only be accessed by their owner
    match /dreams/{dreamId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Sonraki Adım
Bu adımları tamamladıktan sonra `flutter run` komutunu çalıştırabilirsiniz!
