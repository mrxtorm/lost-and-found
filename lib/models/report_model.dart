import 'package:cloud_firestore/cloud_firestore.dart';

/// Why a post or message was reported. Keys are what Firestore stores (and
/// what firestore.rules allows); values are the labels shown in the UI.
class ReportReason {
  ReportReason._();

  static const labels = {
    'fake': 'Fake or misleading post',
    'scam': 'Scam or suspicious request',
    'spam': 'Spam',
    'harassment': 'Harassment or abusive language',
    'inappropriate': 'Inappropriate content',
    'other': 'Other',
  };

  static const forItems = ['fake', 'scam', 'spam', 'inappropriate', 'other'];
  static const forMessages = [
    'harassment',
    'scam',
    'spam',
    'inappropriate',
    'other',
  ];

  static String label(String key) => labels[key] ?? key;
}

class ReportTarget {
  ReportTarget._();

  static const item = 'item';
  static const message = 'message';

  /// Replaces the text of a message an admin removed. Must match the value
  /// required by firestore.rules. (Messages are replaced, not deleted,
  /// because the offline cache only picks up updates, not deletions.)
  static const removedMessageText = 'This message was removed by an admin.';
}

/// What an admin decided. Stored on the report and in moderationLog.
class ModerationAction {
  ModerationAction._();

  static const dismiss = 'dismiss';
  static const remove = 'remove';
  static const removeAndSuspend = 'remove_and_suspend';

  /// Reverts an earlier decision (logged as its own entry; see undoOf).
  static const undo = 'undo';

  /// A suspension was lifted early from the Suspended tab.
  static const unban = 'unban';

  static String label(String action) => switch (action) {
    dismiss => 'Dismissed',
    remove => 'Content removed',
    removeAndSuspend => 'Removed + posting suspended',
    undo => 'Decision undone',
    unban => 'Suspension lifted',
    _ => action,
  };

  static bool isRemoval(String action) =>
      action == remove || action == removeAndSuspend;
}

/// reports/{id}. Created by a user (status 'pending'); reviewed by an admin.
class ReportModel {
  final String id;
  final String targetType; // ReportTarget.item | ReportTarget.message
  final String targetId; // itemId or messageId
  final String conversationId; // '' for items
  final String reporterId;
  final String reportedUserId;
  final String reportedUserName;

  /// Post title or message text at the time of reporting. Firestore rules
  /// check it matches the real content, so admins can trust it without
  /// needing access to the whole conversation.
  final String contentPreview;
  final String reason;
  final String details;
  final String status; // pending | dismissed | actioned
  final DateTime? createdAt;

  const ReportModel({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.conversationId,
    required this.reporterId,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.contentPreview,
    required this.reason,
    required this.details,
    required this.status,
    this.createdAt,
  });

  bool get isItem => targetType == ReportTarget.item;

  factory ReportModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ReportModel(
      id: doc.id,
      targetType: data['targetType'] as String? ?? ReportTarget.item,
      targetId: data['targetId'] as String? ?? '',
      conversationId: data['conversationId'] as String? ?? '',
      reporterId: data['reporterId'] as String? ?? '',
      reportedUserId: data['reportedUserId'] as String? ?? '',
      reportedUserName: data['reportedUserName'] as String? ?? 'User',
      contentPreview: data['contentPreview'] as String? ?? '',
      reason: data['reason'] as String? ?? 'other',
      details: data['details'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// moderationLog/{id}. One immutable entry per admin decision.
class ModerationLogEntry {
  final String id;
  final String adminId;
  final String adminEmail;
  final String action;
  final String targetType;
  final String targetId;
  final String reportedUserId;
  final String reportedUserName;
  final String contentPreview;
  final List<String> reasons;
  final int reportCount;
  final List<String> reportIds;
  final String note;

  /// For action == undo: the id of the entry that was reverted.
  final String undoOf;
  final DateTime? createdAt;

  const ModerationLogEntry({
    required this.id,
    required this.adminId,
    required this.adminEmail,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.contentPreview,
    required this.reasons,
    required this.reportCount,
    this.reportIds = const [],
    required this.note,
    this.undoOf = '',
    this.createdAt,
  });

  bool get isUndo => action == ModerationAction.undo;

  factory ModerationLogEntry.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return ModerationLogEntry(
      id: doc.id,
      adminId: data['adminId'] as String? ?? '',
      adminEmail: data['adminEmail'] as String? ?? '',
      action: data['action'] as String? ?? '',
      targetType: data['targetType'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      reportedUserId: data['reportedUserId'] as String? ?? '',
      reportedUserName: data['reportedUserName'] as String? ?? '',
      contentPreview: data['contentPreview'] as String? ?? '',
      reasons:
          (data['reasons'] as List?)?.whereType<String>().toList() ?? const [],
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
      reportIds:
          (data['reportIds'] as List?)?.whereType<String>().toList() ??
          const [],
      note: data['note'] as String? ?? '',
      undoOf: data['undoOf'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
