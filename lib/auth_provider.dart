import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/firebase_auth_service.dart';
import '../models/user_model.dart' as app_models;

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  
  app_models.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  app_models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  
  // Constructor
  AuthProvider() {
    _initializeAuthListener();
  }
  
  // Initialize authentication state listener
  void _initializeAuthListener() {
    _authService.authStateChanges.listen((firebase_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        try {
          _currentUser = await _authService.getUserProfile(firebaseUser.uid);
          notifyListeners();
        } catch (e) {
          _setError('Kullanıcı profili alınamadı: $e');
        }
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }
  
  // Sign up with email and password
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
      
      _setError('Kayıt işlemi başarısız oldu');
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
      
      _setError('Giriş işlemi başarısız oldu');
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();
      
      final user = await _authService.signInWithGoogle();
      
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
      
      _setError('Google ile giriş başarısız oldu');
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Çıkış yapılırken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update user profile
  Future<bool> updateUserProfile(app_models.User user) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.updateUserProfile(user);
      _currentUser = user;
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update profile image
  Future<bool> updateProfileImage(String imageUrl) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (_currentUser != null) {
        await _authService.updateProfileImageUrl(_currentUser!.id, imageUrl);
        _currentUser = _currentUser!.copyWith(profileImageUrl: imageUrl);
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete account
  Future<bool> deleteAccount(String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.deleteAccount(password);
      _currentUser = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // Clear error message
  void clearError() {
    _clearError();
  }
  
  // Private methods
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
    if (!_isLoading) {
      notifyListeners();
    }
  }
}