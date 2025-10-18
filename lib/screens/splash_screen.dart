import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

/// Ultra-Modern Splash Screen with Advanced Animations
///
/// Features:
/// - Floating animated particles with physics
/// - Shimmer/wave effect on logo
/// - Glassmorphism design
/// - Smooth pulsating animations
/// - Modern loading dots animation
/// - Optimized for 60 FPS
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _particlesController;
  late AnimationController _dotsController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Pulse animation for logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Particles animation
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Loading dots animation
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _particlesController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0514),
              Color(0xFF1F152E),
              Color(0xFF2D1B4E),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated floating particles
            _buildFloatingParticles(),

            // Radial gradient overlay for depth
            _buildRadialGradient(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glassmorphic logo container with shimmer
                  _buildGlassmorphicLogo(),

                  const SizedBox(height: 50),

                  // App title with gradient shimmer
                  _buildShimmerTitle(),

                  const SizedBox(height: 16),

                  // Animated subtitle
                  _buildAnimatedSubtitle(),

                  const SizedBox(height: 80),

                  // Modern loading dots
                  _buildModernLoadingDots(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingParticles() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particlesController,
        builder: (context, child) {
          return CustomPaint(
            painter: _FloatingParticlesPainter(
              animationValue: _particlesController.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRadialGradient() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              const Color(0xFF7f13ec).withValues(alpha: 0.15),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _shimmerController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow rings
              ...List.generate(3, (index) {
                final delay = index * 0.15;
                final glowValue = (_glowAnimation.value + delay).clamp(0.0, 1.0);
                return Container(
                  width: 180 + (index * 25),
                  height: 180 + (index * 25),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF7f13ec).withValues(
                        alpha: (0.3 - index * 0.1) * glowValue,
                      ),
                      width: 2,
                    ),
                  ),
                );
              }),

              // Main glassmorphic container
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7f13ec).withValues(
                        alpha: _glowAnimation.value * 0.6,
                      ),
                      blurRadius: 50,
                      spreadRadius: 15,
                    ),
                    BoxShadow(
                      color: const Color(0xFF9B4DE0).withValues(
                        alpha: _glowAnimation.value * 0.4,
                      ),
                      blurRadius: 70,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    children: [
                      // Icon
                      const Center(
                        child: Icon(
                          Icons.nightlight_round,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),

                      // Shimmer overlay
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ShimmerPainter(
                            animationValue: _shimmerAnimation.value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerTitle() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [
              Color(0xFF7f13ec),
              Color(0xFF9B4DE0),
              Color(0xFFB87FE8),
              Color(0xFF9B4DE0),
              Color(0xFF7f13ec),
            ],
            stops: [
              0.0,
              (_shimmerAnimation.value - 0.5).clamp(0.0, 1.0),
              _shimmerAnimation.value.clamp(0.0, 1.0),
              (_shimmerAnimation.value + 0.5).clamp(0.0, 1.0),
              1.0,
            ],
          ).createShader(bounds),
          child: Text(
            'Dreamp',
            style: GoogleFonts.poppins(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3.0,
              height: 1.0,
              shadows: [
                Shadow(
                  color: const Color(0xFF7f13ec).withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSubtitle() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.6 + (_glowAnimation.value * 0.4),
          child: Text(
            'Rüyalarınızı keşfedin',
            style: GoogleFonts.poppins(
              fontSize: 17,
              color: Colors.white,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w300,
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernLoadingDots() {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _dotsController,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = (_dotsController.value + delay) % 1.0;
              final scale = 0.5 + (math.sin(value * math.pi * 2) * 0.5);
              final opacity = 0.3 + (math.sin(value * math.pi * 2) * 0.7);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: opacity),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7f13ec).withValues(alpha: opacity * 0.6),
                      blurRadius: 8 * scale,
                      spreadRadius: 2 * scale,
                    ),
                  ],
                ),
                transform: Matrix4.identity()..scale(scale),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Floating particles painter with physics-based movement
class _FloatingParticlesPainter extends CustomPainter {
  final double animationValue;

  _FloatingParticlesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);

    for (int i = 0; i < 50; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      // Create floating effect with sine waves
      final floatX = baseX + math.sin((animationValue + i * 0.1) * math.pi * 2) * 20;
      final floatY = baseY + math.cos((animationValue + i * 0.15) * math.pi * 2) * 30;

      final radius = random.nextDouble() * 2.5 + 0.5;
      final opacity = random.nextDouble() * 0.4 + 0.1;

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(floatX, floatY), radius, paint);

      // Add glow
      paint.color = const Color(0xFF9B4DE0).withValues(alpha: opacity * 0.3);
      canvas.drawCircle(Offset(floatX, floatY), radius * 2, paint);
    }
  }

  @override
  bool shouldRepaint(_FloatingParticlesPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}

/// Shimmer effect painter
class _ShimmerPainter extends CustomPainter {
  final double animationValue;

  _ShimmerPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.2),
          Colors.transparent,
        ],
        stops: const [0.3, 0.5, 0.7],
      ).createShader(Rect.fromLTWH(
        animationValue * size.width * 0.5,
        animationValue * size.height * 0.5,
        size.width,
        size.height,
      ));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      shimmerPaint,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}
