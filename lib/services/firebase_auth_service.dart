import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart' as app_models;
import 'google_sign_in_helper.dart';

class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
    // Force account selection to avoid cached credential issues
    forceCodeForRefreshToken: true,
  );

  // Current user stream
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<app_models.User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Send email verification
        await credential.user!.sendEmailVerification();

        // Create user profile in Firestore
        final user = app_models.User(
          id: credential.user!.uid,
          email: email,
          name: name,
          createdAt: DateTime.now(),
          preferences: app_models.UserPreferences.defaultPreferences(),
        );

        await _createUserProfile(user);
        return user;
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  // Sign in with email and password
  Future<app_models.User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update last login time
        await _updateLastLoginTime(credential.user!.uid);
        return await getUserProfile(credential.user!.uid);
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// ✨ Sessiz Google Sign-In - Kullanıcı daha önce giriş yaptıysa otomatik giriş yapar
  /// Onay ekranı göstermez, sadece cache'deki kullanıcıyı kontrol eder
  Future<app_models.User?> signInSilently() async {
    try {
      print('🤫 Attempting silent Google Sign-In...');
      
      // Google Sign-In'den sessizce kullanıcı al (UI göstermez)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      if (googleUser == null) {
        print('ℹ️ No cached Google user found');
        return null;
      }
      
      print('✅ Found cached Google user: ${googleUser.email}');
      
      // Firebase'de zaten giriş yapmış mı kontrol et
      final currentFirebaseUser = _auth.currentUser;
      if (currentFirebaseUser != null && currentFirebaseUser.email == googleUser.email) {
        print('✅ Firebase user already signed in: ${currentFirebaseUser.uid}');
        // Profili al ve döndür
        return await getUserProfile(currentFirebaseUser.uid);
      }
      
      // Google authentication tokenlarını al
      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await googleUser.authentication;
        
        // Tokenları doğrula
        if (!GoogleSignInHelper.validateGoogleAuthTokens(googleAuth)) {
          print('⚠️ Invalid Google auth tokens in silent sign-in');
          return null;
        }
      } catch (e) {
        print('⚠️ Failed to get Google auth tokens: $e');
        return null;
      }
      
      // Firebase credential oluştur
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase'e giriş yap
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;
        print('✅ Silent Firebase authentication successful: ${firebaseUser.uid}');
        
        // Kullanıcı profilini al veya oluştur
        app_models.User? user = await getUserProfile(firebaseUser.uid);
        
        if (user == null) {
          // Yeni kullanıcı profili oluştur
          user = app_models.User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? googleUser.email,
            name: firebaseUser.displayName ?? googleUser.displayName ?? 'Google User',
            profileImageUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            preferences: app_models.UserPreferences.defaultPreferences(),
            isEmailVerified: firebaseUser.emailVerified,
          );
          
          await _createUserProfile(user);
          print('✅ New user profile created for silent sign-in: ${user.name}');
        } else {
          // Mevcut kullanıcı, son giriş zamanını güncelle
          await _updateLastLoginTime(firebaseUser.uid);
          print('✅ Last login time updated for: ${user.name}');
        }
        
        return user;
      }
      
      return null;
      
    } catch (e) {
      print('ℹ️ Silent sign-in failed (this is normal): $e');
      // Sessiz giriş başarısız olması normaldir, hata fırlatmıyoruz
      return null;
    }
  }

  // Sign in with Google
  Future<app_models.User?> signInWithGoogle() async {
    try {
      // First clear any existing Google Sign-In session
      await GoogleSignInHelper.safeClearGoogleSignIn(_googleSignIn);
      
      GoogleSignInAccount? googleUser;
      GoogleSignInAuthentication? googleAuth;
      
      // Try to get Google Sign-In account with multiple attempts
      int attempts = 0;
      const maxAttempts = 3;
      
      while (attempts < maxAttempts) {
        try {
          googleUser = await _googleSignIn.signIn();
          if (googleUser == null) return null; // User cancelled

          // Try to get authentication tokens
          googleAuth = await googleUser.authentication;
          
          // Validate tokens using helper
          if (GoogleSignInHelper.validateGoogleAuthTokens(googleAuth)) {
            break; // Success, exit the retry loop
          } else {
            throw Exception('Invalid tokens received');
          }
        } catch (e) {
          attempts++;
          print('🔄 Google Sign-In attempt $attempts failed: $e');
          
          if (GoogleSignInHelper.isPigeonUserDetailsError(e)) {
            print('⚠️ PigeonUserDetails error detected, retrying...');
            // Clear and retry
            await GoogleSignInHelper.safeClearGoogleSignIn(_googleSignIn);
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          
          if (attempts >= maxAttempts) {
            rethrow;
          }
          
          // Wait before retry
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
      
      // If we still don't have valid auth, throw error
      if (googleAuth == null || !GoogleSignInHelper.validateGoogleAuthTokens(googleAuth)) {
        throw Exception('Failed to get valid Google authentication after $maxAttempts attempts');
      }
      
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;
        print('✅ Firebase authentication successful for: ${firebaseUser.uid}');
        
        // Check if user profile exists, create if not
        app_models.User? user = await getUserProfile(firebaseUser.uid);
        
        if (user == null) {
          // Create new user profile
          user = app_models.User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? 'Google User',
            profileImageUrl: firebaseUser.photoURL,
            createdAt: DateTime.now(),
            preferences: app_models.UserPreferences.defaultPreferences(),
          );
          
          await _createUserProfile(user);
          print('✅ New user profile created: ${user.name}');
        } else {
          // Update last login time
          await _updateLastLoginTime(firebaseUser.uid);
          print('✅ User login time updated: ${user.name}');
        }
        
        return user;
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('🔥 Firebase Auth Exception in Google Sign-In: ${e.code} - ${e.message}');
      throw Exception(_handleAuthException(e));
    } catch (e) {
      print('❌ Error in Google Sign-In: $e');
      
      // Special handling for PigeonUserDetails error
      if (GoogleSignInHelper.isPigeonUserDetailsError(e)) {
        // Check if user is already authenticated in Firebase
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          print('🔄 PigeonUserDetails error but Firebase user exists, attempting recovery...');
          
          try {
            final user = await getUserProfile(currentUser.uid);
            if (user != null) {
              print('✅ Successfully recovered user session: ${user.name}');
              return user;
            }
          } catch (recoveryError) {
            print('❌ Recovery attempt failed: $recoveryError');
          }
        }
      }
      
      // Use helper to get appropriate error message
      throw Exception(GoogleSignInHelper.getErrorMessage(e));
    }
  }

  // Phone authentication - Send verification code
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(firebase_auth.FirebaseAuthException) onVerificationFailed,
    Function()? onAutoVerificationCompleted,
  }) async {
    try {
      print('📱 Starting phone verification for: $phoneNumber');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60), // Timeout süresi eklendi
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
          print('✅ Phone verification completed automatically');
          // Auto verification completed (Android only)
          if (onAutoVerificationCompleted != null) {
            onAutoVerificationCompleted();
          }
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          print('❌ Phone verification failed: ${e.code} - ${e.message}');
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          print('📨 SMS code sent, verification ID: $verificationId');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏰ Auto retrieval timeout for: $verificationId');
        },
      );
    } catch (e) {
      print('💥 Exception in sendPhoneVerificationCode: $e');
      throw Exception('SMS gönderilirken hata oluştu: $e');
    }
  }

  // Phone authentication - Verify SMS code
  Future<app_models.User?> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
    String? userName,
  }) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;
        
        // Check if user profile exists, create if not
        app_models.User? user = await getUserProfile(firebaseUser.uid);
        
        if (user == null) {
          // Create new user profile
          user = app_models.User(
            id: firebaseUser.uid,
            email: '', // Phone auth doesn't require email
            phoneNumber: firebaseUser.phoneNumber,
            name: userName ?? 'Telefon Kullanıcısı',
            createdAt: DateTime.now(),
            preferences: app_models.UserPreferences.defaultPreferences(),
          );
          
          await _createUserProfile(user);
        } else {
          // Update last login time
          await _updateLastLoginTime(firebaseUser.uid);
        }
        
        return user;
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Telefon doğrulaması yapılırken hata oluştu: $e');
    }
  }

  /// ✨ Çıkış yap - Hem Firebase hem Google'dan tamamen çıkış yapar
  Future<void> signOut() async {
    try {
      print('🚪 Starting sign out process...');
      
      // Google Sign-In'den çıkış yap (önemli: silent sign-in'i de temizler)
      try {
        await _googleSignIn.signOut();
        print('✅ Google Sign-In signed out');
      } catch (e) {
        print('⚠️ Google sign out warning: $e');
        // Google sign out hatası kritik değil, devam et
      }
      
      // Google Sign-In disconnect (tüm izinleri iptal et)
      try {
        await _googleSignIn.disconnect();
        print('✅ Google Sign-In disconnected');
      } catch (e) {
        print('⚠️ Google disconnect warning: $e');
        // Disconnect hatası normaldir (zaten bağlantı kesilmişse)
      }
      
      // Firebase'den çıkış yap
      await _auth.signOut();
      print('✅ Firebase sign out completed');
      
      print('✅ Sign out process completed successfully');
      
    } catch (e) {
      print('❌ Error during sign out: $e');
      throw Exception('Çıkış yapılırken hata oluştu: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Şifre sıfırlama e-postası gönderilirken hata oluştu: $e');
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Re-authenticate user
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Şifre değiştirilirken hata oluştu: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Re-authenticate user
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Delete user data from Firestore
      await _deleteUserData(user.uid);
      
      // Delete Firebase Auth account
      await user.delete();
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Hesap silinirken hata oluştu: $e');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('E-posta doğrulama gönderilirken hata oluştu: $e');
    }
  }

  // Get user profile from Firestore
  Future<app_models.User?> getUserProfile(String userId) async {
    try {
      print('📄 Getting user profile from Firestore for: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        print('✅ User document found in Firestore');
        return app_models.User.fromJson({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      
      print('⚠️ User document not found in Firestore');
      return null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      throw Exception('Kullanıcı profili alınırken hata oluştu: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(app_models.User user) async {
    try {
      print('💾 Saving user profile to Firestore: ${user.id}');
      await _firestore.collection('users').doc(user.id).set(user.toJson(), SetOptions(merge: true));
      print('✅ User profile saved successfully');
    } catch (e) {
      print('❌ Error saving user profile: $e');
      throw Exception('Profil güncellenirken hata oluştu: $e');
    }
  }

  // Update user profile image URL
  Future<void> updateProfileImageUrl(String userId, String imageUrl) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': imageUrl,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Profil resmi güncellenirken hata oluştu: $e');
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(app_models.User user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  // Update last login time
  Future<void> _updateLastLoginTime(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Delete user data from Firestore
  Future<void> _deleteUserData(String userId) async {
    final batch = _firestore.batch();
    
    try {
      // Delete user document
      batch.delete(_firestore.collection('users').doc(userId));
      
      // Delete user's dreams
      final dreamsQuery = await _firestore
          .collection('dreams')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in dreamsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user's analyses
      final analysesQuery = await _firestore
          .collection('dream_analyses')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in analysesQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user stats
      batch.delete(_firestore.collection('user_stats').doc(userId));
      
      // Delete user preferences
      batch.delete(_firestore.collection('user_preferences').doc(userId));
      
      await batch.commit();
    } catch (e) {
      throw Exception('Kullanıcı verisi silinirken hata oluştu: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      case 'user-not-found':
        return 'Bu e-posta adresine kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda mevcut değil.';
      case 'requires-recent-login':
        return 'Bu işlem için yeniden giriş yapmanız gerekiyor.';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgileri.';
      case 'account-exists-with-different-credential':
        return 'Bu e-posta adresi farklı bir giriş yöntemi ile kayıtlı.';
      case 'credential-already-in-use':
        return 'Bu kimlik bilgisi zaten başka bir hesap tarafından kullanılıyor.';
      // Phone authentication specific errors
      case 'invalid-phone-number':
        return 'Geçersiz telefon numarası formatı.';
      case 'invalid-verification-code':
        return 'Geçersiz doğrulama kodu.';
      case 'invalid-verification-id':
        return 'Geçersiz doğrulama ID\'si.';
      case 'missing-verification-code':
        return 'Doğrulama kodu eksik.';
      case 'missing-verification-id':
        return 'Doğrulama ID\'si eksik.';
      case 'quota-exceeded':
        return 'SMS kotası aşıldı. Lütfen daha sonra tekrar deneyin.';
      case 'session-expired':
        return 'Doğrulama oturumu süresi doldu. Lütfen tekrar deneyin.';
      default:
        return 'Kimlik doğrulama hatası: ${e.message ?? e.code}';
    }
  }
}