import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isRead,
  });

  factory MessageModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String conversationId,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final timestamp = data['timestamp'];

    return MessageModel(
      id: doc.id,
      conversationId: conversationId,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'User',
      text: data['text'] as String? ?? '',
      timestamp: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }
}
