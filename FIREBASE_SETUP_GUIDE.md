# 🔥 Firebase Configuration Adım Adım Rehber

## Mevcut Bilgiler:
- **Package Name**: `com.dreamy.app`
- **SHA-1 Fingerprint**: `6F:A5:AE:54:A8:2B:C4:8A:32:2A:73:35:BF:F9:8B:B0:06:56:0F:39`

## Adım 1: Firebase Console'da Proje Oluşturma

1. **Firebase Console'a Git**: https://console.firebase.google.com/
2. **"Add project" veya "Create a project"** tıklayın
3. **Proje adı girin**: `rua-dream-app` (veya istediğiniz isim)
4. **Google Analytics'i etkinleştirin** (önerilen)
5. **Create project** tıklayın

## Adım 2: Android App Ekleme

1. Firebase console'da **"Add app"** tıklayın
2. **Android** ikonu seçin
3. **Package name** girin: `com.dreamy.app`
4. **App nickname**: `RUA Dream App` (opsiyonel)
5. **SHA-1 signing certificate** girin: `6F:A5:AE:54:A8:2B:C4:8A:32:2A:73:35:BF:F9:8B:B0:06:56:0F:39`
6. **Register app** tıklayın

## Adım 3: google-services.json İndirme

1. **Download google-services.json** tıklayın
2. İndirilen dosyayı **`android/app/`** klasörüne yerleştirin
3. Mevcut placeholder dosyasının üzerine yazın

## Adım 4: Authentication Metotlarını Aktifleştirme

1. Firebase console'da **Authentication** bölümüne git
2. **Sign-in method** sekmesini seç

### Phone Authentication:
1. **Phone** provider'ı tıklayın
2. **Enable** yapın
3. **Save** tıklayın

### Google Sign-In:
1. **Google** provider'ı tıklayın  
2. **Enable** yapın
3. **Project support email** seçin
4. **Save** tıklayın

## Adım 5: Firebase Options Güncellemesi

`lib/config/firebase_options.dart` dosyasını Firebase console'dan alınan bilgilerle güncelleyin:

1. Firebase console'da **Project Settings** (⚙️) tıklayın
2. **General** sekmesinde **Your apps** bölümünde Android app'inizi bulun
3. **Firebase SDK snippet** bölümünde **Config** seçin
4. Aşağıdaki bilgileri kopyalayın:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIza...', // Firebase console'dan alın
  appId: '1:551...', // Firebase console'dan alın  
  messagingSenderId: '551503664846', // Firebase console'dan alın
  projectId: 'your-project-id', // Firebase console'dan alın
  storageBucket: 'your-project.appspot.com', // Firebase console'dan alın
);
```

## Adım 6: Firestore Database Oluşturma

1. Firebase console'da **Firestore Database** tıklayın
2. **Create database** tıklayın
3. **Start in test mode** seçin (geliştirme için)
4. **Location** seçin (Europe-west3 önerilen)
5. **Enable** tıklayın

## Adım 7: Test

Konfigürasyonu tamamladıktan sonra:

```bash
flutter clean
flutter pub get
flutter run
```

### Test Phone Number:
Firebase console'da test telefon numarası ekleyin:
- **Authentication** > **Sign-in method** > **Phone** > **Phone numbers for testing**
- Number: `+90 555 123 4567`
- Code: `123456`

## ⚠️ Önemli Notlar:

1. **google-services.json** dosyası kesinlikle **`android/app/`** klasöründe olmalı
2. **Package name** tam olarak `com.dreamy.app` olmalı
3. **SHA-1 fingerprint** doğru girilmeli
4. **Authentication providers** aktif olmalı

## 🧪 Test Sonrası:

✅ Firebase başlatma başarılı olmalı  
✅ Phone authentication çalışmalı  
✅ Google sign-in çalışmalı  
✅ Firestore'a veri yazılmalı  

Bu adımları tamamladıktan sonra uygulamanız gerçek Firebase backend ile çalışacak!
