import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Firebase temporarily disabled for UI/UX focus
// import 'package:firebase_core/firebase_core.dart';
// import 'package:rua_new/config/firebase_options.dart';
// import 'package:rua_new/providers/auth_provider.dart';
import 'package:rua_new/config/app_theme.dart';
import 'package:rua_new/providers/dream_provider.dart';
import 'package:rua_new/providers/mock_auth_provider.dart';
import 'package:rua_new/screens/splash_screen.dart';
import 'package:rua_new/screens/login_screen.dart';
import 'package:rua_new/screens/main_navigation.dart';
import 'package:rua_new/screens/dream_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase disabled for UI/UX development
  // Simulate initialization delay
  await Future.delayed(const Duration(milliseconds: 500));
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MockAuthProvider()),
        ChangeNotifierProvider(create: (context) => DreamProvider()),
      ],
      child: MaterialApp(
        title: 'RUA - Rüya Analizi',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/main': (context) => const MainNavigation(),
          '/dream-history': (context) => const DreamHistoryScreen(),
        },
      ),
    );
  }
}