import '../models/user_model.dart' as app_models;
import 'auth_provider_interface.dart';

// Fallback mock auth provider for when Firebase is not available
class MockAuthProvider extends AuthProviderInterface {
  app_models.User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Getters
  @override
  app_models.User? get currentUser => _currentUser;
  @override
  bool get isLoading => _isLoading;
  @override
  String? get errorMessage => _errorMessage;
  @override
  bool get isAuthenticated => _currentUser != null;
  @override
  bool get isVerifyingPhone => false;
  @override
  String? get verificationId => null;
  @override
  bool get isInitialized => true;
  
  // Constructor
  MockAuthProvider() {
    _initializeAsync();
  }
  
  Future<void> _initializeAsync() async {
    try {
      _setLoading(true);
      
      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Start with no authenticated user
      _currentUser = null;
      
    } catch (e) {
      _setError('Başlatma hatası: $e');
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Mock Google sign in
  @override
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
  
  // Mock phone verification
  @override
  Future<bool> sendPhoneVerificationCode(String phoneNumber) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      return true;
    } catch (e) {
      _setError('SMS gönderilirken hata: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Mock phone code verification
  @override
  Future<bool> verifyPhoneCode({
    required String smsCode,
    String? userName,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Accept any 6-digit code
      if (smsCode.length == 6) {
        _currentUser = app_models.User(
          id: 'phone_mock_user',
          email: '',
          phoneNumber: '+905551234567',
          name: userName ?? 'Telefon Kullanıcısı',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          preferences: app_models.UserPreferences.defaultPreferences(),
          stats: app_models.UserStats(
            totalDreams: 1,
            totalAnalyses: 1,
            streakDays: 1,
          ),
          isEmailVerified: false,
        );
        return true;
      }
      
      _setError('Geçersiz doğrulama kodu');
      return false;
    } catch (e) {
      _setError('Doğrulama kodu hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign out
  @override
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
  
  // Update user profile
  @override
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
  @override
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
  
  // Delete account
  @override
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _clearError();
      
      await Future.delayed(const Duration(seconds: 1));
      
      _currentUser = null;
      
      return true;
    } catch (e) {
      _setError('Hesap silme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Send email verification (not applicable for mock)
  @override
  Future<void> sendEmailVerification() async {
    // Do nothing in mock
  }
  
  // Reset phone verification
  @override
  void resetPhoneVerification() {
    _clearError();
    notifyListeners();
  }
  
  // Clear error message
  @override
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