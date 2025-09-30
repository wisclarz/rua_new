import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.8),
              theme.colorScheme.secondary.withValues(alpha: 0.6),
              theme.colorScheme.tertiary.withValues(alpha: 0.4),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.bedtime,
                  size: 60,
                  color: Colors.white,
                ),
              ).animate()
                .scale(delay: 200.ms, duration: 800.ms, curve: Curves.elasticOut)
                .then()
                .shimmer(duration: 1000.ms),
              
              const SizedBox(height: 32),
              
              // App Name
              Text(
                'RUA Dream',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ).animate()
                .fadeIn(delay: 600.ms, duration: 800.ms)
                .slide(begin: const Offset(0, -0.3)),
              
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                'Rüyalarınızı keşfedin ve analiz edin',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ).animate()
                .fadeIn(delay: 800.ms, duration: 800.ms)
                .slide(begin: const Offset(0, 0.3)),
              
              const SizedBox(height: 64),
              
              // Loading Indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ).animate()
                .fadeIn(delay: 1000.ms, duration: 800.ms),
              
              const SizedBox(height: 16),
              
              // Loading Text
              Text(
                'Yükleniyor...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ).animate()
                .fadeIn(delay: 1200.ms, duration: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}