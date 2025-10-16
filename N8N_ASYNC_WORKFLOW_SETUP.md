# N8N Asenkron Workflow Yapılandırması

## Problem

❌ **Eski Durum:**
- Flutter N8N'e request gönderir ve analiz bitene kadar bekler (60 saniye timeout)
- N8N workflow uzun sürer (Whisper + GPT + Firestore işlemleri)
- Timeout durumunda Flutter "başarısız" olarak işaretler
- N8N workflow ise "running" durumda kalır ve response gönderemez

## Çözüm: Asenkron Pattern

✅ **Yeni Durum:**
- Flutter N8N'e request gönderir ve HEMEN response alır (10 saniye içinde)
- N8N workflow arka planda devam eder
- Analiz bitince N8N **direkt Firestore'u günceller**
- Flutter real-time listener ile otomatik güncellenir
- Push notification gönderilir

## N8N Workflow Yapısı

### 1. Webhook Node (Başlangıç)

**Settings:**
- Method: POST
- Path: `/webhook/bf22088f-6627-4593-85b6-8dc112767901`
- **Response Mode:** "Immediately" veya "Using 'Respond to Webhook' Node"

**Expected Input:**
```json
{
  "dreamId": "dream_123456",
  "userId": "user_abc",
  "idToken": "firebase-id-token",
  "fcmToken": "fcm-device-token",
  "inputType": "text",
  "action": "analyze_dream",
  "audioUrl": "https://...", // Sadece voice için
  "dreamText": "Rüya metni...", // Sadece text için
  "previousDreams": [...],
  "previousDreamsCount": 5
}
```

### 2. Respond to Webhook Node (HEMEN Response Döndür)

**ÖNEMLI:** Bu node'u webhook'tan hemen sonra ekleyin!

**Settings:**
- Response Code: 200
- Response Body:
```json
{
  "success": true,
  "message": "Analiz başlatıldı",
  "dreamId": "{{$json[\"dreamId\"]}}",
  "status": "processing"
}
```

**Not:** Bu node çalıştıktan sonra Flutter response alır ve devam eder. Sonraki node'lar arka planda çalışır.

### 3. Workflow Devamı (Background Processing)

Artık aşağıdaki işlemler arka planda devam eder:

```
Respond to Webhook
   ↓
IF (inputType === 'voice')
   ↓
   OpenAI Whisper (Transcription)
   ↓
END IF
   ↓
Firestore Query (Previous Dreams) [opsiyonel - Flutter'dan zaten geliyor]
   ↓
OpenAI GPT (Analysis)
   ↓
Firestore Update (WRITE ANALYSIS TO FIRESTORE) ← ÖNEMLİ!
   ↓
Firestore Query (Get User FCM Token)
   ↓
HTTP Request (Send Push Notification)
   ↓
[Workflow Biter]
```

### 4. Firestore Update Node (Analysis Sonuçlarını Kaydet)

**KRITIK:** Analiz sonuçlarını direkt Firestore'a yazın!

**Settings:**
- Operation: Update Document
- Collection: `dreams`
- Document ID: `{{$json["dreamId"]}}`

**Update Data:**
```json
{
  "dreamText": "{{$json[\"transcription\"] || $json[\"dreamText\"]}}",
  "baslik": "{{$json[\"analysis\"][\"baslik\"]}}",
  "analiz": "{{$json[\"analysis\"][\"analiz\"]}}",
  "duygular": {
    "anaDuygu": "{{$json[\"analysis\"][\"duygular\"][\"anaDuygu\"]}}",
    "yogunluk": "{{$json[\"analysis\"][\"duygular\"][\"yogunluk\"]}}",
    "detay": "{{$json[\"analysis\"][\"duygular\"][\"detay\"]}}"
  },
  "semboller": "{{$json[\"analysis\"][\"semboller\"]}}",
  "ruhSagligi": "{{$json[\"analysis\"][\"ruhSagligi\"]}}",
  "mood": "{{$json[\"analysis\"][\"duygular\"][\"anaDuygu\"]}}",
  "interpretation": "{{$json[\"analysis\"][\"analiz\"]}}",
  "status": "completed",
  "updatedAt": "{{$now}}"
}
```

### 5. Error Handling

**Try-Catch Pattern Kullanın:**

```
Respond to Webhook (HEMEN response döndür)
   ↓
Try
   ↓
   [OpenAI Whisper]
   ↓
   [OpenAI GPT]
   ↓
   [Firestore Update - Success]
   ↓
   [Send FCM Notification - Success]
Catch (Hata olursa)
   ↓
   Firestore Update (Mark as Failed):
   {
     "status": "failed",
     "analysis": "Analiz sırasında hata oluştu: {{$json[\"error\"][\"message\"]}}",
     "updatedAt": "{{$now}}"
   }
   ↓
   [Send FCM Notification - Error]
```

## OpenAI Prompt Yapısı

### GPT Analysis Prompt

```
Sen bir rüya analizi uzmanısın. Kullanıcının rüyasını analiz et ve JSON formatında döndür.

Rüya Metni:
{{$json["dreamText"]}}

{{#if previousDreams.length > 0}}
Önceki Rüyalar (Context):
{{#each previousDreams}}
- {{this.title}}: {{this.dreamText}}
{{/each}}
{{/if}}

JSON formatı:
{
  "baslik": "Rüyanın kısa başlığı (max 50 karakter)",
  "analiz": "Detaylı analiz metni (min 200 karakter)",
  "duygular": {
    "anaDuygu": "Mutlu/Hüzünlü/Kaygılı/Korkulu/Şaşkın/vb",
    "yogunluk": "Düşük/Orta/Yüksek",
    "detay": "Duygu analizi detayı"
  },
  "semboller": [
    {
      "sembol": "sembol adı",
      "anlam": "sembolün anlamı"
    }
  ],
  "ruhSagligi": "Rüyanın ruh sağlığı açısından analizi"
}

Türkçe yanıt ver. Samimi ve profesyonel ol.
```

## FCM Push Notification

### FCM Request (Analysis Success)

**HTTP Request Node:**
- Method: POST
- URL: `https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send`
- Authentication: OAuth2 (Service Account)

**Body:**
```json
{
  "message": {
    "token": "{{$json[\"fcmToken\"]}}",
    "notification": {
      "title": "Rüya Analizi Tamamlandı! ✨",
      "body": "{{$json[\"analysis\"][\"baslik\"]}} - Sonuçları görmek için tıklayın."
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
        "channel_id": "dream_analysis"
      }
    }
  }
}
```

### FCM Request (Analysis Failed)

```json
{
  "message": {
    "token": "{{$json[\"fcmToken\"]}}",
    "notification": {
      "title": "Analiz Başarısız",
      "body": "Rüya analizi sırasında bir hata oluştu. Lütfen tekrar deneyin."
    },
    "data": {
      "type": "dream_analysis_failed",
      "dreamId": "{{$json[\"dreamId\"]}}",
      "userId": "{{$json[\"userId\"]}}",
      "error": "{{$json[\"error\"][\"message\"]}}"
    }
  }
}
```

## Test Etme

### 1. Workflow Test

N8N Test Mode'da test ederken:
1. "Respond to Webhook" node'u hemen response döndürmeli
2. Sonraki node'lar arka planda çalışmalı
3. Firestore'da document güncellenmiş olmalı
4. FCM notification gönderilmiş olmalı

### 2. Flutter Test

```bash
flutter run
```

1. Bir rüya kaydedin (text veya voice)
2. Console'da şunu görmelisiniz:
   ```
   🚀 Starting TEXT dream analysis for: dream_xxx
   ✅ N8N workflow triggered successfully
   ```
3. Birkaç saniye sonra Firestore listener güncellemesi:
   ```
   🔄 Received 1 dreams
   ```
4. Push notification almalısınız

### 3. Debug

**N8N Execution Log:**
- Her execution'ı kontrol edin
- "Respond to Webhook" hemen dönüyor mu?
- Firestore update başarılı mı?
- FCM request 200 OK dönüyor mu?

**Firestore Console:**
- `dreams/{dreamId}` document'ı kontrol edin
- `status` field'ı "processing" → "completed" olmalı
- `analiz`, `baslik`, `duygular` field'ları dolu olmalı

**Flutter Console:**
```dart
// N8N trigger
🚀 Starting TEXT dream analysis for: dream_123
✅ N8N workflow triggered successfully

// Firestore update geldiğinde
🔄 Received 1 dreams
💾 Dream updated: dream_123 (status: completed)
```

## Performans İyileştirmeleri

### 1. Timeout Ayarları

- Webhook Response: 5 saniye (hemen döner)
- OpenAI Whisper: 30 saniye
- OpenAI GPT: 45 saniye
- Firestore Update: 5 saniye
- FCM Request: 5 saniye

### 2. Retry Logic

Hata durumlarında retry ekleyin:
- OpenAI timeout: 3 retry, 5 saniye interval
- Firestore error: 2 retry, 2 saniye interval
- FCM error: 1 retry (token invalid olabilir)

### 3. Rate Limiting

Kullanıcı başına limit ekleyin:
- Max 10 analiz/saat
- Max 50 analiz/gün

### 4. Monitoring

N8N'de alert kurun:
- Execution failed rate > %5
- Execution duration > 2 dakika
- OpenAI error rate > %10

## Güvenlik

1. **idToken Validation:** Firebase Admin SDK ile validate edin
2. **Rate Limiting:** User ID bazlı rate limit
3. **Input Validation:** dreamText/audioUrl format kontrolü
4. **Error Messages:** Hassas bilgi içermesin

## Örnek Execution Timeline

```
00:00 - Flutter request gönderir
00:01 - N8N webhook alır
00:02 - N8N "200 OK" döner (Flutter devam eder)
00:03 - OpenAI Whisper başlar (eğer voice ise)
00:15 - Whisper tamamlanır
00:16 - OpenAI GPT başlar
00:35 - GPT tamamlanır
00:36 - Firestore update
00:37 - Flutter listener güncellemeyi alır ✅
00:38 - FCM notification gönderilir
00:39 - Kullanıcı notification alır 📱
00:40 - Workflow tamamlanır
```

## Sorun Giderme

### "Workflow running durumda kalıyor"

✅ **ÇÖZÜLDÜ:** "Respond to Webhook" node'u eklediniz mi?

### "Flutter timeout alıyor"

✅ **ÇÖZÜLDÜ:** N8N hemen response dönüyor (10 saniye timeout yeterli)

### "Analiz tamamlanıyor ama Flutter'da görünmüyor"

- Firestore update node'u çalışıyor mu?
- Field adları doğru mu? (`baslik`, `analiz`, `duygular`)
- Flutter listener aktif mi? (console'da `🔄 Received X dreams`)

### "Push notification gelmiyor"

- FCM token Firestore'da var mı? (`users/{userId}/fcmToken`)
- Service Account Key doğru mu?
- Android 13+ için notification permission verildi mi?

## Kaynaklar

- [N8N Webhook Docs](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/)
- [N8N Respond to Webhook](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.respondtowebhook/)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [FCM HTTP v1 API](https://firebase.google.com/docs/cloud-messaging/send-message)
