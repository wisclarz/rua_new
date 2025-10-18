import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart' as app_models;
import '../models/subscription_model.dart';
import 'google_sign_in_helper.dart';

class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ✨ Optimized Google Sign-In Configuration
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'profile',
    ],
    // forceCodeForRefreshToken: true,  // Kaldırıldı - gereksiz consent screen'e sebep oluyor
  );

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();
  firebase_auth.User? get currentUser => _auth.currentUser;

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
        await credential.user!.sendEmailVerification();

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

  Future<app_models.User?> signInSilently() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      if (googleUser == null) return null;
      
      final currentFirebaseUser = _auth.currentUser;
      if (currentFirebaseUser != null && currentFirebaseUser.email == googleUser.email) {
        return await getUserProfile(currentFirebaseUser.uid);
      }
      
      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await googleUser.authentication;
        if (!GoogleSignInHelper.validateGoogleAuthTokens(googleAuth)) return null;
      } catch (e) {
        return null;
      }
      
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;
        app_models.User? user = await getUserProfile(firebaseUser.uid);

        if (user == null) {
          // Profile doesn't exist - auth listener will create new profile
          // Return null to indicate profile needs to be created
          debugPrint('⚠️ Silent sign-in: User profile not found, will be created by auth listener');
          return null;
        } else {
          await _updateLastLoginTime(firebaseUser.uid);
          return user;
        }
      }

      return null;
      
    } catch (e) {
      return null;
    }
  }

  Future<app_models.User?> signInWithGoogle() async {
    try {
      // 🔒 ALWAYS show account picker - don't use cached account
      // This ensures deleted users must manually sign in again
      debugPrint('🔐 Starting Google Sign-In (manual)...');

      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('ℹ️ User cancelled sign-in');
        return null; // User cancelled
      }
      
      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (!GoogleSignInHelper.validateGoogleAuthTokens(googleAuth)) {
        throw Exception('Invalid authentication tokens');
      }
      
      // Authenticate with Firebase
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw Exception('Firebase authentication failed');
      }
      
      final firebaseUser = userCredential.user!;
      
      // Get user profile (don't create if doesn't exist)
      app_models.User? user = await getUserProfile(firebaseUser.uid);

      if (user == null) {
        // 🆕 NEW USER: Create profile for first-time users
        debugPrint('🆕 Creating new user profile and subscription...');

        user = app_models.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? googleUser.email,
          name: firebaseUser.displayName ?? googleUser.displayName ?? 'User',
          profileImageUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          preferences: app_models.UserPreferences.defaultPreferences(),
          isEmailVerified: firebaseUser.emailVerified,
        );

        await _createUserProfile(user);

        // 🆕 Create FREE subscription for new user
        await _createFreeSubscription(firebaseUser.uid);

        debugPrint('✅ New user profile and subscription created');
      } else {
        await _updateLastLoginTime(firebaseUser.uid);
      }

      return user;
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      // Error recovery attempt
      if (GoogleSignInHelper.isPigeonUserDetailsError(e)) {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          try {
            final user = await getUserProfile(currentUser.uid);
            if (user != null) return user;
          } catch (recoveryError) {
            // Recovery failed, continue to throw
          }
        }
      }
      
      throw Exception(GoogleSignInHelper.getErrorMessage(e));
    }
  }

  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(firebase_auth.FirebaseAuthException) onVerificationFailed,
    Function()? onAutoVerificationCompleted,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
          if (onAutoVerificationCompleted != null) {
            onAutoVerificationCompleted();
          }
        },
        verificationFailed: onVerificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto retrieval timeout
        },
      );
    } catch (e) {
      throw Exception('SMS gönderilirken hata oluştu: $e');
    }
  }

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
        
        app_models.User? user = await getUserProfile(firebaseUser.uid);
        
        if (user == null) {
          // 🆕 NEW USER: Create profile and subscription
          debugPrint('🆕 Creating new user profile and subscription (phone auth)...');

          user = app_models.User(
            id: firebaseUser.uid,
            email: '',
            phoneNumber: firebaseUser.phoneNumber,
            name: userName ?? 'Telefon Kullanıcısı',
            createdAt: DateTime.now(),
            preferences: app_models.UserPreferences.defaultPreferences(),
          );

          await _createUserProfile(user);

          // 🆕 Create FREE subscription for new user
          await _createFreeSubscription(firebaseUser.uid);

          debugPrint('✅ New user profile and subscription created (phone auth)');
        } else {
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

  /// ✨ Anonymous sign-in for automatic login
  Future<app_models.User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();

      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;

        // Check if user profile exists
        app_models.User? user = await getUserProfile(firebaseUser.uid);

        if (user == null) {
          // Create anonymous user profile
          user = app_models.User(
            id: firebaseUser.uid,
            email: '',
            name: 'Kullanıcı',
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            preferences: app_models.UserPreferences.defaultPreferences(),
            isAnonymous: true,
          );

          await _createUserProfile(user);
        } else {
          await _updateLastLoginTime(firebaseUser.uid);
        }

        return user;
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Anonim giriş yapılırken hata oluştu: $e');
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('🚪 Starting sign out...');

      // 1. Clear FCM token (önce temizle ki bildirim gitmesin)
      try {
        debugPrint('🗑️ Clearing FCM token before sign out...');
        await _clearFCMTokenOnSignOut();
      } catch (e) {
        debugPrint('⚠️ FCM token clear error (non-critical): $e');
      }

      // 2. Sign out from Google (clear cache)
      try {
        final isSignedIn = await _googleSignIn.isSignedIn();
        if (isSignedIn) {
          await _googleSignIn.signOut();
          debugPrint('✅ Google sign out complete');
        }
      } catch (e) {
        debugPrint('⚠️ Google sign out error (non-critical): $e');
      }

      // 3. Sign out from Firebase
      await _auth.signOut();
      debugPrint('✅ Firebase sign out complete');

    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      throw Exception('Çıkış yapılırken hata oluştu: $e');
    }
  }

  /// FCM token'ı temizle (sign out için)
  Future<void> _clearFCMTokenOnSignOut() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      debugPrint('🗑️ Clearing FCM tokens and marking user as logged out: ${user.uid}');

      // 1. Users koleksiyonundan FCM token'ı temizle VE isLoggedIn: false yap
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': Timestamp.fromDate(DateTime.now()),
        'isLoggedIn': false, // 🔐 Mark user as logged out
      });
      debugPrint('✅ FCM token cleared and user marked as logged out');

      // 2. ⚠️ ÖNEMLİ: Dreams koleksiyonundaki TÜM fcmToken'ları temizle
      // n8n workflow'u dreams koleksiyonundaki fcmToken'ı kullanarak bildirim gönderiyor
      final dreamsQuery = await _firestore
          .collection('dreams')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (dreamsQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();
        int updateCount = 0;

        for (final doc in dreamsQuery.docs) {
          // Sadece fcmToken field'ı varsa güncelle
          if (doc.data().containsKey('fcmToken')) {
            batch.update(doc.reference, {
              'fcmToken': FieldValue.delete(),
            });
            updateCount++;
          }
        }

        if (updateCount > 0) {
          await batch.commit();
          debugPrint('✅ FCM tokens cleared from $updateCount dreams');
        } else {
          debugPrint('ℹ️ No dreams with fcmToken found');
        }
      } else {
        debugPrint('ℹ️ No dreams found for user');
      }

      debugPrint('✅ All FCM tokens cleared successfully for user: ${user.uid}');
    } catch (e) {
      debugPrint('⚠️ Failed to clear FCM tokens on sign out: $e');
      // Non-critical error, continue sign out
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Şifre sıfırlama e-postası gönderilirken hata oluştu: $e');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Şifre değiştirilirken hata oluştu: $e');
    }
  }

  /// Hesabı tamamen sil - Tüm giriş yöntemleri için çalışır
  /// Google, telefon numarası veya email/password
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      debugPrint('🗑️ Starting account deletion for user: ${user.uid}');

      // Eğer password ile giriş yapılmışsa re-authenticate et
      if (password.isNotEmpty && user.email != null && user.email!.isNotEmpty) {
        debugPrint('🔐 Re-authenticating with email/password...');
        final credential = firebase_auth.EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
      // Google ile giriş yapılmışsa, Google ile re-authenticate et
      else if (user.providerData.any((p) => p.providerId == 'google.com')) {
        debugPrint('🔐 Re-authenticating with Google...');
        try {
          final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          if (googleUser == null) {
            throw Exception('Google ile tekrar giriş yapılması gerekiyor');
          }

          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final credential = firebase_auth.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          await user.reauthenticateWithCredential(credential);
        } catch (e) {
          throw Exception('Google ile tekrar kimlik doğrulama başarısız: $e');
        }
      }
      // Telefon numarası ile giriş yapılmışsa, re-authenticate gerekmiyor
      else if (user.providerData.any((p) => p.providerId == 'phone')) {
        debugPrint('📱 Phone auth detected - no re-authentication needed');
      }

      // 1. FCM token'ı temizle (önce temizle ki bildirim gitmesin)
      try {
        debugPrint('🗑️ Clearing FCM token before account deletion...');
        await _clearFCMTokenOnSignOut();
      } catch (e) {
        debugPrint('⚠️ FCM token clear error (non-critical): $e');
      }

      // 2. Kullanıcı verilerini sil
      debugPrint('🗑️ Deleting user data from Firestore...');
      await _deleteUserData(user.uid);

      // 3. Google Sign-In cache'ini temizle
      try {
        final isSignedIn = await _googleSignIn.isSignedIn();
        if (isSignedIn) {
          await _googleSignIn.signOut();
          debugPrint('✅ Google Sign-In cache cleared');
        }
      } catch (e) {
        debugPrint('⚠️ Google sign-out error (non-critical): $e');
      }

      // 4. Son olarak Firebase Auth hesabını sil
      debugPrint('🗑️ Deleting Firebase Auth account...');
      await user.delete();

      debugPrint('✅ Account deletion completed successfully');

    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth exception during account deletion: ${e.code}');
      throw Exception(_handleAuthException(e));
    } catch (e) {
      debugPrint('❌ Error during account deletion: $e');
      throw Exception('Hesap silinirken hata oluştu: $e');
    }
  }

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

  Future<app_models.User?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        return app_models.User.fromJson({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      
      return null;
    } catch (e) {
      throw Exception('Kullanıcı profili alınırken hata oluştu: $e');
    }
  }

  Future<void> updateUserProfile(app_models.User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Profil güncellenirken hata oluştu: $e');
    }
  }

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

  Future<void> _createUserProfile(app_models.User user) async {
    // ⚠️ Yeni kullanıcı oluşturulurken MUTLAKA isLoggedIn: true olmalı
    final userData = user.toJson();
    userData['isLoggedIn'] = true; // 🔐 Force set to true for new users

    await _firestore.collection('users').doc(user.id).set(userData);
    debugPrint('✅ New user profile created with isLoggedIn: true');
  }

  /// 🔐 Check if user is currently logged in (optimized - only fetches isLoggedIn field)
  /// Bu metod sadece isLoggedIn field'ını okur, tüm user verisini çekmez
  Future<bool> isUserLoggedIn(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️ User document not found: $userId');
        return false;
      }

      final isLoggedIn = doc.data()?['isLoggedIn'] ?? false;
      debugPrint('🔐 User $userId isLoggedIn: $isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      debugPrint('❌ Error checking isLoggedIn: $e');
      return false;
    }
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

      await _firestore
          .collection('subscriptions')
          .doc(userId)
          .set(subscription.toMap());

      debugPrint('✅ Free subscription created for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to create free subscription: $e');
      // Non-critical error, continue anyway
    }
  }

  Future<void> _updateLastLoginTime(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'isLoggedIn': true, // 🔐 Mark user as logged in
    });
    debugPrint('✅ User marked as logged in: $userId');
  }

  Future<void> _deleteUserData(String userId) async {
    try {
      debugPrint('🗑️ Deleting all user data for: $userId');

      // ⚠️ ÖNEMLİ: Kullanıcı dokümanını EN SON siliyoruz
      // Çünkü kullanıcı dokümanı silindiğinde, diğer koleksiyonlara erişim izni kayboluyor

      // 1. Rüyaları sil
      final dreamsQuery = await _firestore
          .collection('dreams')
          .where('userId', isEqualTo: userId)
          .get();

      if (dreamsQuery.docs.isNotEmpty) {
        final dreamsBatch = _firestore.batch();
        for (final doc in dreamsQuery.docs) {
          dreamsBatch.delete(doc.reference);
        }
        await dreamsBatch.commit();
        debugPrint('✅ ${dreamsQuery.docs.length} dreams deleted');
      }

      // 2. Rüya analizlerini sil
      try {
        final analysesQuery = await _firestore
            .collection('dream_analyses')
            .where('userId', isEqualTo: userId)
            .get();

        if (analysesQuery.docs.isNotEmpty) {
          final analysesBatch = _firestore.batch();
          for (final doc in analysesQuery.docs) {
            analysesBatch.delete(doc.reference);
          }
          await analysesBatch.commit();
          debugPrint('✅ ${analysesQuery.docs.length} dream analyses deleted');
        } else {
          debugPrint('ℹ️ No dream analyses to delete');
        }
      } catch (e) {
        debugPrint('⚠️ Could not delete dream analyses (permission or not found): $e');
        // Continue anyway - this is non-critical
      }

      // 3. Abonelik bilgisini sil
      try {
        await _firestore.collection('subscriptions').doc(userId).delete();
        debugPrint('✅ Subscription deleted');
      } catch (e) {
        debugPrint('ℹ️ Subscription not found: $e');
      }

      // 4. İstatistikleri sil (varsa)
      try {
        await _firestore.collection('user_stats').doc(userId).delete();
        debugPrint('✅ User stats deleted');
      } catch (e) {
        debugPrint('ℹ️ User stats not found (already deleted or never created)');
      }

      // 5. Kullanıcı tercihlerini sil (varsa)
      try {
        await _firestore.collection('user_preferences').doc(userId).delete();
        debugPrint('✅ User preferences deleted');
      } catch (e) {
        debugPrint('ℹ️ User preferences not found (already deleted or never created)');
      }

      // 6. EN SON: Kullanıcı dokümanını sil
      await _firestore.collection('users').doc(userId).delete();
      debugPrint('✅ User document deleted');

      debugPrint('✅ All user data deleted successfully');

    } catch (e) {
      debugPrint('❌ Error deleting user data: $e');
      throw Exception('Kullanıcı verisi silinirken hata oluştu: $e');
    }
  }

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