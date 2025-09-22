import 'package:flutter/material.dart';

class MockUser {
  final String uid;
  final String email;
  final String? displayName;

  MockUser({
    required this.uid,
    required this.email,
    this.displayName,
  });
}

class MockAuthProvider extends ChangeNotifier {
  MockUser? _currentUser;
  MockUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  MockAuthProvider() {
    // Auto login for demo purposes
    _currentUser = MockUser(
      uid: 'demo_user_123',
      email: 'demo@rua.app',
      displayName: 'Demo User',
    );
  }

  // Mock sign in
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock validation
      if (email.isEmpty || password.isEmpty) {
        _setError('E-posta ve şifre gereklidir');
        return false;
      }

      if (password.length < 6) {
        _setError('Şifre en az 6 karakter olmalıdır');
        return false;
      }

      // Mock successful login
      _currentUser = MockUser(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@').first,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Giriş yapılırken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mock register
  Future<bool> registerWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // Mock validation
      if (email.isEmpty || password.isEmpty) {
        _setError('E-posta ve şifre gereklidir');
        return false;
      }

      if (!email.contains('@')) {
        _setError('Geçerli bir e-posta adresi girin');
        return false;
      }

      if (password.length < 6) {
        _setError('Şifre en az 6 karakter olmalıdır');
        return false;
      }

      // Mock successful registration
      _currentUser = MockUser(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@').first,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Kayıt olurken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mock sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _currentUser = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Mock reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      if (email.isEmpty || !email.contains('@')) {
        _setError('Geçerli bir e-posta adresi girin');
        return false;
      }

      // Mock successful password reset
      return true;
    } catch (e) {
      _setError('Şifre sıfırlama hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
