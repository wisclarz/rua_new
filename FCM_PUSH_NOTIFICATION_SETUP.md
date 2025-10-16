# Firebase Cloud Messaging (FCM) Push Notification Kurulumu

## Flutter Tarafı (Tamamlandı ✅)

1. ✅ Firebase Messaging dependency eklendi
2. ✅ Android manifestte FCM izinleri eklendi
3. ✅ NotificationService oluşturuldu
4. ✅ FCM token otomatik olarak Firestore'a kaydediliyor
5. ✅ N8N servisi FCM token'ı webhook'a gönderiyor

## N8N Workflow Yapılandırması

### 1. Firestore'dan FCM Token'ı Al

N8N workflow'unuzda, kullanıcının FCM token'ını almak için:

```javascript
// Firestore Query Node
// Collection: users
// Document ID: {{$json["userId"]}}

// Response'da şu alan olacak:
// fcmToken: "kullanıcının-fcm-token-değeri"
```

### 2. FCM Push Notification Gönder

Analiz tamamlandığında HTTP Request node ile FCM'e istek gönderin:

**HTTP Request Node Ayarları:**

- **Method:** POST
- **URL:** `https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send`
- **Authentication:** OAuth2
- **Headers:**
  ```json
  {
    "Content-Type": "application/json"
  }
  ```

**Body (JSON):**

```json
{
  "message": {
    "token": "{{$json[\"fcmToken\"]}}",
    "notification": {
      "title": "Rüya Analizi Tamamlandı! ✨",
      "body": "Rüyanız analiz edildi. Sonuçları görmek için tıklayın."
    },
    "data": {
      "type": "dream_analysis_complete",
      "dreamId": "{{$json[\"dreamId\"]}}",
      "userId": "{{$json[\"userId\"]}}",
      "timestamp": "{{$now}}",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    },
    "android": {
      "priority": "high",
      "notification": {
        "sound": "default",
        "channel_id": "dream_analysis",
        "icon": "ic_notification"
      }
    },
    "apns": {
      "headers": {
        "apns-priority": "10"
      },
      "payload": {
        "aps": {
          "sound": "default",
          "badge": 1
        }
      }
    }
  }
}
```

### 3. Firebase Service Account Key Oluşturma

FCM API'yi kullanmak için Service Account Key'e ihtiyacınız var:

1. Firebase Console'a gidin: https://console.firebase.google.com
2. Project Settings > Service Accounts
3. "Generate New Private Key" butonuna tıklayın
4. İndirilen JSON dosyasını güvenli bir yerde saklayın
5. N8N'de OAuth2 ayarlarında bu JSON'dan:
   - `client_email`
   - `private_key`
   - `project_id` değerlerini kullanın

### 4. N8N Workflow Örnek Akışı

```
1. Webhook (Dream Analysis Request)
   ↓
2. OpenAI (Whisper - Transcription) [eğer ses varsa]
   ↓
3. Firestore Query (Previous Dreams)
   ↓
4. OpenAI (GPT - Analysis)
   ↓
5. Firestore Update (Save Analysis)
   ↓
6. Firestore Query (Get User FCM Token)
   ↓
7. HTTP Request (Send FCM Notification) ← YENİ!
   ↓
8. Response (Success)
```

### 5. Hata Yönetimi

Notification gönderilemezse (token invalid, expired, etc.):

```javascript
// Error handler node
if (error.code === 'messaging/invalid-registration-token') {
  // Token invalid - Firestore'dan sil
  await firestore.collection('users').doc(userId).update({
    fcmToken: FieldValue.delete()
  });
}
```

## Test Etme

### 1. Manuel Test (Firebase Console)

Firebase Console > Cloud Messaging > Send test message:
- FCM Token'ınızı girin
- Test notification gönderin

### 2. N8N Workflow Test

1. Flutter uygulamasını başlatın
2. Giriş yapın (FCM token otomatik kaydedilir)
3. Bir rüya analizi başlatın
4. N8N workflow loglarını kontrol edin
5. Uygulama notification almalı

### 3. Debug

```dart
// Flutter tarafında debug için:
// lib/services/notification_service.dart

// FCM token'ı görmek için:
debugPrint('📱 FCM Token: ${NotificationService().currentToken}');

// Firestore'da kontrol:
// users/{userId}/fcmToken field'ını kontrol edin
```

## Notification Tipleri

Farklı durumlarda farklı notification'lar gönderebilirsiniz:

### Analiz Başarılı
```json
{
  "type": "dream_analysis_complete",
  "title": "Rüya Analizi Tamamlandı! ✨",
  "body": "Rüyanız başarıyla analiz edildi."
}
```

### Analiz Başarısız
```json
{
  "type": "dream_analysis_failed",
  "title": "Analiz Başarısız",
  "body": "Rüya analizi sırasında bir hata oluştu. Lütfen tekrar deneyin."
}
```

### Transkripsiyon Hazır
```json
{
  "type": "transcription_ready",
  "title": "Ses Metne Dönüştürüldü",
  "body": "Sesiniz metne dönüştürüldü. Kontrol edip onaylayabilirsiniz."
}
```

## Güvenlik Notları

1. **FCM Server Key'i asla Flutter koduna koymayın**
2. **Service Account Key'i güvenli saklayın**
3. **N8N webhook'larına authentication ekleyin**
4. **Rate limiting ekleyin (spam prevention)**
5. **User consent alın (GDPR/KVKK uyumluluğu)**

## İleri Seviye Özellikler

### Notification Scheduling
- Kullanıcı timezone'una göre bildirim gönderme
- Quiet hours (sessiz saatler) kontrolü

### Notification Grouping
- Birden fazla rüya analizi aynı anda tamamlanırsa grupla

### Rich Notifications
- Resim/thumbnail ekleme
- Action buttons (Gör, Paylaş, etc.)

### Analytics
- Notification açılma oranları
- Click-through rate tracking

## Sorun Giderme

### Token alınamıyor
- Google services JSON dosyası doğru mu?
- Internet permission var mı?
- Firebase projesinde FCM aktif mi?

### Notification gelmiyor
- Token Firestore'a kaydedildi mi?
- N8N workflow'da token doğru gönderiliyor mu?
- Service Account Key doğru mu?
- Android 13+ için notification permission verildi mi?

### Background'da çalışmıyor
- Background handler registered mi? (main.dart:74)
- App battery optimization'dan muaf mı?

## Kaynaklar

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [N8N HTTP Request Node](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.httprequest/)
