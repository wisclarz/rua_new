// lib/main.dart - Real-time listener ile güncellenmiş

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
    print('✅ Firebase initialized successfully');
  } catch (e) {
    _isFirebaseInitialized = false;
    print('❌ Firebase initialization error: $e');
    print('📱 Using mock authentication provider');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProviderInterface>(
          create: (_) => _isFirebaseInitialized 
              ? FirebaseAuthProvider()
              : MockAuthProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProviderInterface, DreamProvider>(
          create: (_) => DreamProvider(),
          update: (context, auth, dreamProvider) {
            // When auth state changes, update DreamProvider
            if (dreamProvider != null) {
              // If user is authenticated and not already listening, start listening
              if (auth.isAuthenticated) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  dreamProvider.startListeningToAuthenticatedUser();
                });
              } else {
                // If user is not authenticated, stop listening
                dreamProvider.stopListeningToDreams();
              }
            }
            return dreamProvider ?? DreamProvider();
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
    return Consumer<AuthProviderInterface>(
      builder: (context, authProvider, child) {
        // Show splash screen while loading
        if (authProvider.isLoading) {
          return const SplashScreen();
        }
        
        // Show main navigation if authenticated
        if (authProvider.isAuthenticated) {
          return const MainNavigation();
        }
        
        // Show authentication screen
        return const PhoneAuthScreen();
      },
    );
  }
}