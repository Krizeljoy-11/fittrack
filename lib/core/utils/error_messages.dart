import 'package:firebase_auth/firebase_auth.dart';

/// Turns Firebase errors into short, user-facing messages.
String describeError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'requires-recent-login':
        return 'Please sign in again before retrying this action.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to do that.';
      case 'unavailable':
        return 'Firestore is unreachable right now. Please try again.';
      case 'not-found':
        return 'The requested item no longer exists.';
      default:
        return error.message ?? 'A Firebase error occurred.';
    }
  }

  return 'Something went wrong. Please try again.';
}
