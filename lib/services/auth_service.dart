import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user (null if not logged in)
  User? get currentUser => _auth.currentUser;

  // Stream to listen for auth state changes (useful for auto-login/routing)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register a new user
  Future<User?> register(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save the name to the Firebase user profile
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();

      return _auth.currentUser; // reload to get the updated displayName
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  // Login existing user
  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Convert Firebase error codes into readable messages
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}