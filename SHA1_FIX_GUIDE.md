# 🔐 SHA-1 Fingerprint Düzeltme Kılavuzu

## ❌ Mevcut Hata:
```
E/FirebaseAuth: Invalid app info in play_integrity_token
app-not-authorized - This app is not authorized to use Firebase Authentication
```

## ✅ ÇÖZÜM ADIMLARI:

### 1. Firebase Console'a Git
🔗 https://console.firebase.google.com/project/dreamy-app-2025

### 2. Project Settings'e Git
1. Sol üstteki **⚙️ Ayarlar** (Settings) ikonuna tıklayın
2. **Project settings** seçin

### 3. Android App Ayarlarını Bul
1. **General** sekmesinde aşağı kaydırın
2. **Your apps** bölümünde `com.dreamy.app` uygulamanızı bulun
3. Android simgesine tıklayın

### 4. SHA Fingerprint'leri Ekle
1. **SHA certificate fingerprints** bölümüne gidin
2. **Add fingerprint** butonuna tıklayın

#### Eklenecek SHA-1 (Debug):
```
6F:A5:AE:54:A8:2B:C4:8A:32:2A:73:35:BF:F9:8B:B0:06:56:0F:39
```

#### Eklenecek SHA-256 (Debug):
```
65:C5:F4:BF:07:95:64:FE:77:B4:8B:16:15:D7:98:21:F1:16:C0:1A:75:47:84:ED:AA:DE:1B:A2:4A:E1:23:2A
```

3. Her iki fingerprint'i de ekleyin
4. **Save** butonuna tıklayın

### 5. App Bilgilerini Kontrol Et
**Package name:** `com.dreamy.app` ✅

### 6. google-services.json Güncelle
1. Firebase Console'da **google-services.json** indir
2. `android/app/google-services.json` dosyasını yeni olanla değiştir

### 7. Temizlik ve Yeniden Başlatma
```bash
flutter clean
flutter pub get
```

### 8. Test Et
```bash
flutter run
```

## 🔍 KONTROL LİSTESİ:

### Firebase Console'da:
- [ ] Package name: `com.dreamy.app` ✅
- [ ] SHA-1 fingerprint eklendi ✅
- [ ] SHA-256 fingerprint eklendi ✅
- [ ] google-services.json güncel ✅

### Authentication Ayarları:
- [ ] Phone Authentication: **Enabled** ✅
- [ ] Google Sign-In: **Enabled** ✅
- [ ] Turkey (+90): **Allowed** ✅

## 🧪 TEST SENARYOSU:

### 1. Google Sign-In Test:
```
1. Uygulamayı aç
2. "Google ile Giriş Yap" tıkla
3. ✅ Başarılı giriş bekleniyor
```

### 2. Phone Auth Test (Test Number):
```
1. Phone Auth ekranına git
2. +90 555 123 4567 gir
3. Code: 123456
4. ✅ Başarılı giriş bekleniyor
```

### 3. Phone Auth Test (Gerçek Number):
```
1. Gerçek Türk numaranı gir
2. ✅ SMS gelmelidir
3. Kodu gir
4. ✅ Başarılı giriş bekleniyor
```

## ⚠️ NOTLAR:

1. **Firebase değişiklikleri 5-10 dakika sürebilir**
2. **Debug ve Release farklı SHA'lar kullanır**
3. **Play Store'a çıkarken production SHA-1 gerekir**
4. **Test numaraları hemen çalışır**

## 🚨 HALA ÇALIŞMIYORSA:

1. **10 dakika bekleyin** (Firebase yayılması)
2. **Uygulamayı tamamen kapatın** ve tekrar açın
3. **Google Services cache'i temizleyin**:
   ```bash
   flutter clean
   cd android
   ./gradlew clean
   cd ..
   flutter run
   ```
4. **Farklı cihazda test edin**

## 📱 PRODUCTION HAZIRLIĞI:

Production'a çıkarken:
1. **Production keystore** oluşturun
2. **Production SHA-1** ekleyin
3. **Play Console** SHA-1'ini ekleyin
4. **App Signing** etkinleştirin

## ✅ SONUÇ:
Bu adımları takip ettikten sonra:
- Google Sign-In çalışacak ✅
- Phone Authentication çalışacak ✅
- Test numaraları çalışacak ✅
- Gerçek SMS gelecek ✅
