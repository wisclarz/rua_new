// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/app_theme.dart';
import 'config/firebase_options.dart';
import 'models/dream_model.dart';
import 'providers/auth_provider_interface.dart';
import 'providers/firebase_auth_provider.dart';
import 'providers/mock_auth_provider.dart';
import 'providers/dream_provider.dart';
import 'providers/subscription_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/phone_auth_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/profile_screen.dart';
import 'utils/navigation_utils.dart';
import 'utils/fps_monitor.dart';
import 'services/cache_service.dart';
import 'services/notification_service.dart';
import 'widgets/dream_detail_widget.dart';

bool _isFirebaseInitialized = false;

/// Global navigator key for handling notifications when app is not focused
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 Background message: ${message.notification?.title}');
}

/// Handle notification tap and navigate to dream detail
/// This function is called by NotificationService when user taps a notification
void _handleNotificationTap(String dreamId) async {
  debugPrint('🔔 [HANDLER] Handling notification tap for dream: $dreamId');

  // ⚡ Navigator context'i bekle (max 5 saniye)
  int contextAttempts = 0;
  const maxContextAttempts = 50;

  while (navigatorKey.currentContext == null && contextAttempts < maxContextAttempts) {
    debugPrint('⏳ Waiting for navigator context... attempt ${contextAttempts + 1}/$maxContextAttempts');
    await Future.delayed(const Duration(milliseconds: 100));
    contextAttempts++;
  }

  final context = navigatorKey.currentContext;
  if (context == null) {
    debugPrint('❌ Navigator context not available, aborting navigation');
    return;
  }

  debugPrint('✅ Navigator context ready!');

  try {
    final dreamProvider = Provider.of<DreamProvider>(context, listen: false);

    debugPrint('📥 [HANDLER] Fetching dream from Firestore: $dreamId');

    // ⚡ Direkt Firestore'dan güncel dream'i fetch et
    // Stream beklemek yerine specific dream'i oku (daha hızlı ve güncel!)
    Dream? dream;
    try {
      dream = await dreamProvider.getDreamById(dreamId);
    } catch (e) {
      debugPrint('⚠️ [HANDLER] Failed to fetch dream from Firestore: $e');
      debugPrint('⚠️ [HANDLER] Falling back to local dreams list...');

      // Fallback: Local listeden bul (eğer Firestore fetch başarısız olursa)
      int attempts = 0;
      const maxAttempts = 50;

      while (dreamProvider.dreams.isEmpty && attempts < maxAttempts) {
        debugPrint('⏳ Waiting for dreams to load... attempt ${attempts + 1}/$maxAttempts');
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (dreamProvider.dreams.isEmpty) {
        debugPrint('❌ Dreams not loaded after timeout, aborting navigation');
        return;
      }

      dream = dreamProvider.dreams.firstWhere(
        (d) => d.id == dreamId,
        orElse: () => throw Exception('Dream not found: $dreamId'),
      );
    }

    if (dream == null) {
      debugPrint('❌ [HANDLER] Dream not found: $dreamId');
      return;
    }

    debugPrint('✅ [HANDLER] Found dream: ${dream.id}');
    debugPrint('✅ [HANDLER] Title: ${dream.baslik ?? dream.title}');
    debugPrint('✅ [HANDLER] Status: ${dream.status}');
    debugPrint('✅ [HANDLER] Has analysis: ${dream.analiz != null}');

    // ⚡ Kısa delay - UI render olsun
    await Future.delayed(const Duration(milliseconds: 200));

    // Navigate using global navigator key
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => DreamDetailWidget(dream: dream!),
        fullscreenDialog: true,
      ),
    );

    debugPrint('✅ [HANDLER] Navigated to dream detail successfully');
  } catch (e) {
    debugPrint('❌ [HANDLER] Error navigating to dream: $e');
    debugPrint('❌ [HANDLER] Stack trace: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // ⚡ PERFORMANCE: Enable high refresh rate (90Hz, 120Hz support)
  // Flutter will automatically match the device's native refresh rate
  // This ensures FPS = Screen Hz (60/90/120 FPS based on device)
  // No additional code needed - Flutter handles this automatically

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 🗄️ Initialize CacheService
  try {
    await CacheService.instance.initialize();
    debugPrint('✅ CacheService initialized successfully');

    // ⚡ PERFORMANCE: Clean expired cache on app start
    Future.microtask(() async {
      await CacheService.instance.clearExpired();
    });
  } catch (e) {
    debugPrint('⚠️ CacheService initialization error: $e');
  }

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _isFirebaseInitialized = true;
    debugPrint('✅ Firebase initialized successfully');

    // 📱 Initialize Firebase Cloud Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('✅ FCM background handler registered');
  } catch (e) {
    _isFirebaseInitialized = false;
    debugPrint('❌ Firebase initialization error: $e');
    debugPrint('📱 Using mock authentication provider');
  }

  // ⚡ Set notification tap callback BEFORE running the app
  // This ensures the callback is ready when pending notifications are handled
  NotificationService().onNotificationTapped = _handleNotificationTap;
  debugPrint('✅ Notification tap callback registered');

  // ⚡ Check for initial message (notification tap while app was terminated)
  // Do this BEFORE runApp to ensure message is stored before UI renders
  try {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📱 [MAIN] Initial message found: ${initialMessage.data}');
      debugPrint('📱 [MAIN] Notification title: ${initialMessage.notification?.title}');
      debugPrint('📱 [MAIN] Notification body: ${initialMessage.notification?.body}');

      // Store it in NotificationService for later handling
      await NotificationService().storeInitialMessage(initialMessage);
    } else {
      debugPrint('📱 [MAIN] No initial message found');
    }
  } catch (e) {
    debugPrint('⚠️ [MAIN] Error checking initial message: $e');
    debugPrint('⚠️ [MAIN] Stack trace: ${StackTrace.current}');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ⚡ Auth provider - initialized early but async
        ChangeNotifierProvider<AuthProviderInterface>(
          create: (_) => _isFirebaseInitialized
              ? FirebaseAuthProvider()
              : MockAuthProvider(),
          lazy: false,
        ),

        // ⚡ Subscription provider - initialized early and loaded immediately
        ChangeNotifierProxyProvider<AuthProviderInterface, SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
          lazy: false,
          update: (context, auth, subscriptionProvider) {
            if (subscriptionProvider == null) {
              return SubscriptionProvider();
            }

            // ⚡ Load subscription immediately when auth is ready
            // loadUserSubscription() has built-in deduplication (only loads once)
            if (auth.isAuthenticated && auth.isInitialized) {
              Future.microtask(() {
                subscriptionProvider.loadUserSubscription();
              });
            }

            return subscriptionProvider;
          },
        ),

        // ⚡ Dream provider - lazy loaded
        ChangeNotifierProxyProvider<AuthProviderInterface, DreamProvider>(
          create: (_) => DreamProvider(),
          lazy: true,
          update: (context, auth, dreamProvider) {
            if (dreamProvider == null) return DreamProvider();

            // ⚡ Use Future.microtask to avoid blocking UI
            if (auth.isAuthenticated && auth.isInitialized) {
              Future.microtask(() {
                dreamProvider.startListeningToAuthenticatedUser();
              });
            } else {
              dreamProvider.stopListeningToDreams();
            }

            return dreamProvider;
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Rüya - Dream Analysis',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        // ⚡ FPS Monitor - AÇIK (Test için gerçek zamanlı FPS gösterir)
        // Sağ üstte FPS counter göreceksiniz
        builder: (context, child) {
          return FPSMonitor(
            enabled: false, // ✅ FPS counter aktif - Performans testi için
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const AuthWrapper(),
        // ⚡ Custom fast transitions for ALL named routes (120ms instead of 300ms)
        onGenerateRoute: (settings) {
          Widget page;
          switch (settings.name) {
            case '/home':
              page = const MainNavigation();
              break;
            case '/profile':
              page = const ProfileScreen();
              break;
            default:
              return null;
          }
          // ⚡ Use fast custom transitions (120ms fade + slide)
          return createFastRoute(page);
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _minSplashTimeElapsed = false;
  bool _notificationServiceInitialized = false;

  @override
  void initState() {
    super.initState();
    // ⚡ Minimum splash screen süresi (UX için)
    // Auth kontrolü tamamlansa bile minimum bu süre kadar splash gösterilir
    _startMinimumSplashTimer();
  }

  void _startMinimumSplashTimer() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _minSplashTimeElapsed = true;
        });
        debugPrint('⏱️ Minimum splash time elapsed');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProviderInterface>(
      builder: (context, authProvider, child) {
        // ✨ Splash screen'i göster eğer:
        // 1. Minimum süre henüz geçmediyse VEYA
        // 2. Auth henüz initialize olmadıysa VEYA
        // 3. Auth yükleniyor ise
        final shouldShowSplash = !_minSplashTimeElapsed ||
                                 !authProvider.isInitialized ||
                                 authProvider.isLoading;

        if (shouldShowSplash) {
          debugPrint('🎨 Showing splash: minTime=${_minSplashTimeElapsed}, initialized=${authProvider.isInitialized}, loading=${authProvider.isLoading}');
          return const SplashScreen();
        }

        debugPrint('✅ Splash complete, auth=${authProvider.isAuthenticated}');

        // Show main navigation if authenticated
        if (authProvider.isAuthenticated) {
          // 📱 Initialize notification service ONCE when user is authenticated
          if (!_notificationServiceInitialized) {
            Future.microtask(() async {
              try {
                await NotificationService().initialize();

                // ⚡ REMOVED: checkInitialMessage() - already called in main()
                // Initial message is stored BEFORE app runs, no need to check again

                _notificationServiceInitialized = true;
                debugPrint('✅ [AUTH] Notification service initialized');
              } catch (e) {
                debugPrint('⚠️ [AUTH] Notification service initialization error: $e');
              }
            });
          }

          return const MainNavigation();
        }

        // Show authentication screen if not authenticated
        return const PhoneAuthScreen();
      },
    );
  }
}