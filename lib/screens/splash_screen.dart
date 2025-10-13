import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

/// Modern Splash Screen with Smooth Animations
///
/// Features:
/// - Animated logo with pulsating glow
/// - Gradient background matching app theme
/// - Smooth loading indicator
/// - Optimized for fast initialization
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
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
              Color(0xFF120B1C), // AppTheme.darkBackground
              Color(0xFF1F152E), // AppTheme.darkSurface
              Color(0xFF2D1B4E), // AppTheme.darkSurfaceVariant
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles background
            _buildParticlesBackground(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo with glow
                  _buildAnimatedLogo(),

                  const SizedBox(height: 40),

                  // App title with gradient
                  _buildGradientTitle(),

                  const SizedBox(height: 12),

                  // Subtitle
                  _buildSubtitle(),

                  const SizedBox(height: 60),

                  // Modern loading indicator
                  _buildLoadingIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticlesBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _ParticlesPainter(),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7f13ec).withValues(alpha: _glowAnimation.value * 0.6),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: const Color(0xFF9B4DE0).withValues(alpha: _glowAnimation.value * 0.4),
                  blurRadius: 60,
                  spreadRadius: 15,
                ),
              ],
            ),
            child: const Icon(
              Icons.nightlight_round,
              size: 70,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFF7f13ec), // AppTheme.deepPurple
          Color(0xFF9B4DE0), // AppTheme.softPurple
          Color(0xFFB87FE8), // AppTheme.lightPurple
        ],
      ).createShader(bounds),
      child: Text(
        'Dreamp',
        style: GoogleFonts.poppins(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 2.0,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.7 + (_glowAnimation.value * 0.3),
          child: Text(
            'Rüyalarınızı keşfedin',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 40,
      height: 40,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CircularProgressIndicator(
            strokeWidth: 3.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: _glowAnimation.value),
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
          );
        },
      ),
    );
  }
}

/// Custom painter for particle effect
class _ParticlesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw subtle particles
    final random = math.Random(42); // Fixed seed for consistent pattern
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2 + 1;

      paint.color = Colors.white.withValues(alpha: random.nextDouble() * 0.3);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
