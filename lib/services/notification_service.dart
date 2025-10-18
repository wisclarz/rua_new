import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Firebase Cloud Messaging Service
///
/// Bu servis:
/// - FCM token'ı alır ve Firestore'a kaydeder
/// - Gelen bildirimleri yönetir
/// - Token refresh'lerini handle eder
/// - Bildirim tıklanma olaylarını yönetir ve navigation sağlar
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _currentToken;
  bool _messageHandled = false; // ⚡ Flag to prevent double handling

  // Callback for handling notification taps (set from main app)
  Function(String dreamId)? onNotificationTapped;

  /// FCM servisini başlat
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('📱 Notification service already initialized');
      return;
    }

    try {
      debugPrint('📱 Initializing notification service...');

      // Bildirim izni iste
      final settings = await _requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('⚠️ Notification permission denied');
        return;
      }

      // FCM token al
      await _initializeFCMToken();

      // Token refresh listener
      _setupTokenRefreshListener();

      // Foreground message handler
      _setupForegroundMessageHandler();

      // Background message handler (main.dart'ta tanımlanacak)

      // ⚡ REMOVED: _setupNotificationTapHandler
      // onMessageOpenedApp double handling'e sebep oluyor
      // Bunun yerine sadece getInitialMessage + pending system kullanıyoruz

      // Local notifications initialize
      await _initializeLocalNotifications();

      _initialized = true;
      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('❌ Notification service initialization error: $e');
    }
  }

  /// Bildirim izni iste
  Future<NotificationSettings> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('📱 Notification permission: ${settings.authorizationStatus}');
    return settings;
  }

  /// FCM token'ı al ve kaydet
  Future<void> _initializeFCMToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        _currentToken = token;
        debugPrint('📱 FCM Token: ${token.substring(0, 20)}...');

        // Token'ı Firestore'a kaydet
        await _saveFCMTokenToFirestore(token);
      } else {
        debugPrint('⚠️ FCM token is null');
      }
    } catch (e) {
      debugPrint('❌ FCM token error: $e');
    }
  }

  /// Token refresh listener
  void _setupTokenRefreshListener() {
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed');
      _currentToken = newToken;
      _saveFCMTokenToFirestore(newToken);
    });
  }

  /// Foreground message handler
  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground message received');
      debugPrint('📩 Title: ${message.notification?.title}');
      debugPrint('📩 Body: ${message.notification?.body}');
      debugPrint('📩 Data: ${message.data}');

      // Uygulama açıkken bildirim GÖSTERME (n8n zaten gönderiyor)
      // Sadece data'yı log'la
      debugPrint('✅ Foreground notification received - n8n handles notification display');
    });
  }

  /// ⚡ REMOVED: Background/Terminated notification tap handler
  /// onMessageOpenedApp double handling'e sebep oluyordu
  /// Artık sadece getInitialMessage + pending message system kullanıyoruz
  /*
  void _setupNotificationTapHandler() {
    // Uygulama kapalıyken bildirime tıklanınca çalışır
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 Notification tapped (background state)');
      debugPrint('📱 Message data: ${message.data}');
      debugPrint('📱 Message notification: ${message.notification?.title}');
      _handleNotificationTap(message);
    });
  }
  */

  // Pending initial message (uygulama kapalıyken tıklanmışsa)
  RemoteMessage? _pendingInitialMessage;

  /// Store initial message (called from main.dart BEFORE app runs)
  /// This ensures message is captured before any UI renders
  Future<void> storeInitialMessage(RemoteMessage message) async {
    debugPrint('📱 [SERVICE] Storing initial message');
    debugPrint('📱 [SERVICE] Message data: ${message.data}');
    debugPrint('📱 [SERVICE] Message notification: ${message.notification?.title}');

    _pendingInitialMessage = message;
    debugPrint('✅ [SERVICE] Initial message stored, will handle when navigation ready');
  }

  /// Check for initial message (uygulama kapalıyken tıklanmış bildirim)
  /// NOT: Bu method artık kullanılmıyor - main.dart'ta zaten check ediliyor
  @Deprecated('Use storeInitialMessage from main.dart instead')
  Future<void> checkInitialMessage() async {
    // Bu method artık kullanılmıyor çünkü main.dart'ta daha erken çağrılıyor
    debugPrint('⚠️ [SERVICE] checkInitialMessage called but deprecated - message should be stored from main.dart');
  }

  /// Handle pending initial message (navigation ready olduğunda çağrılacak)
  Future<void> handlePendingInitialMessage() async {
    // ⚡ Flag check - sadece bir kere handle et
    if (_messageHandled) {
      debugPrint('📱 Message already handled, skipping');
      return;
    }

    if (_pendingInitialMessage != null) {
      debugPrint('📱 Handling pending initial message...');
      final message = _pendingInitialMessage!;
      _pendingInitialMessage = null;
      _messageHandled = true; // ⚡ Flag'i set et

      // ⚡ Direkt handle et - _handleNotificationTap kendi retry logic'i var
      _handleNotificationTap(message);
    } else {
      debugPrint('📱 No pending initial message to handle');
    }
  }

  /// Handle notification tap (navigate to dream detail)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped - Data: ${message.data}');

    final data = message.data;

    if (data.containsKey('dreamId')) {
      final dreamId = data['dreamId'] as String;
      debugPrint('✅ Found dreamId: $dreamId');

      // Callback'i çağır (main app'te set edilecek)
      if (onNotificationTapped != null) {
        debugPrint('✅ Calling onNotificationTapped callback');
        onNotificationTapped!(dreamId);
      } else {
        debugPrint('❌ onNotificationTapped callback not set');
      }
    } else {
      debugPrint('❌ dreamId not found in notification data');
    }
  }

  /// Show local notification (uygulama açıkken)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'dream_analysis',
        'Rüya Analizi',
        channelDescription: 'Rüya analizi tamamlandığında bildirim',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: message.data['dreamId'],
      );
    } catch (e) {
      debugPrint('❌ Show local notification error: $e');
    }
  }

  /// FCM token'ı Firestore'a kaydet
  Future<void> _saveFCMTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in, cannot save FCM token');
        return;
      }

      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      }, SetOptions(merge: true));

      debugPrint('✅ FCM token saved to Firestore for user: ${user.uid}');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token to Firestore: $e');
    }
  }

  /// FCM token'ı temizle (logout veya account deletion için)
  /// Bu metod hem Firebase'den token'ı siler hem de Firestore'dan temizler
  Future<void> clearFCMToken() async {
    try {
      debugPrint('🗑️ Clearing FCM token...');

      // 1. Firebase'den token'ı sil
      await _fcm.deleteToken();
      debugPrint('✅ FCM token deleted from Firebase');

      // 2. Firestore'dan token'ı temizle
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('✅ FCM token cleared from Firestore for user: ${user.uid}');
      }

      // 3. Local token'ı temizle
      _currentToken = null;
      _initialized = false;

      debugPrint('✅ FCM token cleared successfully');
    } catch (e) {
      debugPrint('❌ Failed to clear FCM token: $e');
    }
  }


  /// Mevcut FCM token'ı al
  String? get currentToken => _currentToken;

  /// Token'ı force refresh et
  Future<String?> refreshToken() async {
    try {
      await _fcm.deleteToken();
      final newToken = await _fcm.getToken();
      if (newToken != null) {
        _currentToken = newToken;
        await _saveFCMTokenToFirestore(newToken);
      }
      return newToken;
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      return null;
    }
  }

  /// Bildirim ayarlarını kontrol et
  Future<bool> areNotificationsEnabled() async {
    final settings = await _fcm.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // ==================== LOCAL NOTIFICATIONS ====================

  /// Local notifications initialize
  Future<void> _initializeLocalNotifications() async {
    try {
      debugPrint('📱 Initializing local notifications...');

      // Android notification channel oluştur
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'dream_analysis',
        'Rüya Analizi',
        description: 'Rüya analizi tamamlandığında bildirim',
        importance: Importance.high,
        playSound: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Android ayarları
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS ayarları
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTapped,
      );

      debugPrint('✅ Local notifications initialized');
    } catch (e) {
      debugPrint('❌ Local notification initialization error: $e');
    }
  }

  /// Local notification tapped handler (uygulama açıkken gösterilen bildirimler için)
  void _onLocalNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Local notification tapped: ${response.payload}');

    if (response.payload != null && response.payload!.isNotEmpty) {
      final dreamId = response.payload!;
      debugPrint('🔔 Navigating to dream: $dreamId');

      // Callback'i çağır
      if (onNotificationTapped != null) {
        onNotificationTapped!(dreamId);
      } else {
        debugPrint('⚠️ onNotificationTapped callback not set');
      }
    }
  }

  /// Rüya analizi tamamlandı bildirimi göster
  Future<void> showDreamAnalysisCompleteNotification({
    required String dreamId,
    required String dreamTitle,
  }) async {
    try {
      debugPrint('📱 Showing dream analysis notification for: $dreamId');

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'dream_analysis',
        'Rüya Analizi',
        channelDescription: 'Rüya analizi tamamlandığında bildirim',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        dreamId.hashCode, // Unique notification ID
        'Rüya Analizi Tamamlandı! ✨',
        '$dreamTitle - Sonuçları görmek için tıklayın.',
        notificationDetails,
        payload: dreamId,
      );

      debugPrint('✅ Notification shown for dream: $dreamId');
    } catch (e) {
      debugPrint('❌ Show notification error: $e');
    }
  }
}

/// Background message handler (top-level function olmalı)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background message received');
  debugPrint('📩 Title: ${message.notification?.title}');
  debugPrint('📩 Body: ${message.notification?.body}');
  debugPrint('📩 Data: ${message.data}');

  // Background'da bildirim geldiğinde yapılacak işlemler
  // NOT: Bu fonksiyon isolate'ta çalışır, UI güncellemesi yapılamaz
}
