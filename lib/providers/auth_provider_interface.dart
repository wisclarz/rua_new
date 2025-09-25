import 'package:flutter/material.dart';
import '../models/user_model.dart' as app_models;

// Interface for auth providers
abstract class AuthProviderInterface with ChangeNotifier {
  app_models.User? get currentUser;
  bool get isLoading;
  String? get errorMessage;
  bool get isAuthenticated;
  bool get isVerifyingPhone;
  String? get verificationId;
  bool get isInitialized;
  
  Future<bool> signInWithGoogle();
  Future<bool> sendPhoneVerificationCode(String phoneNumber);
  Future<bool> verifyPhoneCode({
    required String smsCode,
    String? userName,
  });
  Future<void> signOut();
  Future<bool> updateUserProfile(app_models.User user);
  Future<bool> updateProfileImage(String imageUrl);
  Future<bool> deleteAccount();
  Future<void> sendEmailVerification();
  void resetPhoneVerification();
  void clearError();
}
