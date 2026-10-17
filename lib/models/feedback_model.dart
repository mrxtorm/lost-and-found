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
