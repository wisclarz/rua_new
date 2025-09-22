import 'package:flutter/material.dart';
import '../models/user_model.dart' as app_models;

// Mock implementation for development
class AuthProvider with ChangeNotifier {
  app_models.User? _currentUser;
  bool _isLoading = true; // Başlangıçta loading true olmalı
  String? _errorMessage;
  
  // Mock users for testing
  final List<Map<String, String>> _mockUsers = [
    {'email': 'test@example.com', 'password': '123456', 'name': 'Test User'},
    {'email': 'admin@ruadream.com', 'password': 'admin123', 'name': 'Admin User'},
  ];
  
  // Getters
  app_models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  
  // Constructor
  AuthProvider() {
    // Async initialization
    _initializeAsync();
  }
  
  Future<void> _initializeAsync() async {
    try {
      _setLoading(true);
      
      // Simulate loading delay
      await Future.delayed(const Duration(seconds: 1));
      
      // For development, automatically create a mock user
      _currentUser = app_models.User(
        id: 'mock_user_123',
        email: 'demo@ruadream.com',
        name: 'Demo Kullanıcı',
        profileImageUrl: null,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLoginAt: DateTime.now(),
        preferences: app_models.UserPreferences.defaultPreferences(),
        stats: app_models.UserStats(
          totalDreams: 15,
          totalAnalyses: 12,
          streakDays: 7,
          currentStreak: 3,
          lastDreamDate: DateTime.now().subtract(const Duration(days: 1)),
          favoriteCount: 5,
          moodCounts: {'mutlu': 8, 'üzgün': 3, 'kaygılı': 4},
          tagCounts: {'renkli': 6, 'uçmak': 4, 'su': 3, 'aile': 5},
          averageRating: 4.2,
          totalRecordingMinutes: 45,
        ),
        isEmailVerified: true,
      );
      
    } catch (e) {
      _setError('Başlatma hatası: $e');
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign up with email and password (Mock)
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if email already exists
      final existingUser = _mockUsers.where((user) => user['email'] == email);
      if (existingUser.isNotEmpty) {
        _setError('Bu e-posta adresi zaten kullanımda');
        return false;
      }
      
      // Add new mock user
      _mockUsers.add({
        'email': email,
        'password': password,
        'name': name,
      });
      
      // Create user profile
      _currentUser = app_models.User(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name,
        createdAt: DateTime.now(),
        preferences: app_models.UserPreferences.defaultPreferences(),
        isEmailVerified: false,
      );
      
      return true;
    } catch (e) {
      _setError('Kayıt işlemi başarısız: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign in with email and password (Mock)
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Find user in mock data - firstOrNull yerine where().isEmpty kontrolü
      final matchingUsers = _mockUsers.where((user) => 
          user['email'] == email && user['password'] == password
      );
      
      if (matchingUsers.isEmpty) {
        _setError('Hatalı e-posta veya şifre');
        return false;
      }
      
      final mockUser = matchingUsers.first;
      
      // Create user session
      _currentUser = app_models.User(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: mockUser['name'] ?? 'Unknown User',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        lastLoginAt: DateTime.now(),
        preferences: app_models.UserPreferences.defaultPreferences(),
        stats: app_models.UserStats(
          totalDreams: 8,
          totalAnalyses: 6,
          streakDays: 3,
          currentStreak: 1,
        ),
        isEmailVerified: true,
      );
      
      return true;
    } catch (e) {
      _setError('Giriş işlemi başarısız: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign in with Google (Mock)
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock Google user
      _currentUser = app_models.User(
        id: 'google_mock_user',
        email: 'google.user@gmail.com',
        name: 'Google Kullanıcı',
        profileImageUrl: 'https://via.placeholder.com/100',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        lastLoginAt: DateTime.now(),
        preferences: app_models.UserPreferences.defaultPreferences(),
        stats: app_models.UserStats(
          totalDreams: 3,
          totalAnalyses: 2,
          streakDays: 1,
        ),
        isEmailVerified: true,
      );
      
      return true;
    } catch (e) {
      _setError('Google ile giriş başarısız: $e');
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
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _currentUser = null;
    } catch (e) {
      _setError('Çıkış yapılırken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Reset password (Mock)
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if email exists
      final userExists = _mockUsers.any((user) => user['email'] == email);
      if (!userExists) {
        _setError('Bu e-posta adresine kayıtlı kullanıcı bulunamadı');
        return false;
      }
      
      // In real implementation, send reset email
      return true;
    } catch (e) {
      _setError('Şifre sıfırlama hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Change password (Mock)
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      await Future.delayed(const Duration(seconds: 1));
      
      if (_currentUser == null) {
        _setError('Kullanıcı oturumu bulunamadı');
        return false;
      }
      
      // In real implementation, verify current password and update
      return true;
    } catch (e) {
      _setError('Şifre değiştirme hatası: $e');
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
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      _currentUser = user.copyWith(updatedAt: DateTime.now());
      
      return true;
    } catch (e) {
      _setError('Profil güncelleme hatası: $e');
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
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          profileImageUrl: imageUrl,
          updatedAt: DateTime.now(),
        );
        return true;
      }
      
      return false;
    } catch (e) {
      _setError('Profil resmi güncelleme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete account (Mock)
  Future<bool> deleteAccount(String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      await Future.delayed(const Duration(seconds: 1));
      
      // In real implementation, verify password and delete account
      _currentUser = null;
      
      return true;
    } catch (e) {
      _setError('Hesap silme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Send email verification (Mock)
  Future<void> sendEmailVerification() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      // In real implementation, send verification email
    } catch (e) {
      _setError('E-posta doğrulama gönderme hatası: $e');
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