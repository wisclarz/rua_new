# Firebase Kurulum Komutları

Firebase projenizi oluşturduktan sonra bu komutları sırayla çalıştırın:

## 1. Firebase Login
```bash
firebase login
```

## 2. FlutterFire Configure
```bash
flutterfire configure
```
- Projenizi seçin: `rua-dream-app`
- Platform'ları seçin: Android, iOS, Web
- Paket adını onaylayın

## 3. Android Konfigürasyonu
Android klasöründe `android/app/build.gradle` dosyasına eklenecek:
```gradle
// Firebase'in otomatik eklediği satırları kontrol edin
```

## 4. iOS Konfigürasyonu  
iOS klasöründe `ios/Runner/Info.plist` dosyasını kontrol edin

## 5. Firebase Security Rules
Firestore kurallarını güncelleyin (Firebase Console):
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

## 6. Storage Security Rules
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
