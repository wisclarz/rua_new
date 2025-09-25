# 🇹🇷 Firebase Phone Auth Türkiye Bölgesi Düzeltmesi

## Hata:
```
SMS unable to be sent until this region enabled by the app developer
```

Bu hata, Firebase Phone Authentication'ın Türkiye için etkinleştirilmediğini gösteriyor.

## Çözüm Adımları:

### 1. Firebase Console'a Git
https://console.firebase.google.com/project/dreamy-app-2025

### 2. Phone Authentication Bölgesel Ayarları
1. **Authentication** > **Sign-in method** tıklayın
2. **Phone** provider'ına tıklayın
3. **Advanced** veya **Regional settings** bölümünü bulun
4. **Allow countries** listesinde **Turkey (+90)** olduğunu kontrol edin
5. Eğer yoksa ekleyin

### 3. Alternatif: Test Phone Numbers Kullan
Geliştirme aşamasında test telefon numaraları kullanabilirsiniz:

1. **Authentication** > **Sign-in method** > **Phone**
2. **Phone numbers for testing** bölümüne gidin
3. Bu test numaralarını ekleyin:

```
+90 555 123 4567 → Code: 123456
+90 532 123 4567 → Code: 654321
```

### 4. Firebase Cloud Functions (Gelişmiş)
Eğer bölgesel kısıtlama devam ederse, custom SMS provider kullanabilirsiniz:

1. **Functions** bölümüne gidin
2. Custom SMS function yazın (Twilio, Netgsm vb.)

### 5. Billing Account Kontrol
1. **Project Settings** > **Usage and billing**
2. Billing account'un aktif olduğunu kontrol edin
3. Free tier'da SMS quotası sınırlıdır

## Test Etme:

### Option 1: Test Numbers ile
```dart
// Test numarası kullan
_phoneController.text = '+90 555 123 4567';
// Kod: 123456
```

### Option 2: Gerçek Numara (Billing gerekli)
```dart
// Gerçek Türk numarası
_phoneController.text = '+90 532 XXX XXXX';
```

## Firebase Console Kontrol Listesi:
- [ ] Authentication enabled
- [ ] Phone provider enabled  
- [ ] Turkey (+90) allowed countries'de
- [ ] Billing account active (gerçek SMS için)
- [ ] Test numbers configured (development için)

## Hata Devam Ederse:
1. Firebase support'a ticket açın
2. Proje ID: `dreamy-app-2025`
3. Hata kodu: `17006`
4. Talep: Turkey region SMS enablement

## Alternatif Authentication Methods:
- Google Sign-In (✅ Çalışır)
- Email/Password (✅ Çalışır)  
- Apple Sign-In (iOS için)
- Facebook Login
