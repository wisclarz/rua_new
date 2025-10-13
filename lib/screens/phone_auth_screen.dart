import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider_interface.dart';
import 'auth/widgets/phone_input_card.dart';
import 'auth/widgets/verification_code_card.dart';
import 'auth/widgets/social_auth_buttons.dart';
import 'auth/widgets/auth_constants.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();

  bool _isCodeSent = false;
  String _fullPhoneNumber = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProviderInterface>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF120B1C),
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
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              constraints: BoxConstraints(
                minHeight: size.height - MediaQuery.of(context).padding.top,
              ),
              padding: const EdgeInsets.all(AuthConstants.spacingLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModernHeader(),
                  const SizedBox(height: AuthConstants.spacingXXLarge),

                  // Animated card transition
                  AnimatedSwitcher(
                    duration: AuthConstants.slowDuration,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.2, 0),
                            end: Offset.zero,
                          ).animate(animation),
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
                  ),

                  const SizedBox(height: AuthConstants.spacingXLarge),

                  // Social auth buttons (only show when not code sent)
                  if (!_isCodeSent)
                    SocialAuthButtons(
                      onGoogleSignIn: _signInWithGoogle,
                      isLoading: authProvider.isLoading,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Column(
      children: [
        // App Icon - Matching Splash Screen
        Container(
          width: 100,
          height: 100,
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
                color: const Color(0xFF7f13ec).withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.nightlight_round,
            size: 50,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: AuthConstants.spacingLarge),

        // App Title with Gradient - Matching Splash Screen
        ShaderMask(
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
        ),

        const SizedBox(height: AuthConstants.spacingSmall),

        // Animated Subtitle
        AnimatedSwitcher(
          duration: AuthConstants.mediumDuration,
          child: Text(
            _isCodeSent ? 'Doğrulama Kodu Gönderildi' : 'Rüyalarınızı keşfedin',
            key: ValueKey(_isCodeSent),
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.8,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // Action Methods

  Future<void> _sendVerificationCode() async {
    // Format phone number with country code
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
      userName: 'User', // Default name, can be updated in profile
    );

    if (success && mounted) {
      // Navigation is handled by AuthWrapper in main.dart
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
      // Navigation is handled by AuthWrapper in main.dart
      _showSuccessMessage('Google ile giriş başarılı!');
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorMessage(authProvider.errorMessage!);
    }
  }

  // Helper Methods

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
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuthConstants.radiusMedium),
        ),
        margin: const EdgeInsets.all(AuthConstants.spacingMedium),
        duration: const Duration(seconds: 3),
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
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuthConstants.radiusMedium),
        ),
        margin: const EdgeInsets.all(AuthConstants.spacingMedium),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}