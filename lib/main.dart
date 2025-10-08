// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
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

bool _isFirebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ⚡⚡ OPTIMIZED: Batch system configuration (non-blocking)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // ⚡ Run orientation and Firebase in parallel
  final futures = [
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
    _initializeFirebase(),
  ];
  
  await Future.wait(futures);
  
  runApp(const MyApp());
}

/// ⚡ Separate Firebase initialization for better async handling
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _isFirebaseInitialized = true;
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    _isFirebaseInitialized = false;
    debugPrint('❌ Firebase initialization error: $e');
    debugPrint('📱 Using mock authentication provider');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ⚡⚡ OPTIMIZED: Auth provider - LAZY initialization (non-blocking)
        ChangeNotifierProvider<AuthProviderInterface>(
          create: (_) => _isFirebaseInitialized 
              ? FirebaseAuthProvider()
              : MockAuthProvider(),
          lazy: true, // Changed to lazy to prevent blocking startup
        ),
        
        // ⚡⚡ OPTIMIZED: Subscription provider - LAZY initialization
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
          lazy: true, // Defer heavy initialization (AdMob, IAP)
        ),
        
        // ⚡ Dream provider - lazy loaded, deferred initialization
        ChangeNotifierProxyProvider<AuthProviderInterface, DreamProvider>(
          create: (_) => DreamProvider(),
          lazy: true,
          update: (context, auth, dreamProvider) {
            if (dreamProvider == null) return DreamProvider();
            
            // ⚡ Defer dream loading until after first frame is rendered
            if (auth.isAuthenticated && auth.isInitialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
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
        title: 'Rüya - Dream Analysis',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/home': (context) => const MainNavigation(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}

/// ⚡⚡ OPTIMIZED AuthWrapper with selective rebuilds
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _subscriptionRequested = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProviderInterface, SubscriptionProvider>(
      builder: (context, authProvider, subscriptionProvider, child) {
        // ⚡ Show splash screen while loading
        if (!authProvider.isInitialized) {
          return const SplashScreen();
        }
        
        // ⚡ Show main navigation if authenticated
        if (authProvider.isAuthenticated) {
          // ⚡⚡ OPTIMIZED: Only request subscription once
          if (!_subscriptionRequested) {
            _subscriptionRequested = true;
            // Schedule after build cycle
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (subscriptionProvider.currentSubscription == null) {
                subscriptionProvider.loadUserSubscription();
              }
            });
          }
          
          return const MainNavigation();
        }
        
        // Show authentication screen
        return const PhoneAuthScreen();
      },
    );
  }
}