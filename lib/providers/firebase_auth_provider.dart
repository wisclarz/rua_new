import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart' as app_models;
import '../services/firebase_auth_service.dart';
import '../services/google_sign_in_helper.dart';
import 'auth_provider_interface.dart';

class FirebaseAuthProvider extends AuthProviderInterface {
  FirebaseAuthService? _authService;
  
  app_models.User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isInitialized = false;
  
  // For phone authentication
  String? _verificationId;
  bool _isVerifyingPhone = false;
  
  // Getters
  app_models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  String? get verificationId => _verificationId;
  bool get isVerifyingPhone => _isVerifyingPhone;
  bool get isInitialized => _isInitialized;
  
  // Constructor
  FirebaseAuthProvider() {
    _initializeAsync();
  }
  
  Future<void> _initializeAsync() async {
    try {
      _setLoading(true);
      
      // Wait for Firebase to be initialized before creating the auth service
      await _waitForFirebaseInitialization();
      
      // Now initialize the auth service
      _authService = FirebaseAuthService();
      _isInitialized = true;
      
      // Listen to auth state changes
      _authService!.authStateChanges.listen((firebase_auth.User? firebaseUser) async {
        print('🔄 Auth state changed: ${firebaseUser?.uid ?? 'null'}');
        
        if (firebaseUser != null) {
          try {
            print('👤 Getting user profile for: ${firebaseUser.uid}');
            final user = await _authService!.getUserProfile(firebaseUser.uid);
            
            if (user != null) {
              print('✅ User profile loaded: ${user.name}');
              _currentUser = user;
            } else {
              print('⚠️ User profile not found, creating new one');
              // Create a new user profile if it doesn't exist
              final newUser = app_models.User(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? '',
                phoneNumber: firebaseUser.phoneNumber,
                name: firebaseUser.displayName ?? 'Firebase User',
                profileImageUrl: firebaseUser.photoURL,
                createdAt: DateTime.now(),
                lastLoginAt: DateTime.now(),
                preferences: app_models.UserPreferences.defaultPreferences(),
                isEmailVerified: firebaseUser.emailVerified,
              );
              
              await _authService!.updateUserProfile(newUser);
              _currentUser = newUser;
              print('✅ New user profile created: ${newUser.name}');
            }
          } catch (e) {
            print('❌ Error loading user profile: $e');
            _setError('Kullanıcı profili yüklenirken hata: $e');
            _currentUser = null;
          }
        } else {
          print('🚪 User signed out');
          _currentUser = null;
        }
        
        if (_isLoading) {
          _setLoading(false);
        } else {
          notifyListeners();
        }
      });
      
    } catch (e) {
      _setError('Başlatma hatası: $e');
      _currentUser = null;
      _setLoading(false);
    }
  }
  
  Future<void> _waitForFirebaseInitialization() async {
    // Wait for Firebase to be initialized with retries
    int attempts = 0;
    const maxAttempts = 10;
    
    while (attempts < maxAttempts) {
      try {
        // Try to access Firebase - this will throw if not initialized
        firebase_auth.FirebaseAuth.instance;
        return; // Success, Firebase is initialized
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          throw Exception('Firebase initialization timeout after $maxAttempts attempts');
        }
        // Wait 100ms before retrying
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }
  
  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    if (_authService == null) {
      _setError('Firebase henüz başlatılmadı');
      return false;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      final user = await _authService!.signInWithGoogle();
      if (user != null) {
        _currentUser = user;
        print('✅ Google Sign-In successful in provider: ${user.name}');
        return true;
      }
      
      // If sign-in returns null but Firebase user exists, try recovery
      final firebaseUser = _authService!.currentUser;
      if (firebaseUser != null) {
        print('🔄 Sign-in returned null but Firebase user exists, attempting recovery...');
        try {
          final recoveredUser = await _authService!.getUserProfile(firebaseUser.uid);
          if (recoveredUser != null) {
            _currentUser = recoveredUser;
            print('✅ Successfully recovered user in provider: ${recoveredUser.name}');
            return true;
          }
        } catch (e) {
          print('❌ Recovery failed in provider: $e');
        }
      }
      
      return false;
    } catch (e) {
      print('🔴 Google Sign-In error in provider: $e');
      
      // Try recovery if PigeonUserDetails error and Firebase user exists
      if (GoogleSignInHelper.isPigeonUserDetailsError(e)) {
        final firebaseUser = _authService!.currentUser;
        if (firebaseUser != null) {
          print('🔄 Attempting recovery from PigeonUserDetails error...');
          try {
            final recoveredUser = await _authService!.getUserProfile(firebaseUser.uid);
            if (recoveredUser != null) {
              _currentUser = recoveredUser;
              print('✅ Successfully recovered from error: ${recoveredUser.name}');
              return true;
            }
          } catch (recoveryError) {
            print('❌ Recovery attempt failed: $recoveryError');
          }
        }
      }
      
      // Use helper to get appropriate error message
      _setError(GoogleSignInHelper.getErrorMessage(e));
      
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Send phone verification code
  Future<bool> sendPhoneVerificationCode(String phoneNumber) async {
    if (_authService == null) {
      _setError('Firebase henüz başlatılmadı');
      return false;
    }
    
    try {
      _setLoading(true);
      _clearError();
      _isVerifyingPhone = true;
      
      await _authService!.sendPhoneVerificationCode(
        phoneNumber: phoneNumber,
        onCodeSent: (String verificationId) {
          _verificationId = verificationId;
          _setLoading(false);
          notifyListeners();
        },
        onVerificationFailed: (firebase_auth.FirebaseAuthException e) {
          _setError(_getErrorMessage(e));
          _setLoading(false);
          _isVerifyingPhone = false;
          notifyListeners();
        },
        onAutoVerificationCompleted: () {
          // Auto verification completed - this will be handled by auth state listener
          _setLoading(false);
          _isVerifyingPhone = false;
          notifyListeners();
        },
      );
      
      return true;
    } catch (e) {
      _setError('SMS gönderilirken hata: $e');
      _setLoading(false);
      _isVerifyingPhone = false;
      return false;
    }
  }
  
  // Verify phone code
  Future<bool> verifyPhoneCode({
    required String smsCode,
    String? userName,
  }) async {
    if (_authService == null) {
      _setError('Firebase henüz başlatılmadı');
      return false;
    }
    
    if (_verificationId == null) {
      _setError('Doğrulama ID\'si bulunamadı. Lütfen tekrar deneyin.');
      return false;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      final user = await _authService!.verifyPhoneCode(
        verificationId: _verificationId!,
        smsCode: smsCode,
        userName: userName,
      );
      
      if (user != null) {
        _currentUser = user;
        _verificationId = null;
        _isVerifyingPhone = false;
        return true;
      }
      
      return false;
    } catch (e) {
      _setError('Doğrulama kodu hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    if (_authService == null) {
      _setError('Firebase henüz başlatılmadı');
      return;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      await _authService!.signOut();
      _currentUser = null;
      _verificationId = null;
      _isVerifyingPhone = false;
    } catch (e) {
      _setError('Çıkış yapılırken hata: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Update user profile
  Future<bool> updateUserProfile(app_models.User user) async {
    if (_authService == null) {
      _setError('Firebase henüz başlatılmadı');
      return false;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      await _authService!.updateUserProfile(user);
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
    if (_authService == null) {
      _setError('Firebase henüz başlatılmadı');
      return false;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      if (_currentUser != null) {
        await _authService!.updateProfileImageUrl(_currentUser!.id, imageUrl);
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
  Future<bool> deleteAccount() async {
    if (_authService == null) {
      _setError('Firebase henüz başlatılmadı');
      return false;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      if (_currentUser != null) {
        // For phone auth users, we can't verify with password
        // You might want to implement re-authentication differently
        await _authService!.deleteAccount('');
        _currentUser = null;
        _verificationId = null;
        _isVerifyingPhone = false;
        return true;
      }
      
      return false;
    } catch (e) {
      _setError('Hesap silme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Send email verification (not applicable for phone auth)
  Future<void> sendEmailVerification() async {
    if (_authService == null) {
      _setError('Firebase henüz başlatılmadı');
      return;
    }
    
    try {
      await _authService!.sendEmailVerification();
    } catch (e) {
      _setError('E-posta doğrulama gönderme hatası: $e');
    }
  }
  
  // Reset phone verification (allow user to enter new phone number)
  void resetPhoneVerification() {
    _verificationId = null;
    _isVerifyingPhone = false;
    _clearError();
    notifyListeners();
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
  
  String _getErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Geçersiz telefon numarası formatı.';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen daha sonra tekrar deneyin.';
      case 'quota-exceeded':
        return 'SMS kotası aşıldı. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu bölge için SMS gönderimi etkinleştirilmemiş. Firebase Console\'dan Türkiye bölgesini etkinleştirin.';
      case 'app-not-authorized':
        return 'Uygulama yetkili değil. SHA-1 fingerprint Firebase Console\'a eklenmelidir.';
      case 'captcha-check-failed':
        return 'reCAPTCHA doğrulaması başarısız. Lütfen tekrar deneyin.';
      case 'web-context-cancelled':
        return 'İşlem iptal edildi. Lütfen tekrar deneyin.';
      default:
        String message = e.message ?? 'Bir hata oluştu.';
        
        // Check for specific error messages
        if (message.contains('SMS unable to be sent until this region enabled')) {
          return 'Türkiye bölgesi Firebase Console\'da etkinleştirilmemiş. Test numarası kullanın veya bölgeyi etkinleştirin.';
        } else if (message.contains('No Recaptcha Enterprise siteKey')) {
          return 'reCAPTCHA yapılandırması eksik. Firebase Console\'dan reCAPTCHA Enterprise etkinleştirin.';
        } else if (message.contains('invalid-app-credential')) {
          return 'Uygulama kimlik bilgileri geçersiz. google-services.json dosyasını kontrol edin.';
        }
        
        return message;
    }
  }
}
