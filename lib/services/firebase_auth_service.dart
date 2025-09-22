import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart' as app_models;

class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
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

  // Sign in with Google
  Future<app_models.User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
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
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? 'Google User',
            profileImageUrl: firebaseUser.photoURL,
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
      throw Exception('Google ile giriş yapılırken hata oluştu: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
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

  // Update user profile
  Future<void> updateUserProfile(app_models.User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
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
      default:
        return 'Kimlik doğrulama hatası: ${e.message ?? e.code}';
    }
  }
}