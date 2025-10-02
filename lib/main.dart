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
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  try {
    // Initialize Firebase
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProviderInterface, SubscriptionProvider>(
      builder: (context, authProvider, subscriptionProvider, child) {
        // Show splash screen while loading
        if (authProvider.isLoading || 
            !authProvider.isInitialized ||
            subscriptionProvider.isLoading) {
          return const SplashScreen();
        }
        
        // Show main navigation if authenticated
        if (authProvider.isAuthenticated) {
          // Load user subscription
          Future.microtask(() {
            if (subscriptionProvider.currentSubscription == null) {
              subscriptionProvider.loadUserSubscription();
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