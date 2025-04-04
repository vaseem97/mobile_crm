import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create a new account
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Reset password
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user profile
  Future<void> updateUserProfile(
      {String? displayName, String? photoURL}) async {
    try {
      await _firebaseAuth.currentUser?.updateDisplayName(displayName);
      await _firebaseAuth.currentUser?.updatePhotoURL(photoURL);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'email-already-in-use':
        return Exception('The email address is already in use.');
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'invalid-email':
        return Exception('The email address is invalid.');
      case 'operation-not-allowed':
        return Exception('Operation not allowed.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many requests. Try again later.');
      case 'network-request-failed':
        return Exception('Network error. Check your connection.');
      default:
        return Exception('An undefined error occurred: ${e.message}');
    }
  }
}
