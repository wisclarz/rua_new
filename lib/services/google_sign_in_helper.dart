import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInHelper {
  /// Check if error is related to PigeonUserDetails issue
  static bool isPigeonUserDetailsError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('pigeonuserdetails') ||
           errorString.contains('list<object?>') ||
           errorString.contains('type cast');
  }

  /// Check if error is related to network issues
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('unreachable');
  }

  /// Check if user cancelled the sign-in process
  static bool isUserCancellationError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('cancelled') ||
           errorString.contains('canceled') ||
           errorString.contains('user_cancelled');
  }

  /// Check if error is related to disconnect issues
  static bool isDisconnectError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('failed to disconnect') ||
           errorString.contains('disconnect') ||
           errorString.contains('status');
  }

  /// Get user-friendly error message for Google Sign-In errors
  static String getErrorMessage(dynamic error) {
    if (isPigeonUserDetailsError(error)) {
      return 'Google ile giriş sorunu yaşanıyor. Uygulamayı kapatıp tekrar açın.';
    }
    
    if (isNetworkError(error)) {
      return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
    }
    
    if (isUserCancellationError(error)) {
      return 'Google ile giriş iptal edildi.';
    }
    
    if (error is PlatformException) {
      switch (error.code) {
        case 'sign_in_failed':
          return 'Google ile giriş başarısız. Lütfen tekrar deneyin.';
        case 'account_exists_with_different_credential':
          return 'Bu e-posta adresi farklı bir yöntemle kayıt edilmiş.';
        case 'invalid-credential':
          return 'Geçersiz kimlik bilgileri.';
        case 'operation-not-allowed':
          return 'Google ile giriş etkinleştirilmemiş.';
        case 'user-disabled':
          return 'Bu hesap devre dışı bırakılmış.';
        default:
          return 'Google ile giriş hatası: ${error.message ?? 'Bilinmeyen hata'}';
      }
    }
    
    return 'Google ile giriş yapılırken hata oluştu. Lütfen tekrar deneyin.';
  }

  /// Safely disconnect from Google Sign-In to clear cached credentials
  static Future<void> safeClearGoogleSignIn(GoogleSignIn googleSignIn) async {
    try {
      await googleSignIn.signOut();
      print('✅ Google sign out completed');
    } catch (e) {
      print('⚠️ Google sign out error (non-critical): $e');
    }
    
    try {
      await googleSignIn.disconnect();
      print('✅ Google disconnect completed');
    } catch (e) {
      if (isDisconnectError(e)) {
        print('⚠️ Google disconnect error (non-critical): $e');
      } else {
        print('⚠️ Google disconnect error (non-critical): $e');
      }
    }
  }

  /// Validate Google authentication tokens
  /// Returns true if both accessToken and idToken are present and valid
  static bool validateGoogleAuthTokens(GoogleSignInAuthentication? auth) {
    if (auth == null) {
      print('⚠️ GoogleSignInAuthentication is null');
      return false;
    }
    
    final hasAccessToken = auth.accessToken != null && auth.accessToken!.isNotEmpty;
    final hasIdToken = auth.idToken != null && auth.idToken!.isNotEmpty;
    
    if (!hasAccessToken) {
      print('⚠️ Access token is missing or empty');
    }
    
    if (!hasIdToken) {
      print('⚠️ ID token is missing or empty');
    }
    
    return hasAccessToken && hasIdToken;
  }
  
  /// Get safe access token string (empty string if null)
  static String getSafeAccessToken(GoogleSignInAuthentication? auth) {
    return auth?.accessToken ?? '';
  }
  
  /// Get safe ID token string (empty string if null)
  static String getSafeIdToken(GoogleSignInAuthentication? auth) {
    return auth?.idToken ?? '';
  }
}