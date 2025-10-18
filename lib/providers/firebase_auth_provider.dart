import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart' as app_models;
import '../models/subscription_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/google_sign_in_helper.dart';
import '../services/cache_service.dart';
import 'auth_provider_interface.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class FirebaseAuthProvider extends ChangeNotifier implements AuthProviderInterface {
  FirebaseAuthService? _authService;
  
  app_models.User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isInitialized = false;
  
  // For phone authentication
  String? _verificationId;
  bool _isVerifyingPhone = false;
  
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
  String? get verificationId => _verificationId;
  @override
  bool get isVerifyingPhone => _isVerifyingPhone;
  @override
  bool get isInitialized => _isInitialized;
  
  // Constructor - lightweight
  FirebaseAuthProvider() {
    debugPrint('🏗️ FirebaseAuthProvider constructor started');
    _initializeAsync();
  }
  
  Future<void> _initializeAsync() async {
    try {
      debugPrint('⏳ Starting async initialization...');
      
      // Wait for Firebase with timeout
      await _waitForFirebaseInitialization();
      
      // Create auth service
      _authService = FirebaseAuthService();
      _isInitialized = true;
      debugPrint('✅ Auth service initialized');
      
      // Setup auth listener
      _setupAuthListener();
      
      // ✨ AUTO SILENT SIGN-IN CHECK
      await _attemptSilentSignIn();
      
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
      _setError('Başlatma hatası: $e');
      _isInitialized = true;
      _setLoading(false);
    }
  }
  
  /// ✨ Check for existing Firebase session ONLY (no Google Sign-In cache)
  Future<void> _attemptSilentSignIn() async {
    try {
      debugPrint('🔍 Checking for existing Firebase authenticated session...');

      // ONLY check Firebase session - NO Google Sign-In cache check
      // This prevents automatic sign-in for deleted users
      final firebaseUser = _authService!.currentUser;

      if (firebaseUser != null) {
        debugPrint('✅ Firebase session exists: ${firebaseUser.uid}');
        // Auth listener will load user profile
        return;
      }

      // No Firebase session - user must sign in manually
      debugPrint('ℹ️ No Firebase session found');
      debugPrint('ℹ️ User will need to sign in manually');

      // 🗑️ Clear cache since no valid session exists
      await CacheService.instance.clear();
      debugPrint('🗑️ Cache cleared (no Firebase session)');

    } catch (e) {
      debugPrint('ℹ️ Session check failed: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  void _setupAuthListener() {
    String? _lastAuthUserId;

    _authService!.authStateChanges.listen(
      (firebase_auth.User? firebaseUser) async {
        final currentUserId = firebaseUser?.uid;

        // Prevent duplicate events
        if (_lastAuthUserId == currentUserId) {
          debugPrint('⏭️ Skipping duplicate auth event for: ${currentUserId ?? "signed out"}');
          return;
        }

        _lastAuthUserId = currentUserId;
        debugPrint('🔄 Auth state changed: ${currentUserId ?? "signed out"}');

        if (firebaseUser != null) {
          await _handleUserSignedIn(firebaseUser);
        } else {
          _handleUserSignedOut();
        }
      },
      onError: (error) {
        debugPrint('❌ Auth listener error: $error');
        _setError('Auth hatası: $error');
      },
    );
  }
  
  Future<void> _handleUserSignedIn(firebase_auth.User firebaseUser) async {
    try {
      debugPrint('👤 Getting user profile for: ${firebaseUser.uid}');
      final user = await _authService!.getUserProfile(firebaseUser.uid);

      if (user != null) {
        debugPrint('✅ User profile loaded: ${user.name}');
        _currentUser = user;
      } else {
        // 🆕 Profile not found - create NEW user (deleted account or first-time user)
        debugPrint('⚠️ User profile not found in Firestore');
        debugPrint('🆕 Creating new user profile and subscription...');

        // Clear old cache data
        await CacheService.instance.clear();

        // Create new user profile
        final newUser = app_models.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          phoneNumber: firebaseUser.phoneNumber,
          name: firebaseUser.displayName ?? 'Kullanıcı',
          profileImageUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          preferences: app_models.UserPreferences.defaultPreferences(),
          isEmailVerified: firebaseUser.emailVerified,
        );

        await _authService!.updateUserProfile(newUser);

        // 🆕 Create FREE subscription for new user
        await _createFreeSubscription(firebaseUser.uid);

        _currentUser = newUser;
        debugPrint('✅ New user profile and subscription created: ${newUser.name}');
      }

      if (_isLoading) {
        _setLoading(false);
      }
      _safeNotify();

    } catch (e) {
      debugPrint('❌ Error loading user profile: $e');
      _setError('Kullanıcı profili yüklenirken hata: $e');
      _currentUser = null;

      if (_isLoading) {
        _setLoading(false);
      }
      _safeNotify();
    }
  }
  
  void _handleUserSignedOut() {
    debugPrint('🚪 User signed out');

    // 🗑️ Clear cache for the signed-out user
    if (_currentUser != null) {
      final userId = _currentUser!.id; // Save userId before clearing
      Future.microtask(() async {
        await CacheService.instance.clearUserCache(userId);
        debugPrint('🗑️ Cache cleared for signed-out user: $userId');
      });
    }

    _currentUser = null;

    if (_isLoading) {
      _setLoading(false);
    }
    _safeNotify();
  }
  
  Future<void> _waitForFirebaseInitialization() async {
    int attempts = 0;
    const maxAttempts = 10;
    
    while (attempts < maxAttempts) {
      try {
        firebase_auth.FirebaseAuth.instance;
        debugPrint('✅ Firebase ready after $attempts attempts');
        return;
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          throw Exception('Firebase initialization timeout after $maxAttempts attempts');
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }
  
  /// ✨ Google ile giriş - Kullanıcı giriş butonuna bastığında
  @override
  Future<bool> signInWithGoogle() async {
    if (_authService == null) {
      _setError('Firebase henüz başlatılmadı');
      return false;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      debugPrint('🔐 User initiated Google Sign-In...');
      
      // signInWithGoogle içinde zaten silentSignIn önce deneniyor
      // Eğer cache'de hesap varsa direkt giriş yapar
      // Yoksa hesap seçme ekranı gösterir
      final user = await _authService!.signInWithGoogle();
      
      if (user != null) {
        _currentUser = user;
        debugPrint('✅ Sign-in completed: ${user.name}');
        return true;
      }
      
      // 3. If sign-in returns null but Firebase user exists, try recovery
      final firebaseUser = _authService!.currentUser;
      if (firebaseUser != null) {
        debugPrint('🔄 Sign-in returned null but Firebase user exists, attempting recovery...');
        try {
          final recoveredUser = await _authService!.getUserProfile(firebaseUser.uid);
          if (recoveredUser != null) {
            _currentUser = recoveredUser;
            debugPrint('✅ Successfully recovered user: ${recoveredUser.name}');
            return true;
          }
        } catch (e) {
          debugPrint('❌ Recovery failed: $e');
        }
      }
      
      debugPrint('❌ Google Sign-In returned no user');
      return false;
      
    } catch (e) {
      debugPrint('🔴 Google Sign-In error: $e');
      
      // Try recovery if PigeonUserDetails error and Firebase user exists
      if (GoogleSignInHelper.isPigeonUserDetailsError(e)) {
        final firebaseUser = _authService!.currentUser;
        if (firebaseUser != null) {
          debugPrint('🔄 Attempting recovery from PigeonUserDetails error...');
          try {
            final recoveredUser = await _authService!.getUserProfile(firebaseUser.uid);
            if (recoveredUser != null) {
              _currentUser = recoveredUser;
              debugPrint('✅ Successfully recovered from error: ${recoveredUser.name}');
              return true;
            }
          } catch (recoveryError) {
            debugPrint('❌ Recovery attempt failed: $recoveryError');
          }
        }
      }
      
      _setError(GoogleSignInHelper.getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Send phone verification code
  @override
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
          _safeNotify();
        },
        onVerificationFailed: (firebase_auth.FirebaseAuthException e) {
          _setError(_getErrorMessage(e));
          _setLoading(false);
          _isVerifyingPhone = false;
          _safeNotify();
        },
        onAutoVerificationCompleted: () {
          _setLoading(false);
          _isVerifyingPhone = false;
          _safeNotify();
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
  @override
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
  
  /// ✨ Çıkış yap - Google oturumunu da sonlandır
  @override
  Future<void> signOut() async {
    if (_authService == null) {
      _setError('Firebase henüz başlatılmadı');
      return;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      debugPrint('🚪 Signing out user...');
      
      // Firebase ve Google'dan çıkış yap
      await _authService!.signOut();
      
      _currentUser = null;
      _verificationId = null;
      _isVerifyingPhone = false;
      
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      _setError('Çıkış yapılırken hata: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Update user profile
  @override
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
  @override
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
  @override
  Future<bool> deleteAccount() async {
    if (_authService == null) {
      _setError('Firebase henüz başlatılmadı');
      return false;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      if (_currentUser != null) {
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
  
  // Send email verification
  @override
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
  
  // Reset phone verification
  @override
  void resetPhoneVerification() {
    _verificationId = null;
    _isVerifyingPhone = false;
    _clearError();
    _safeNotify();
  }
  
  // Clear error message
  @override
  void clearError() {
    _clearError();
  }
  
  // Helper methods - OPTIMIZED
  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotify();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    _safeNotify();
  }
  
  void _clearError() {
    _errorMessage = null;
    if (!_isLoading) {
      _safeNotify();
    }
  }
  
  // ⚡ Safe notify - prevents "called during build" errors
  void _safeNotify() {
    scheduleMicrotask(() {
      notifyListeners();
    });
  }
  
  /// 🆕 Create free subscription for new user
  Future<void> _createFreeSubscription(String userId) async {
    try {
      final subscription = Subscription(
        id: userId,
        userId: userId,
        plan: SubscriptionPlan.free,
        startDate: DateTime.now(),
        isActive: true,
        adWatchCount: 0,
      );

      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(userId)
          .set(subscription.toMap());

      debugPrint('✅ Free subscription created for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to create free subscription: $e');
      // Non-critical error, continue anyway
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