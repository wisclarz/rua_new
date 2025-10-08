import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_auth_provider.dart';
import '../widgets/glassmorphic_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoginMode = true;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showModernSnackBar(BuildContext context, String message, Color color, IconData icon) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 80,
            borderRadius: 16,
            blurValue: 20, // blur parametresi blurValue olarak değiştirildi
            opacityValue: 0.9,
            color: color.withValues(alpha: 0.8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and Title
                  _buildHeader(context),
                  const SizedBox(height: 40),
                  
                  // Login Form
                  GlassmorphicContainer(
                    borderRadius: 24,
                    blurValue: 20,
                    opacityValue: 0.15,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tab Selector
                          _buildTabSelector(),
                          const SizedBox(height: 24),
                          
                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (!_isLoginMode) ...[
                                  _buildTextField(
                                    controller: TextEditingController(),
                                    label: 'Ad Soyad',
                                    prefixIcon: Icons.person_outline,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Ad soyad gerekli';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'E-posta',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'E-posta gerekli';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value!)) {
                                      return 'Geçersiz e-posta formatı';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Şifre',
                                  prefixIcon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                    icon: Icon(_isPasswordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined),
                                  ),
                                  obscureText: !_isPasswordVisible,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Şifre gerekli';
                                    }
                                    if (value!.length < 6) {
                                      return 'Şifre en az 6 karakter olmalı';
                                    }
                                    return null;
                                  },
                                ),
                                
                                if (!_isLoginMode) ...[
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: TextEditingController(),
                                    label: 'Şifre Tekrar',
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: true,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Şifre tekrarı gerekli';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Şifreler eşleşmiyor';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                                
                                if (_isLoginMode) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => _showForgotPasswordDialog(context),
                                      child: Text(
                                        'Şifremi Unuttum',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 24),
                                
                                // Submit Button
                                Consumer<FirebaseAuthProvider>(
                                  builder: (context, authProvider, child) {
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: authProvider.isLoading
                                            ? null
                                            : () => (context, authProvider),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme.primary,
                                          foregroundColor: theme.colorScheme.onPrimary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: authProvider.isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                                ),
                                              )
                                            : Text(
                                                _isLoginMode ? 'Giriş Yap' : 'Kayıt Ol',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'veya',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Google Sign In
                          Consumer<FirebaseAuthProvider>(
                            builder: (context, authProvider, child) {
                              return SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: authProvider.isLoading
                                      ? null
                                      : () => _handleGoogleSignIn(context, authProvider),
                                  
                                  label: const Text('Google ile Devam Et'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.onSurface,
                                    side: BorderSide(
                                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Terms and Privacy
                  if (!_isLoginMode)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Kayıt olarak Kullanım Koşulları ve Gizlilik Politikası\'nı kabul etmiş olursunuz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.bedtime,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'RUA Dream',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rüyalarınızı keşfedin ve analiz edin',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLoginMode = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isLoginMode
                      ? theme.colorScheme.primary.withValues(alpha: 0.8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Giriş Yap',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isLoginMode
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLoginMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isLoginMode
                      ? theme.colorScheme.primary.withValues(alpha: 0.8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Kayıt Ol',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isLoginMode
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: theme.colorScheme.primary),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface.withValues(alpha: 0.1),
      ),
    );
  }


  Future<void> _handleGoogleSignIn(BuildContext context, FirebaseAuthProvider authProvider) async {
    // Mevcut provider instance'ını kullan (yeni instance yaratma!)
    final success = await authProvider.signInWithGoogle();
    
    if (mounted) {
      if (success) {
        _showModernSnackBar(
          context,
          'Google ile giriş başarılı! 🎉',
          Colors.green,
          Icons.check_circle_outline,
        );
        
        // Navigate to main navigation
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showModernSnackBar(
          context,
          '${authProvider.errorMessage ?? 'Google girişi başarısız'} ❌',
          Colors.red,
          Icons.error_outline,
        );
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Sıfırlama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'E-posta adresinizi girin, şifre sıfırlama bağlantısı göndereceğiz.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          // ElevatedButton(
          //   onPressed: () async {
          //     final authProvider = Provider.of<FirebaseAuthProvider>(context, listen: false);
          //     final success = await FirebaseAuthProvider().resetPhoneVerification().resetPassword(emailController.text.trim());
              
          //     if (mounted) {
          //       Navigator.pop(context);
          //       _showModernSnackBar(
          //         context,
          //         success 
          //             ? 'Şifre sıfırlama bağlantısı gönderildi! 📧'
          //             : '${authProvider.errorMessage ?? 'Hata oluştu'} ❌',
          //         success 
          //             ? Theme.of(context).colorScheme.primary
          //             : Theme.of(context).colorScheme.error,
          //         success 
          //             ? Icons.email_outlined
          //             : Icons.error_outline,
          //       );
          //     }
          //   },
          //   child: const Text('Gönder'),
          // ),
        ],
      ),
    );
  }
}