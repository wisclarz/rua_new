import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ⚡⚡ OPTIMIZED SplashScreen - Reduced animations for better performance
/// - Reduced particles from 30 to 8 (75% reduction)
/// - Simplified gradient calculations
/// - Removed heavy AnimationController loops
/// - Optimized build cycles
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        // ⚡ Static gradient instead of animated (major perf boost)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0F3460),
              Color(0xFF533483),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ⚡⚡ OPTIMIZED: Reduced particles from 30 to 8
            ...List.generate(8, (index) {
              return Positioned(
                left: (index * 47.0) % MediaQuery.of(context).size.width,
                top: (index * 83.0) % MediaQuery.of(context).size.height,
                child: Icon(
                  index % 3 == 0 ? Icons.star : Icons.circle,
                  color: Colors.white.withOpacity(0.3),
                  size: index % 2 == 0 ? 4 : 3,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .fadeIn(duration: 2000.ms)
              .fadeOut(duration: 2000.ms);
            }),
            
            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Container - Simplified
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      size: 70,
                      color: Colors.white,
                    ),
                  )
                  .animate()
                  .scale(
                    delay: 200.ms,
                    duration: 800.ms, // Reduced from 1200ms
                    curve: Curves.easeOut, // Changed from elasticOut
                  )
                  .fadeIn(duration: 600.ms), // Reduced from 800ms
                  
                  const SizedBox(height: 48),
                  
                  // App Name - Simplified
                  Text(
                    'Dreamp',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                      letterSpacing: 2,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 800.ms) // Reduced delay
                  .slide(
                    begin: const Offset(0, -0.2), // Reduced movement
                    curve: Curves.easeOut, // Simplified curve
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Decorative Line
                  Container(
                    width: 60,
                    height: 2,
                    color: Colors.white.withOpacity(0.8),
                  )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 600.ms)
                  .scale(begin: const Offset(0, 1), duration: 600.ms),
                  
                  const SizedBox(height: 16),
                  
                  // Tagline
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Rüyalarınızı keşfedin ve analiz edin',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        letterSpacing: 0.5,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 800.ms)
                  .slide(
                    begin: const Offset(0, 0.2),
                    curve: Curves.easeOut,
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // ⚡ Simplified Loading Indicator
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 600.ms),
                  
                  const SizedBox(height: 20),
                  
                  // Loading Text
                  Text(
                    'Yükleniyor...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 1200.ms, duration: 600.ms),
                ],
              ),
            ),
            
            // Bottom Decoration
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.psychology,
                    size: 16,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Psikolojik Rüya Analizi',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 1400.ms, duration: 800.ms),
            ),
          ],
        ),
      ),
    );
  }
}
