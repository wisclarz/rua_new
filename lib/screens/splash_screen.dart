import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF1A1A2E),
                        const Color(0xFF16213E),
                        (_controller.value * 2) % 1,
                      )!,
                      const Color(0xFF0F3460),
                      Color.lerp(
                        const Color(0xFF533483),
                        const Color(0xFF7B2CBF),
                        (_controller.value * 3) % 1,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Floating Stars/Particles
          ...List.generate(30, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final offset = (index * 0.1 + _controller.value) % 1;
                final x = (math.sin(index * 2.0 + _controller.value * 2) * 0.4 + 0.5) * size.width;
                final y = offset * size.height;
                final opacity = (1 - offset).clamp(0.0, 0.8);
                final scale = 0.3 + (math.sin(index * 3.0 + _controller.value * 4) * 0.2 + 0.2);
                
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Icon(
                        index % 3 == 0 ? Icons.star : (index % 3 == 1 ? Icons.star_half : Icons.circle),
                        color: Colors.white.withOpacity(0.6),
                        size: index % 4 == 0 ? 4 : 3,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          
          // Glow Effect Behind Logo
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .fadeIn(duration: 1500.ms)
            .then()
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.3, 1.3),
              duration: 2000.ms,
            )
            .then()
            .scale(
              begin: const Offset(1.3, 1.3),
              end: const Offset(1.0, 1.0),
              duration: 2000.ms,
            ),
          
          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container with Glass Effect
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Glow Ring
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat())
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.15, 1.15),
                        duration: 2000.ms,
                      )
                      .fadeOut(begin: 0.5, duration: 2000.ms),
                    
                    // Main Logo Container
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
                            color: Colors.purple.withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Moon Icon
                          const Icon(
                            Icons.nightlight_round,
                            size: 70,
                            color: Colors.white,
                          ),
                          // Small Stars Around Moon
                          Positioned(
                            top: 25,
                            right: 25,
                            child: Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                            .fadeIn(duration: 800.ms)
                            .then()
                            .fadeOut(duration: 800.ms),
                          Positioned(
                            bottom: 35,
                            left: 30,
                            child: Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                            .fadeIn(delay: 400.ms, duration: 800.ms)
                            .then()
                            .fadeOut(duration: 800.ms),
                        ],
                      ),
                    ).animate()
                      .scale(
                        delay: 200.ms,
                        duration: 1200.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 800.ms),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // App Name with Gradient
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFE0B0FF),
                      Colors.white,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Dreamp',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                      letterSpacing: 2,
                    ),
                  ),
                ).animate()
                  .fadeIn(delay: 800.ms, duration: 1000.ms)
                  .slide(
                    begin: const Offset(0, -0.3),
                    curve: Curves.easeOutCubic,
                  )
                  .shimmer(delay: 1800.ms, duration: 1500.ms),
                
                const SizedBox(height: 16),
                
                // Decorative Line
                Container(
                  width: 60,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ).animate()
                  .fadeIn(delay: 1000.ms, duration: 800.ms)
                  .scale(begin: const Offset(0, 1), duration: 800.ms),
                
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
                ).animate()
                  .fadeIn(delay: 1200.ms, duration: 1000.ms)
                  .slide(
                    begin: const Offset(0, 0.3),
                    curve: Curves.easeOutCubic,
                  ),
                
                const SizedBox(height: 80),
                
                // Loading Indicator with Custom Style
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Ring
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                      // Inner Ring
                      SizedBox(
                        width: 35,
                        height: 35,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.purple.shade200.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate()
                  .fadeIn(delay: 1400.ms, duration: 800.ms)
                  .scale(begin: const Offset(0.8, 0.8), duration: 800.ms),
                
                const SizedBox(height: 20),
                
                // Loading Text
                Text(
                  'Yükleniyor...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ).animate()
                  .fadeIn(delay: 1600.ms, duration: 800.ms)
                  .then(delay: 800.ms)
                  .fadeOut(duration: 1000.ms)
                  .then()
                  .fadeIn(duration: 1000.ms, curve: Curves.easeInOut)
                  .flip(),
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
            ).animate()
              .fadeIn(delay: 1800.ms, duration: 1000.ms)
              .slide(begin: const Offset(0, 0.5)),
          ),
        ],
      ),
    );
  }
}