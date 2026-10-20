import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Reads the signed-in user's posting suspension (users/{uid}.bannedUntil,
/// set by an admin). Firestore rules already reject posts from suspended
/// users; this lets the app say so up front instead of failing on submit
/// (or, offline, queueing a post that can never sync).
class SuspensionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// When the current suspension ends, or null if the user isn't
  /// suspended. If the status can't be read (e.g. offline with nothing
  /// cached) this returns null and the server rules remain the backstop.
  Future<DateTime?> activeSuspensionEnd() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 6));
      final until = (doc.data()?['bannedUntil'] as Timestamp?)?.toDate();
      return until != null && until.isAfter(DateTime.now()) ? until : null;
    } catch (_) {
      return null;
    }
  }
}
