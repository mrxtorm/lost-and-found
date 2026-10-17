import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/feedback_model.dart';

/// Optional post-return feedback.
///
/// - completedReturns/{claimId}: written by the finder when approving.
/// - feedback/{claimId}_{uid}: one per participant. The deterministic id plus
///   create-only Firestore rules prevent duplicate submissions.
class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const maxRecommendationLength = 500;

  String? get _uid => _auth.currentUser?.uid;

  String _feedbackId(String returnId, String uid) => '${returnId}_$uid';

  /// Called by the finder right after the claim is marked Approved.
  Future<void> recordCompletedReturn({
    required String claimId,
    required String itemId,
    required String itemTitle,
    required String ownerId,
    required String claimantId,
  }) {
    return _firestore.collection('completedReturns').doc(claimId).set({
      'itemId': itemId,
      'itemTitle': itemTitle,
      'ownerId': ownerId,
      'claimantId': claimantId,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Null when it doesn't exist or the user isn't a participant.
  Future<CompletedReturn?> fetchCompletedReturn(String returnId) async {
    final uid = _uid;
    if (uid == null || returnId.isEmpty) return null;
    try {
      final doc = await _firestore
          .collection('completedReturns')
          .doc(returnId)
          .get()
          .timeout(const Duration(seconds: 8));
      if (!doc.exists) return null;
      final result = CompletedReturn.fromDoc(doc);
      return result.hasParticipant(uid) ? result : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasSubmitted(String returnId) async {
    final uid = _uid;
    if (uid == null) return true;
    try {
      final doc = await _firestore
          .collection('feedback')
          .doc(_feedbackId(returnId, uid))
          .get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  Future<void> submit({
    required CompletedReturn completedReturn,
    required int rating,
    required String recommendation,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('You must be signed in.');
    if (!completedReturn.hasParticipant(uid)) {
      throw Exception('Only participants of this return can leave feedback.');
    }
    if (rating < 1 || rating > 5) throw Exception('Choose a rating first.');

    final ref = _firestore
        .collection('feedback')
        .doc(_feedbackId(completedReturn.id, uid));

    if ((await ref.get()).exists) {
      throw Exception('You already submitted feedback for this return.');
    }

    await ref.set({
      'returnId': completedReturn.id,
      'itemTitle': completedReturn.itemTitle,
      'authorId': uid,
      'role': uid == completedReturn.ownerId ? 'finder' : 'claimant',
      'otherUserId': completedReturn.otherUserFor(uid),
      'rating': rating,
      'recommendation': recommendation.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
