import 'package:cloud_firestore/cloud_firestore.dart';

/// The kind of event a notification represents. The UI maps this to an
/// icon/color; Firestore just stores the string.
class NotificationType {
  static const match = 'match';
  static const claimReceived = 'claim_received';
  static const claimApproved = 'claim_approved';
  static const claimRejected = 'claim_rejected';
  static const claimUpdate = 'claim_update';
  static const message = 'message';

  /// Local-only: fired when an item reported while offline finishes
  /// syncing to Firestore. Never comes from the server.
  static const reportPosted = 'report_posted';
}

class NotificationModel {
  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String message;
  final String? relatedItemId;
  final String? relatedClaimId;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedItemId,
    this.relatedClaimId,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? <String, dynamic>{};
    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] as String? ?? '',
      type: data['type'] as String? ?? NotificationType.message,
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      relatedItemId: data['relatedItemId'] as String?,
      relatedClaimId: data['relatedClaimId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'type': type,
      'title': title,
      'message': message,
      'relatedItemId': relatedItemId,
      'relatedClaimId': relatedClaimId,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}