// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/app_theme.dart';
import 'config/firebase_options.dart';
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
void _handleNotificationTap(BuildContext context, String dreamId) {
  debugPrint('🔔 Handling notification tap for dream: $dreamId');

  try {
    final dreamProvider = Provider.of<DreamProvider>(context, listen: false);
    final dream = dreamProvider.dreams.firstWhere(
      (d) => d.id == dreamId,
      orElse: () => throw Exception('Dream not found'),
    );

    // Navigate using global navigator key
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => DreamDetailWidget(dream: dream),
        fullscreenDialog: true,
      ),
    );

    debugPrint('✅ Navigated to dream detail: $dreamId');
  } catch (e) {
    debugPrint('❌ Error navigating to dream: $e');
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
        
        // ⚡ Subscription provider - initialized early for all screens
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
          lazy: false,
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
            enabled: true, // ✅ FPS counter aktif - Performans testi için
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
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Keep splash visible for smooth transition
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProviderInterface>(
      builder: (context, authProvider, child) {
        // IMPORTANT: Show splash while:
        // 1. Auth is initializing
        // 2. Initial delay for smooth UX
        // 3. Auth is loading
        if (_showSplash || !authProvider.isInitialized || authProvider.isLoading) {
          return const SplashScreen();
        }

        // Show main navigation if authenticated
        if (authProvider.isAuthenticated) {
          // Load subscription asynchronously (don't block navigation)
          final subscriptionProvider = context.read<SubscriptionProvider>();
          if (subscriptionProvider.currentSubscription == null &&
              !subscriptionProvider.isLoading) {
            Future.microtask(() {
              subscriptionProvider.loadUserSubscription();
            });
          }

          // 📱 Initialize notification service when user is authenticated
          Future.microtask(() async {
            try {
              await NotificationService().initialize();

              // Set notification tap callback
              NotificationService().onNotificationTapped = (String dreamId) {
                _handleNotificationTap(context, dreamId);
              };
            } catch (e) {
              debugPrint('⚠️ Notification service initialization error: $e');
            }
          });

          return const MainNavigation();
        }

        // Show authentication screen
        return const PhoneAuthScreen();
      },
    );
  }
}