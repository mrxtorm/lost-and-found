import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/claim_model.dart';
import '../data/repositories/claim_repository.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/claim_service.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;

  const ConversationScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ClaimService _claimService = ClaimService();

  bool _isSending = false;
  bool _didInitialScroll = false;
  bool _markingRead = false;
  bool _isResolvingClaim = false;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    if (_markingRead) return;
    _markingRead = true;
    try {
      await context.read<ChatProvider>().markConversationRead(widget.conversationId);
    } catch (_) {}
    finally {
      _markingRead = false;
    }
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await context.read<ChatProvider>().sendMessage(
        conversationId: widget.conversationId,
        text: text,
      );
      _scrollToBottom(animated: true);
    } catch (e) {
      _messageController.text = text;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _resolveClaim(String status) async {
    if (_isResolvingClaim) return;

        final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${status == 'Approved' ? 'Accept' : 'Reject'} Claim?'),
        content: Text(
          status == 'Approved'
              ? 'Accepting this claim marks the item as successfully claimed and removes the item, claim, conversation, and messages for privacy.'
              : 'Reject this claim? The conversation will remain available so you can discuss the item further.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(status == 'Approved' ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isResolvingClaim = true);
    try {
      await _claimService.updateClaimStatus(
        _currentClaimId,
        status,
      );

      if (!mounted) return;

      if (status == 'Approved') {
        // The conversation has been deleted. Leave this screen immediately.
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Claim ${status == 'Approved' ? 'accepted' : 'rejected'} successfully.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update claim: $e')),
      );
    } finally {
      if (mounted) setState(() => _isResolvingClaim = false);
    }
  }

  String _currentClaimId = '';

  void _scrollToBottom({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.uid ?? '';
    final conversation = chatProvider.conversationById(widget.conversationId);

    if (chatProvider.error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Unable to load this conversation.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation?.otherUserName ?? 'Conversation',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if ((conversation?.itemName ?? '').isNotEmpty)
              Text(
                conversation!.itemName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
      body: conversation == null
          ? Column(
              children: [
                Expanded(
                  child: _buildMessagesArea(chatProvider, currentUserId, null),
                ),
                _buildMessageInput(null, false),
              ],
            )
          // The claim panel and the option button are visible only to the
          // two people involved in this conversation because the claim
          // document itself is private.
          : StreamBuilder<ClaimModel?>(
              stream: context.read<ClaimRepository>().watchClaimForItem(conversation.postId),
              builder: (context, claimSnapshot) {
                final claim = claimSnapshot.data;
                if (claim != null) {
                  _currentClaimId = claim.id;
                }
                final isFinder = claim != null && claim.ownerId == currentUserId;

                return Column(
                  children: [
                    _buildItemHeader(conversation),
                    if (claim != null) _buildClaimPanel(claim, currentUserId),
                    Expanded(
                      child: _buildMessagesArea(chatProvider, currentUserId, conversation),
                    ),
                    _buildMessageInput(claim, isFinder),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildMessagesArea(
    ChatProvider chatProvider,
    String currentUserId,
    ConversationModel? conversation,
  ) {
    return StreamBuilder<List<MessageModel>>(
      stream: chatProvider.streamMessages(widget.conversationId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load messages.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data ?? const <MessageModel>[];
        if (!_didInitialScroll && messages.isNotEmpty) {
          _didInitialScroll = true;
          _scrollToBottom(animated: false);
        }

        if (conversation != null && conversation.unreadCount > 0) {
          _markRead();
        }

        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet. Say hello!',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          itemCount: messages.length,
          itemBuilder: (_, index) =>
              _buildMessageBubble(messages[index], currentUserId),
        );
      },
    );
  }

  Widget _buildClaimPanel(ClaimModel claim, String currentUserId) {
    final isFinder = claim.ownerId == currentUserId;
    final isClaimant = claim.claimantId == currentUserId;
    if (!isFinder && !isClaimant) return const SizedBox.shrink();

    final pending = claim.status.toLowerCase() == 'pending';
    final approved = claim.status.toLowerCase() == 'approved';
    final rejected = claim.status.toLowerCase() == 'rejected';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFinder
                      ? 'Claim Request'
                      : 'Your Claim Request',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pending
                      ? Colors.orange
                      : rejected
                          ? Colors.red
                          : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  claim.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isFinder) ...[
            Text(
              '${claim.claimantName} says this item belongs to them.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
          ],
          _answerBox('Verification Answer', claim.answer),
          if (claim.additionalDetails.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _answerBox('Additional Information', claim.additionalDetails),
          ],
          if (isFinder && pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 16, color: Colors.orange.shade900),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tap the options button next to the message box to accept or reject this claim.',
                    style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          if (isClaimant && pending) ...[
            const SizedBox(height: 10),
            Text(
              'Your claim has been sent. Continue discussing the item here and provide more information if needed.',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
            ),
          ],
          if (rejected) ...[
            const SizedBox(height: 8),
            const Text(
              'This claim was rejected. The conversation remains open for further discussion.',
              style: TextStyle(fontSize: 12),
            ),
          ],
          if (approved) ...[
            const SizedBox(height: 8),
            const Text('This claim was approved.'),
          ],
        ],
      ),
    );
  }

  Widget _answerBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(value.isEmpty ? 'No answer provided.' : value),
        ],
      ),
    );
  }

  Widget _buildItemHeader(ConversationModel conversation) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: conversation.itemImageUrl.isEmpty
                ? const Icon(Icons.image_outlined, color: Colors.grey)
                : Image.network(
                    conversation.itemImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_outlined,
                      color: Colors.grey,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (conversation.itemType.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    conversation.itemType.toUpperCase(),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, String currentUserId) {
    final isMine = message.senderId == currentUserId;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * .78,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.timestamp),
              style: TextStyle(
                color: isMine ? Colors.white70 : Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(ClaimModel? claim, bool isFinder) {
    final hasText = _messageController.text.trim().isNotEmpty;
    final hasPendingClaimForFinder =
        claim != null && isFinder && claim.status.toLowerCase() == 'pending';

    // "Option" state: field is empty and the founder has a pending claim to
    // act on -> button opens the accept/reject sheet instead of sending.
    final showOptionsButton = !hasText && hasPendingClaimForFinder;

    VoidCallback? onPressed;
    Widget icon;
    if (_isSending) {
      onPressed = null;
      icon = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    } else if (showOptionsButton) {
      onPressed = () => _showClaimOptions(claim);
      icon = const Icon(Icons.checklist_rtl, color: Colors.white);
    } else if (hasText) {
      onPressed = _sendMessage;
      icon = const Icon(Icons.send, color: Colors.white);
    } else {
      onPressed = null;
      icon = const Icon(Icons.send, color: Colors.white);
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: onPressed,
                icon: icon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClaimOptions(ClaimModel claim) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Claim Request',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${claim.claimantName} says this item belongs to them.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _resolveClaim('Rejected');
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _resolveClaim('Approved');
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Accept Claim'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }
}
