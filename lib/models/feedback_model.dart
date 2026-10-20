import 'package:cloud_firestore/cloud_firestore.dart';

/// A finished item return. Written by the finder at the moment a claim is
/// approved (the claim, item and chat are deleted right after), so it is the
/// only durable proof that two users completed a transaction.
class CompletedReturn {
  final String id; // same as the claim id: {itemId}_{claimantId}
  final String itemId;
  final String itemTitle;
  final String ownerId;
  final String claimantId;

  const CompletedReturn({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.ownerId,
    required this.claimantId,
  });

  factory CompletedReturn.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CompletedReturn(
      id: doc.id,
      itemId: data['itemId'] as String? ?? '',
      itemTitle: data['itemTitle'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      claimantId: data['claimantId'] as String? ?? '',
    );
  }

  bool hasParticipant(String uid) => uid == ownerId || uid == claimantId;
  String otherUserFor(String uid) => uid == ownerId ? claimantId : ownerId;
}

/// feedback/{returnId}_{uid}: one participant's rating of a return.
/// Read back only by admins (Admin Dashboard > Feedback).
class FeedbackEntry {
  final String id;
  final String returnId; // shared by both participants' feedback
  final String itemTitle;
  final String authorId;
  final String otherUserId;
  final String role; // finder | claimant
  final int rating; // 1-5
  final String recommendation;
  final DateTime? createdAt;

  const FeedbackEntry({
    required this.id,
    required this.returnId,
    required this.itemTitle,
    required this.authorId,
    required this.otherUserId,
    required this.role,
    required this.rating,
    required this.recommendation,
    this.createdAt,
  });

  factory FeedbackEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return FeedbackEntry(
      id: doc.id,
      returnId: data['returnId'] as String? ?? '',
      itemTitle: data['itemTitle'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      otherUserId: data['otherUserId'] as String? ?? '',
      role: data['role'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      recommendation: data['recommendation'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
