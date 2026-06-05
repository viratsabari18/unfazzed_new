import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Adding serverClientId (Web Client ID) can help resolve audience mismatch errors
    // serverClientId: 'YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com',
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

  // Phone Authentication: Verify Phone Number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // AUTO-VERIFICATION (usually on Android)
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: onVerificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint("Phone Verification Error: $e");
    }
  }

Future<UserCredential?> signInWithPhoneNumber(
  String verificationId,
  String smsCode,
) async {
  try {
    debugPrint("================================");
    debugPrint("STARTING OTP VERIFICATION");
    debugPrint("Verification ID: $verificationId");
    debugPrint("SMS Code: $smsCode");
    debugPrint("================================");

    final AuthCredential credential =
        PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    debugPrint("PHONE CREDENTIAL CREATED");

    final result =
        await _auth.signInWithCredential(credential);

    debugPrint("================================");
    debugPrint("OTP VERIFIED SUCCESSFULLY");
    debugPrint("UID: ${result.user?.uid}");
    debugPrint("PHONE: ${result.user?.phoneNumber}");
    debugPrint("================================");

    return result;
  } on FirebaseAuthException catch (e, stackTrace) {
    debugPrint("================================");
    debugPrint("FIREBASE AUTH ERROR");
    debugPrint("CODE: ${e.code}");
    debugPrint("MESSAGE: ${e.message}");
    debugPrint("EXCEPTION: $e");
    debugPrint("STACKTRACE: $stackTrace");
    debugPrint("================================");

    throw FirebaseAuthException(
      code: e.code,
      message: e.message,
    );
  } catch (e, stackTrace) {
    debugPrint("================================");
    debugPrint("GENERAL ERROR");
    debugPrint("ERROR: $e");
    debugPrint("STACKTRACE: $stackTrace");
    debugPrint("================================");

    throw Exception(e.toString());
  }
}

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
