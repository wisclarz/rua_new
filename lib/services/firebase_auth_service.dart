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
    forceCodeForRefreshToken: true,
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
      print('🤫 Attempting silent Google Sign-In...');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      if (googleUser == null) {
        print('ℹ️ No cached Google user found');
        return null;
      }
      
      print('✅ Found cached Google user: ${googleUser.email}');
      
      final currentFirebaseUser = _auth.currentUser;
      if (currentFirebaseUser != null && currentFirebaseUser.email == googleUser.email) {
        print('✅ Firebase user already signed in: ${currentFirebaseUser.uid}');
        return await getUserProfile(currentFirebaseUser.uid);
      }
      
      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await googleUser.authentication;
        
        if (!GoogleSignInHelper.validateGoogleAuthTokens(googleAuth)) {
          print('⚠️ Invalid Google auth tokens in silent sign-in');
          return null;
        }
      } catch (e) {
        print('⚠️ Failed to get Google auth tokens: $e');
        return null;
      }
      
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;
        print('✅ Silent Firebase authentication successful: ${firebaseUser.uid}');
        
        app_models.User? user = await getUserProfile(firebaseUser.uid);
        
        if (user == null) {
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
          await _updateLastLoginTime(firebaseUser.uid);
          print('✅ Last login time updated for: ${user.name}');
        }
        
        return user;
      }
      
      return null;
      
    } catch (e) {
      print('ℹ️ Silent sign-in failed (this is normal): $e');
      return null;
    }
  }

  Future<app_models.User?> signInWithGoogle() async {
    try {
      await GoogleSignInHelper.safeClearGoogleSignIn(_googleSignIn);
      
      GoogleSignInAccount? googleUser;
      GoogleSignInAuthentication? googleAuth;
      
      int attempts = 0;
      const maxAttempts = 3;
      
      while (attempts < maxAttempts) {
        try {
          googleUser = await _googleSignIn.signIn();
          if (googleUser == null) return null;

          googleAuth = await googleUser.authentication;
          
          if (GoogleSignInHelper.validateGoogleAuthTokens(googleAuth)) {
            break;
          } else {
            throw Exception('Invalid tokens received');
          }
        } catch (e) {
          attempts++;
          print('🔄 Google Sign-In attempt $attempts failed: $e');
          
          if (GoogleSignInHelper.isPigeonUserDetailsError(e)) {
            print('⚠️ PigeonUserDetails error detected, retrying...');
            await GoogleSignInHelper.safeClearGoogleSignIn(_googleSignIn);
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          
          if (attempts >= maxAttempts) {
            rethrow;
          }
          
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
      
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
        
        app_models.User? user = await getUserProfile(firebaseUser.uid);
        
        if (user == null) {
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
      
      if (GoogleSignInHelper.isPigeonUserDetailsError(e)) {
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
      print('📱 Starting phone verification for: $phoneNumber');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
          print('✅ Phone verification completed automatically');
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
          user = app_models.User(
            id: firebaseUser.uid,
            email: '',
            phoneNumber: firebaseUser.phoneNumber,
            name: userName ?? 'Telefon Kullanıcısı',
            createdAt: DateTime.now(),
            preferences: app_models.UserPreferences.defaultPreferences(),
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
      throw Exception('Telefon doğrulaması yapılırken hata oluştu: $e');
    }
  }

  Future<void> signOut() async {
    try {
      print('🚪 Starting sign out process...');
      
      try {
        await _googleSignIn.signOut();
        print('✅ Google Sign-In signed out');
      } catch (e) {
        print('⚠️ Google sign out warning: $e');
      }
      
      try {
        await _googleSignIn.disconnect();
        print('✅ Google Sign-In disconnected');
      } catch (e) {
        print('⚠️ Google disconnect warning: $e');
      }
      
      await _auth.signOut();
      print('✅ Firebase sign out completed');
      
      print('✅ Sign out process completed successfully');
      
    } catch (e) {
      print('❌ Error during sign out: $e');
      throw Exception('Çıkış yapılırken hata oluştu: $e');
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

  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      await _deleteUserData(user.uid);
      await user.delete();
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
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
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  Future<void> _updateLastLoginTime(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> _deleteUserData(String userId) async {
    final batch = _firestore.batch();
    
    try {
      batch.delete(_firestore.collection('users').doc(userId));
      
      final dreamsQuery = await _firestore
          .collection('dreams')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in dreamsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      final analysesQuery = await _firestore
          .collection('dream_analyses')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in analysesQuery.docs) {
        batch.delete(doc.reference);
      }
      
      batch.delete(_firestore.collection('user_stats').doc(userId));
      batch.delete(_firestore.collection('user_preferences').doc(userId));
      
      await batch.commit();
    } catch (e) {
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