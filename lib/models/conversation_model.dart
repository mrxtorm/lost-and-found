import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String postId;
  final String itemName;
  final String itemImageUrl;
  final String itemType;
  final List<String> participantIds;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.postId,
    required this.itemName,
    required this.itemImageUrl,
    required this.itemType,
    this.participantIds = const [],
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  factory ConversationModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String currentUserId,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final participantIds = List<String>.from(
      data['participantIds'] as List<dynamic>? ?? const [],
    );
    final participantNames = Map<String, dynamic>.from(
      data['participantNames'] as Map<String, dynamic>? ?? const {},
    );
    final unreadCounts = Map<String, dynamic>.from(
      data['unreadCounts'] as Map<String, dynamic>? ?? const {},
    );

    final otherUserId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    final timestamp = data['lastMessageTime'];
    final lastMessageTime = timestamp is Timestamp
        ? timestamp.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);

    return ConversationModel(
      id: doc.id,
      postId: data['postId'] as String? ?? '',
      itemName: data['itemName'] as String? ?? 'Item',
      itemImageUrl: data['itemImageUrl'] as String? ?? '',
      itemType: data['itemType'] as String? ?? '',
      participantIds: participantIds,
      otherUserId: otherUserId,
      otherUserName: participantNames[otherUserId] as String? ?? 'User',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageTime: lastMessageTime,
      unreadCount: (unreadCounts[currentUserId] as num?)?.toInt() ?? 0,
    );
  }
}
