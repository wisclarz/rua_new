# Firebase Authentication Setup Instructions

## Firebase Authentication Configuration

Your Flutter app has been updated to use Firebase Authentication with phone number and Google sign-in. However, you need to complete the Firebase configuration before testing.

## What's Been Implemented

✅ **Firebase Auth Service** - Complete authentication service with phone and Google sign-in
✅ **Phone Authentication UI** - Modern phone verification screen with SMS code input
✅ **Google Sign-In UI** - Integrated Google authentication button
✅ **Firebase Auth Provider** - State management for authentication
✅ **Updated Dependencies** - All necessary Firebase packages are configured

## Required Configuration Steps

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use an existing one
3. Add your Android/iOS apps to the project

### 2. Download Configuration Files

**For Android:**
- Download `google-services.json`
- Place it in `android/app/` directory (replace the existing placeholder)

**For iOS:**
- Download `GoogleService-Info.plist`
- Add it to your iOS project in Xcode

### 3. Update Firebase Configuration

Replace the placeholder values in `lib/config/firebase_options.dart` with your actual Firebase project configuration:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-actual-android-api-key',
  appId: 'your-actual-android-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  storageBucket: 'your-actual-project.appspot.com',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'your-actual-ios-api-key',
  appId: 'your-actual-ios-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  storageBucket: 'your-actual-project.appspot.com',
  iosBundleId: 'com.example.ruaDreamApp',
);
```

### 4. Enable Authentication Methods

In Firebase Console:
1. Go to **Authentication** > **Sign-in method**
2. Enable **Phone** authentication
3. Enable **Google** authentication
4. Configure OAuth consent screen for Google sign-in

### 5. Configure Phone Authentication

1. In Firebase Console, go to **Authentication** > **Sign-in method** > **Phone**
2. Add your test phone numbers if needed
3. Configure your app's SHA-1 fingerprint for Android

### 6. Configure Google Sign-In

1. In Firebase Console, enable Google sign-in
2. Download and configure OAuth 2.0 client IDs
3. For Android: Add SHA-1 fingerprint in Firebase console
4. For iOS: Add URL schemes in Xcode

### 7. Test Phone Number for Development

Add a test phone number in Firebase Console:
- Go to **Authentication** > **Sign-in method** > **Phone**
- Scroll down to "Phone numbers for testing"
- Add: `+90 555 123 4567` with verification code: `123456`

## Getting SHA-1 Fingerprint (Android)

Run this command in your project directory:
```bash
# For debug
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release (when you create a release keystore)
keytool -list -v -keystore path/to/your/release.keystore -alias your-alias
```

## Testing Authentication

Once configured, you can test:

1. **Phone Authentication:**
   - Use test phone number: `+90 555 123 4567`
   - Use test verification code: `123456`

2. **Google Sign-In:**
   - Should work with any Google account

## Current App Flow

1. App starts with `PhoneAuthScreen`
2. User can either:
   - Enter phone number and verify with SMS
   - Sign in with Google account
3. After successful authentication, user goes to `MainNavigation`
4. User data is stored in Firestore

## Files Modified

- `lib/main.dart` - Updated to use Firebase and new auth provider
- `lib/providers/firebase_auth_provider.dart` - New Firebase-based auth provider
- `lib/services/firebase_auth_service.dart` - Added phone authentication
- `lib/screens/phone_auth_screen.dart` - New modern phone auth UI
- `lib/screens/home_screen.dart` - Updated to use Firebase auth provider
- `lib/screens/profile_screen.dart` - Updated to use Firebase auth provider

## Next Steps

1. Complete Firebase configuration with real project credentials
2. Test phone authentication with test numbers
3. Test Google sign-in
4. Deploy to Firebase hosting if needed
5. Configure production phone authentication rates and quotas

## Troubleshooting

- **SMS not received:** Check Firebase quotas and test phone numbers
- **Google sign-in fails:** Verify SHA-1 fingerprint and OAuth configuration
- **Build errors:** Ensure `google-services.json` is properly placed
- **Authentication state issues:** Check Firestore security rules

Your app is now ready for Firebase authentication once you complete the configuration!