import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../screens/conversation_screen.dart';

class MessageButton extends StatefulWidget {
  final String postId;
  final String itemName;
  final String itemType;
  final String otherUserId;
  final String otherUserName;
  final String imageUrl;

  const MessageButton({
    super.key,
    required this.postId,
    required this.itemName,
    required this.itemType,
    required this.otherUserId,
    required this.otherUserName,
    this.imageUrl = '',
  });

  @override
  State<MessageButton> createState() => _MessageButtonState();
}

class _MessageButtonState extends State<MessageButton> {
  bool _isOpening = false;

  Future<void> _openConversation(BuildContext context) async {
    setState(() {
      _isOpening = true;
    });

    try {
      final conversationId =
          await context.read<ChatProvider>().getOrCreateConversation(
                postId: widget.postId,
                itemName: widget.itemName,
                itemImageUrl: widget.imageUrl,
                itemType: widget.itemType,
                otherUserId: widget.otherUserId,
                otherUserName: widget.otherUserName,
              );

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationScreen(conversationId: conversationId),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to start conversation: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpening = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isOpening ? null : () => _openConversation(context),
      icon: _isOpening
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chat_bubble_outline),
      label: const Text('Message'),
    );
  }
}
