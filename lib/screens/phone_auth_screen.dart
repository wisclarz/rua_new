import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math';
import '../providers/auth_provider_interface.dart';
import 'auth/widgets/phone_input_card.dart';
import 'auth/widgets/verification_code_card.dart';
import 'auth/widgets/social_auth_buttons.dart';
import 'auth/widgets/auth_constants.dart';

/// Ultra-Modern Phone Authentication Screen
///
/// Features:
/// - Glassmorphism design
/// - Smooth page transitions
/// - Floating particles background
/// - Micro-interactions
/// - Modern input fields
class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  bool _isCodeSent = false;
  String _fullPhoneNumber = '';

  late AnimationController _backgroundController;
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _backgroundController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProviderInterface>(context);

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
            // Animated background particles
            _buildAnimatedBackground(),

            // Blur overlay for glassmorphism
            _buildBlurOverlay(),

            // Main content
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Header with animated logo
                          _buildAnimatedHeader(),

                          // Main card with smooth transitions
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildAuthCard(authProvider),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Footer with social auth
                          if (!_isCodeSent) _buildSocialAuthSection(authProvider),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _FloatingParticlesPainter(
            animationValue: _backgroundController.value,
          ),
        );
      },
    );
  }

  Widget _buildBlurOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
        child: Container(
          color: Colors.black.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Column(
                  children: [
                    // Glassmorphic logo container
                    Container(
                      width: 90,
                      height: 90,
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
                              alpha: 0.3 + (_logoController.value * 0.2),
                            ),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.nightlight_round,
                        size: 45,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App title with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF7f13ec),
                          Color(0xFF9B4DE0),
                          Color(0xFFB87FE8),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Dreamp',
                        style: GoogleFonts.poppins(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _isCodeSent
                            ? 'Doğrulama Kodu Gönderildi'
                            : 'Rüyalarınızı keşfedin',
                        key: ValueKey(_isCodeSent),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w300,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAuthCard(AuthProviderInterface authProvider) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: _isCodeSent
          ? VerificationCodeCard(
              key: const ValueKey('verification'),
              phoneNumber: _fullPhoneNumber,
              onVerify: _verifyCode,
              onResend: _resendCode,
              isLoading: authProvider.isLoading,
            )
          : PhoneInputCard(
              key: const ValueKey('phone'),
              phoneController: _phoneController,
              onContinue: _sendVerificationCode,
              isLoading: authProvider.isLoading,
            ),
    );
  }

  Widget _buildSocialAuthSection(AuthProviderInterface authProvider) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Column(
              children: [
                // Divider with text
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'veya',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Social auth buttons
                SocialAuthButtons(
                  onGoogleSignIn: _signInWithGoogle,
                  isLoading: authProvider.isLoading,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Action Methods
  Future<void> _sendVerificationCode() async {
    final phone = _phoneController.text.replaceAll(' ', '');
    _fullPhoneNumber = '+90 $phone';

    final authProvider = Provider.of<AuthProviderInterface>(
      context,
      listen: false,
    );

    final success = await authProvider.sendPhoneVerificationCode(
      _fullPhoneNumber,
    );

    if (success && mounted) {
      setState(() {
        _isCodeSent = true;
      });
      _showSuccessMessage('Doğrulama kodu gönderildi');
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorMessage(authProvider.errorMessage!);
    }
  }

  Future<void> _verifyCode(String code) async {
    final authProvider = Provider.of<AuthProviderInterface>(
      context,
      listen: false,
    );

    final success = await authProvider.verifyPhoneCode(
      smsCode: code,
      userName: 'User',
    );

    if (success && mounted) {
      _showSuccessMessage('Giriş başarılı!');
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorMessage(authProvider.errorMessage!);
    }
  }

  Future<void> _resendCode() async {
    await _sendVerificationCode();
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = Provider.of<AuthProviderInterface>(
      context,
      listen: false,
    );

    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      _showSuccessMessage('Google ile giriş başarılı!');
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorMessage(authProvider.errorMessage!);
    }
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Floating particles painter
class _FloatingParticlesPainter extends CustomPainter {
  final double animationValue;

  _FloatingParticlesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = Random(42);

    for (int i = 0; i < 40; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      final floatX = baseX + sin((animationValue + i * 0.1) * pi * 2) * 15;
      final floatY = baseY + cos((animationValue + i * 0.15) * pi * 2) * 25;

      final radius = random.nextDouble() * 2 + 0.5;
      final opacity = random.nextDouble() * 0.3 + 0.1;

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(floatX, floatY), radius, paint);

      paint.color = const Color(0xFF9B4DE0).withValues(alpha: opacity * 0.2);
      canvas.drawCircle(Offset(floatX, floatY), radius * 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(_FloatingParticlesPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}
