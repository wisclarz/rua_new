import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider_interface.dart';
import '../widgets/glassmorphic_container.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isCodeSent = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B1E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0B1E),
              Color(0xFF1A1B2E),
              Color(0xFF2D1B69),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: size.height - MediaQuery.of(context).padding.top,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 50),
                            _buildAuthCard(),
                            const SizedBox(height: 30),
                            _buildGoogleSignInButton(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.phone_android,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Rüya Defteri',
          style: GoogleFonts.orbitron(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isCodeSent ? 'Doğrulama Kodu' : 'Telefon ile Giriş',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCard() {
    return GlassmorphicContainer(
      width: double.infinity,
      borderRadius: 24,
      blurValue: 20,
      opacityValue: 0.1,
      color: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_isCodeSent) ...[
                _buildPhoneInput(),
                const SizedBox(height: 24),
                _buildNameInput(),
                const SizedBox(height: 32),
                _buildSendCodeButton(),
              ] else ...[
                _buildCodeInput(),
                const SizedBox(height: 24),
                _buildVerifyButton(),
                const SizedBox(height: 16),
                _buildResendButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Telefon Numarası',
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        prefixText: '+90 ',
        prefixStyle: GoogleFonts.poppins(color: Colors.white),
        hintText: '5XX XXX XX XX',
        hintStyle: GoogleFonts.poppins(color: Colors.white30),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        prefixIcon: const Icon(Icons.phone, color: Color(0xFF6366F1)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Telefon numarası gereklidir';
        }
        if (value.length != 10) {
          return 'Geçerli bir telefon numarası girin';
        }
        return null;
      },
    );
  }

  Widget _buildNameInput() {
    return TextFormField(
      controller: _nameController,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'İsim',
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        hintText: 'Adınızı girin',
        hintStyle: GoogleFonts.poppins(color: Colors.white30),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        prefixIcon: const Icon(Icons.person, color: Color(0xFF6366F1)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'İsim gereklidir';
        }
        return null;
      },
    );
  }

  Widget _buildCodeInput() {
    return Column(
      children: [
        Text(
          '+90${_phoneController.text} numarasına gönderilen 6 haneli kodu girin',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            letterSpacing: 4,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: 'Doğrulama Kodu',
            labelStyle: GoogleFonts.poppins(color: Colors.white70),
            hintText: '000000',
            hintStyle: GoogleFonts.poppins(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            prefixIcon: const Icon(Icons.sms, color: Color(0xFF6366F1)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Doğrulama kodu gereklidir';
            }
            if (value.length != 6) {
              return '6 haneli kodu girin';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSendCodeButton() {
    return Consumer<AuthProviderInterface>(
      builder: (context, authProvider, child) {
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: authProvider.isLoading ? _pulseAnimation.value : 1.0,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _sendVerificationCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Doğrulama Kodu Gönder',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVerifyButton() {
    return Consumer<AuthProviderInterface>(
      builder: (context, authProvider, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Doğrula ve Giriş Yap',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildResendButton() {
    return TextButton(
      onPressed: _resendCode,
      child: Text(
        'Kodu tekrar gönder',
        style: GoogleFonts.poppins(
          color: const Color(0xFF6366F1),
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Consumer<AuthProviderInterface>(
      builder: (context, authProvider, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: authProvider.isLoading ? null : _signInWithGoogle,
            icon: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.red, Colors.yellow, Colors.green],
                ),
              ),
              child: const Icon(
                Icons.account_circle,
                color: Colors.white,
                size: 20,
              ),
            ),
            label: Text(
              'Google ile Giriş Yap',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  void _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) return;

    final phoneNumber = '+90${_phoneController.text}';
    final authProvider = context.read<AuthProviderInterface>();

    print('🚀 Sending verification code to: $phoneNumber');
    
    final success = await authProvider.sendPhoneVerificationCode(phoneNumber);
    
    if (success && mounted) {
      setState(() {
        _isCodeSent = true;
      });
      _showSnackBar('Doğrulama kodu gönderildi! 📱', Colors.green);
    } else if (mounted) {
      String errorMsg = authProvider.errorMessage ?? 'Kod gönderilirken hata oluştu';
      
      // Specific error messages for common issues
      if (errorMsg.contains('not authorized')) {
        errorMsg = 'Firebase yapılandırması eksik. SHA-1 fingerprint kontrol edilsin.';
      } else if (errorMsg.contains('Invalid phone number')) {
        errorMsg = 'Geçersiz telefon numarası formatı. +90 ile başlamalı.';
      } else if (errorMsg.contains('quota')) {
        errorMsg = 'SMS kotası aşıldı. Daha sonra tekrar deneyin.';
      } else if (errorMsg.contains('Türkiye bölgesi') || errorMsg.contains('region enabled')) {
        // Show a special dialog for region issues
        _showRegionErrorDialog();
        return;
      }
      
      _showSnackBar(errorMsg, Colors.red);
      print('❌ Phone verification error: $errorMsg');
    }
  }

  void _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProviderInterface>();
    
    final success = await authProvider.verifyPhoneCode(
      smsCode: _codeController.text,
      userName: _nameController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      _showSnackBar(
        authProvider.errorMessage ?? 'Doğrulama başarısız',
        Colors.red,
      );
    }
  }

  void _resendCode() {
    setState(() {
      _isCodeSent = false;
      _codeController.clear();
    });
    
    final authProvider = context.read<AuthProviderInterface>();
    authProvider.resetPhoneVerification();
  }

  void _signInWithGoogle() async {
    final authProvider = context.read<AuthProviderInterface>();
    
    final success = await authProvider.signInWithGoogle();
    
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      _showSnackBar(
        authProvider.errorMessage ?? 'Google ile giriş başarısız',
        Colors.red,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showRegionErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '🇹🇷 Bölge Hatası',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Türkiye bölgesi için SMS gönderimi henüz etkinleştirilmemiş.',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Text(
                'Çözüm seçenekleri:',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Test numarası kullanın: +90 555 123 4567\n• Firebase Console\'dan Türkiye bölgesini etkinleştirin\n• Google ile giriş yapın',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Auto-fill test number
                _phoneController.text = '5551234567';
              },
              child: Text(
                'Test Numarası Kullan',
                style: GoogleFonts.poppins(color: const Color(0xFF6366F1)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tamam',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }
}
