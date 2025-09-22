import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mock_auth_provider.dart';
import '../providers/dream_provider.dart';
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
            blur: 20,
            alignment: Alignment.center,
            border: 2,
            linearGradient: LinearGradient(
              colors: [
                color.withOpacity(0.9),
                color.withOpacity(0.8),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

    // Auto remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<MockAuthProvider>(context, listen: false);
    bool success;

    if (_isLoginMode) {
      success = await authProvider.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await authProvider.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    if (success && mounted) {
      // Test Firebase connections after successful login
      final dreamProvider = Provider.of<DreamProvider>(context, listen: false);
      await dreamProvider.testFirestoreConnection();
      await dreamProvider.testStorageUpload();
      
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<MockAuthProvider>(
          builder: (context, authProvider, child) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and Title
                    const Icon(
                      Icons.bedtime,
                      size: 80,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 32),
                    
                    Text(
                      _isLoginMode ? 'Giriş Yap' : 'Hesap Oluştur',
                      style: Theme.of(context).textTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      _isLoginMode 
                          ? 'Rüyalarına analiz yapmak için giriş yap'
                          : 'Rüya analizine başlamak için hesap oluştur',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'E-posta gereklidir';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Geçerli bir e-posta girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre gereklidir';
                        }
                        if (value.length < 6) {
                          return 'Şifre en az 6 karakter olmalı';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Error Message
                    if (authProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          authProvider.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Submit Button
                    ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _submitForm,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isLoginMode ? 'Giriş Yap' : 'Hesap Oluştur'),
                    ),
                    const SizedBox(height: 16),

                    // Switch Mode Button
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                        });
                      },
                      child: Text(
                        _isLoginMode 
                            ? 'Hesabın yok mu? Hesap oluştur'
                            : 'Hesabın var mı? Giriş yap',
                      ),
                    ),

                    // Forgot Password (only in login mode)
                    if (_isLoginMode) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _showForgotPasswordDialog();
                        },
                        child: const Text('Şifremi Unuttum'),
                      ),
                    ],

                    // Test Firebase Connections Button (Debug)
                    if (authProvider.isAuthenticated) ...[
                      const SizedBox(height: 32),
                      OutlinedButton(
                        onPressed: () async {
                          final dreamProvider = Provider.of<DreamProvider>(context, listen: false);
                          await dreamProvider.testFirestoreConnection();
                          await dreamProvider.testStorageUpload();
                          
                          if (mounted) {
                            _showModernSnackBar(
                              context,
                              'Firebase bağlantıları test edildi! ✅',
                              Theme.of(context).colorScheme.primary,
                              Icons.cloud_done,
                            );
                          }
                        },
                        child: const Text('Firebase Bağlantılarını Test Et'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Sıfırlama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('E-posta adresinizi girin, şifre sıfırlama bağlantısı gönderelim.'),
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
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<MockAuthProvider>(context, listen: false);
              final success = await authProvider.resetPassword(emailController.text.trim());
              
              if (mounted) {
                Navigator.pop(context);
                _showModernSnackBar(
                  context,
                  success 
                      ? 'Şifre sıfırlama bağlantısı gönderildi! 📧'
                      : '${authProvider.errorMessage ?? 'Hata oluştu'} ❌',
                  success 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                  success 
                      ? Icons.email_outlined
                      : Icons.error_outline,
                );
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}
