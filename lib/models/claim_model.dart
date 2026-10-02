import 'package:cloud_firestore/cloud_firestore.dart';

class ClaimModel {
  final String id;
  final String itemId;
  final String itemTitle;
  final String itemImageUrl;
  final String claimantId;
  final String claimantName;
  final String ownerId;
  final String answer;
  final String additionalDetails;
  final String status; // Pending, Approved, Rejected
  final DateTime? createdAt;

  const ClaimModel({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.itemImageUrl,
    required this.claimantId,
    required this.claimantName,
    required this.ownerId,
    required this.answer,
    required this.additionalDetails,
    required this.status,
    this.createdAt,
  });

  factory ClaimModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ClaimModel(
      id: doc.id,
      itemId: data['itemId'] as String? ?? '',
      itemTitle: data['itemTitle'] as String? ?? '',
      itemImageUrl: data['itemImageUrl'] as String? ?? '',
      claimantId: data['claimantId'] as String? ?? '',
      claimantName: data['claimantName'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      answer: data['answer'] as String? ?? '',
      additionalDetails: data['additionalDetails'] as String? ?? '',
      status: data['status'] as String? ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemTitle': itemTitle,
      'itemImageUrl': itemImageUrl,
      'claimantId': claimantId,
      'claimantName': claimantName,
      'ownerId': ownerId,
      'answer': answer,
      'additionalDetails': additionalDetails,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
