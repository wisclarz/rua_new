import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/dream_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';

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
    // Firebase will be initialized later
    print('✅ App initialized successfully');
  } catch (e) {
    print('❌ App initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DreamProvider()),
      ],
      child: MaterialApp(
        title: 'RUA Dream App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const MainNavigation(),
          '/profile': (context) => const ProfileScreen(),
          '/profile-edit': (context) => _buildComingSoonScreen(
            context,
            'Profil Düzenle',
            'Profil düzenleme yakında...',
            Icons.edit,
          ),
          '/notifications': (context) => _buildComingSoonScreen(
            context,
            'Bildirimler',
            'Bildirim ayarları yakında...',
            Icons.notifications,
          ),
          '/privacy-security': (context) => _buildComingSoonScreen(
            context,
            'Gizlilik & Güvenlik',
            'Güvenlik ayarları yakında...',
            Icons.security,
          ),
          '/theme-settings': (context) => _buildComingSoonScreen(
            context,
            'Tema Ayarları',
            'Tema ayarları yakında...',
            Icons.palette,
          ),
          '/statistics': (context) => _buildComingSoonScreen(
            context,
            'İstatistikler',
            'İstatistikler yakında...',
            Icons.analytics,
          ),
          '/backup': (context) => _buildComingSoonScreen(
            context,
            'Yedekleme',
            'Yedekleme yakında...',
            Icons.backup,
          ),
          '/help-support': (context) => _buildComingSoonScreen(
            context,
            'Yardım & Destek',
            'Destek yakında...',
            Icons.help,
          ),
          '/about': (context) => _buildComingSoonScreen(
            context,
            'Hakkında',
            'Hakkında bilgisi yakında...',
            Icons.info,
          ),
        },
      ),
    );
  }
  
  Widget _buildComingSoonScreen(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Geri Dön'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading screen while checking authentication
        if (authProvider.isLoading) {
          return const SplashScreen();
        }
        
        // Show appropriate screen based on authentication status
        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          return const MainNavigation();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}