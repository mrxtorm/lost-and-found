import '../widgets/return_feedback_sheet.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/item_ui.dart';

import '../data/local/app_database.dart';
import '../models/item_model.dart';
import 'claim_item_screen.dart';
import '../models/claim_model.dart';
import '../data/repositories/claim_repository.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/report_model.dart';
import '../widgets/report_sheet.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/item_provider.dart';
import '../services/claim_service.dart';
import '../data/repositories/item_repository.dart';
import '../widgets/claim_actions.dart';

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
  final FocusNode _inputFocus = FocusNode();
  final ClaimService _claimService = ClaimService();

  /// User's choice for the claim card; null = default (open only when the
  /// finder still has to decide).
  bool? _claimExpanded;

  bool _isSending = false;
  bool _didInitialScroll = false;
  bool _markingRead = false;
  bool _isResolvingClaim = false;

  Stream<ItemRow?>? _itemStream;
  String? _itemStreamPostId;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
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
      AppSnack.show(context, 'Failed to send message: $e', kind: SnackKind.error);
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
              ? 'Accepting marks the item as claimed and moves it to your archive. You can undo it for ${ItemModel.archiveDays} days if the handover falls through; after that the post, claim and this chat are deleted for privacy.'
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

    final chatProvider = context.read<ChatProvider>();
    final itemProvider = context.read<ItemProvider>();
    setState(() => _isResolvingClaim = true);
    try {
      await _claimService.updateClaimStatus(
        _currentClaimId,
        status,
      );

      if (!mounted) return;

      if (status == 'Approved') {
        final postId = chatProvider.conversationById(widget.conversationId)?.postId;
        if (postId != null) await itemProvider.refreshItem(postId);
        if (!mounted) return;
        // The chat stays until the archive time is up, so celebrate here.
        ReturnCompletion.run(Navigator.of(context), returnId: _currentClaimId);
      } else {
        AppSnack.show(context, 'Claim ${status == 'Approved' ? 'accepted' : 'rejected'} successfully.', kind: SnackKind.success);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(context, 'Unable to update claim: $e', kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _isResolvingClaim = false);
    }
  }

  String _currentClaimId = '';

  Future<void> _resendClaim(ClaimModel claim) async {
    final navigator = Navigator.of(context);
    ItemModel? item;

    // Local cache first (works offline)...
    try {
      final row = await context.read<AppDatabase>().getItem(claim.itemId);
      if (row != null) {
        item = ItemModel(
          id: row.id,
          title: row.title,
          description: row.description,
          category: row.category,
          location: row.location,
          date: row.date,
          status: row.status,
          imageUrl: row.imageUrl,
          username: row.username,
          ownerPhotoUrl: row.ownerPhotoUrl,
          ownerId: row.ownerId,
          verificationQuestion: row.verificationQuestion,
          createdAt: row.createdAt,
          localImagePath: row.localImagePath,
        );
      }
    } catch (_) {}

    // ...then Firestore.
    if (item == null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('items')
            .doc(claim.itemId)
            .get()
            .timeout(const Duration(seconds: 6));
        if (doc.exists) item = ItemModel.fromDoc(doc);
      } catch (_) {}
    }

    if (!mounted) return;

    final resolvedItem = item;
    if (resolvedItem == null) {
      AppSnack.show(context, 'This post is no longer available.', kind: SnackKind.error);
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ClaimItemScreen(
          item: resolvedItem,
          isResend: true,
          initialAnswer: claim.answer,
          initialDetails: claim.additionalDetails,
        ),
      ),
    );
  }

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
        body: const ErrorState(
          message: 'Unable to load this conversation.',
        ),
      );
    }

    final otherName = conversation?.otherUserName ?? 'Conversation';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        toolbarHeight: 64,
        titleSpacing: 0,
        shape: Border(bottom: BorderSide(color: AppColors.line)),
        title: Row(
          children: [
            UserAvatar(name: otherName, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                otherName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
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
              stream: context.read<ClaimRepository>().watchClaimForConversation(
                conversation.postId,
                conversation.otherUserId,
              ),
              builder: (context, claimSnapshot) {
                final claim = claimSnapshot.data;
                if (claim != null) {
                  _currentClaimId = claim.id;
                }
                final isFinder = claim != null && claim.ownerId == currentUserId;

                return Column(
                  children: [
                    _buildItemHeader(conversation),
                    _buildReturnPanel(conversation, currentUserId),
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

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Messages from the same person within a few minutes are drawn as one
  /// visual group (tight spacing, one timestamp, one bubble tail).
  static bool _sameGroup(MessageModel a, MessageModel b) =>
      a.senderId == b.senderId &&
      _sameDay(a.timestamp, b.timestamp) &&
      b.timestamp.difference(a.timestamp).inMinutes.abs() < 5;

  Widget _buildMessagesArea(
    ChatProvider chatProvider,
    String currentUserId,
    ConversationModel? conversation,
  ) {
    return StreamBuilder<List<MessageModel>>(
      stream: chatProvider.streamMessages(widget.conversationId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ErrorState(message: 'Unable to load messages.');
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const LoadingView();
        }

        final messages = snapshot.data ?? const <MessageModel>[];
        if (!_didInitialScroll && messages.isNotEmpty) {
          _didInitialScroll = true;
          _scrollToBottom(animated: false);
        }

        if (conversation != null && conversation.unreadCount > 0) {
          _markRead();
        }

        if (messages.isEmpty) return _buildEmptyChat(conversation);

        return ListView.builder(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          itemCount: messages.length,
          itemBuilder: (_, index) {
            final message = messages[index];
            final prev = index > 0 ? messages[index - 1] : null;
            final next =
                index < messages.length - 1 ? messages[index + 1] : null;
            final showDate = prev == null ||
                !_sameDay(prev.timestamp, message.timestamp);

            return Column(
              children: [
                if (showDate) _dateSeparator(message.timestamp),
                _buildMessageBubble(
                  message,
                  currentUserId,
                  firstInGroup:
                      showDate || !_sameGroup(prev, message),
                  lastInGroup: next == null || !_sameGroup(message, next),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dateSeparator(DateTime time) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final daysAgo = DateTime(now.year, now.month, now.day)
        .difference(DateTime(time.year, time.month, time.day))
        .inDays;
    final label = daysAgo == 0
        ? 'Today'
        : daysAgo == 1
            ? 'Yesterday'
            : '${weekdays[time.weekday - 1]}, ${months[time.month - 1]} '
                '${time.day}${time.year == now.year ? '' : ', ${time.year}'}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.track,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  /// First-message screen: who you're talking to plus a few one-tap
  /// openers so nobody has to stare at an empty box.
  Widget _buildEmptyChat(ConversationModel? conversation) {
    final name = conversation?.otherUserName ?? '';
    final isLostItem = conversation?.itemType.toLowerCase() == 'lost';
    final suggestions = isLostItem
        ? const [
            'Hi! I think I found your item.',
            'Where did you last have it?',
            'Where can we meet to return it?',
          ]
        : const [
            'Hi! I think this might be mine.',
            'Where exactly did you find it?',
            'When can I pick it up?',
          ];

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                UserAvatar(name: name, size: 76),
                const SizedBox(height: 14),
                Text(
                  name.isEmpty ? 'Say hello' : 'Say hello to $name',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Be friendly and specific. Never share passwords or '
                  'payment details.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 22),
                for (final text in suggestions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        side: BorderSide(color: AppColors.line),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        onTap: () {
                          _messageController.text = text;
                          _messageController.selection =
                              TextSelection.collapsed(offset: text.length);
                          _inputFocus.requestFocus();
                          setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.north_west_rounded,
                                size: 18,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClaimPanel(ClaimModel claim, String currentUserId) {
    final isFinder = claim.ownerId == currentUserId;
    final isClaimant = claim.claimantId == currentUserId;
    if (!isFinder && !isClaimant) return const SizedBox.shrink();

    final pending = claim.status.toLowerCase() == 'pending';
    final rejected = claim.status.toLowerCase() == 'rejected';

    final color = pending
        ? AppColors.warn
        : rejected
            ? AppColors.lost
            : AppColors.found;
    final expanded = _claimExpanded ?? (isFinder && pending);

    final String subtitle;
    if (isFinder && pending) {
      subtitle = '${claim.claimantName} says this is theirs.';
    } else if (isClaimant && pending) {
      subtitle = 'Waiting for the finder to review it.';
    } else if (rejected) {
      subtitle = isClaimant
          ? 'Rejected. You can update your answer and resend.'
          : 'You rejected this claim.';
    } else {
      subtitle = 'This claim was approved.';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - tap to show / hide the answers.
          InkWell(
            onTap: () => setState(() => _claimExpanded = !expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      pending
                          ? Icons.hourglass_top_rounded
                          : rejected
                              ? Icons.cancel_outlined
                              : Icons.verified_rounded,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isFinder ? 'Claim request' : 'Your claim',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                claim.status[0].toUpperCase() +
                                    claim.status.substring(1).toLowerCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.3,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : ConstrainedBox(
                    // Never let the card crowd out the chat itself.
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.34,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _answerBox('Verification answer', claim.answer),
                          if (claim.additionalDetails.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _answerBox(
                              'Additional information',
                              claim.additionalDetails,
                            ),
                          ],
                          if (isFinder && pending) ...[
                            const SizedBox(height: 12),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.checklist_rtl,
                                  size: 18,
                                  color: AppColors.warn,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'To accept or reject, tap the orange '
                                    'button next to the message box.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.warn,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (isClaimant && pending) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Keep chatting here and share more details if '
                              'the finder asks.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                          if (rejected && isClaimant) ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _resendClaim(claim),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Resend claim'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Lost posts: lets the owner confirm the other person returned it.
  /// Any post claimed between these two: shows it's archived (with Undo for
  /// the owner) and when this chat goes away.
  Widget _buildReturnPanel(
    ConversationModel conversation,
    String currentUserId,
  ) {
    // Reuse the stream across rebuilds so the panel doesn't flicker.
    if (_itemStreamPostId != conversation.postId) {
      _itemStreamPostId = conversation.postId;
      _itemStream = context.read<AppDatabase>().watchItem(conversation.postId);
    }

    return StreamBuilder<ItemRow?>(
      stream: _itemStream,
      builder: (context, snapshot) {
        final row = snapshot.data;
        if (row == null) return const SizedBox.shrink();
        final item = ItemRepository.modelFromRow(row);
        final isOwner = item.ownerId == currentUserId;
        final otherId = conversation.otherUserId;
        final otherName = conversation.otherUserName;

        if (item.isClaimed) {
          final betweenUs = isOwner
              ? item.claimedBy == otherId
              : item.claimedBy == currentUserId;
          if (!betweenUs) return const SizedBox.shrink();
          return _returnCard(
            color: AppColors.found,
            icon: Icons.verified_rounded,
            title: item.statusBeforeClaim == 'Found'
                ? 'Item claimed'
                : 'Item returned',
            subtitle: isOwner
                ? 'In your archive. ${ClaimActions.deletesInLabel(item)}, '
                    'along with this chat.'
                : 'This chat is deleted ${ItemModel.archiveDays} days after '
                    'the handover.',
            action: isOwner
                ? TextButton(
                    onPressed: () => ClaimActions.undo(context, item),
                    child: const Text('Undo'),
                  )
                : null,
          );
        }

        if (item.status.toLowerCase() != 'lost' || otherId.isEmpty) {
          return const SizedBox.shrink();
        }

        if (isOwner) {
          return _returnCard(
            color: AppColors.primary,
            icon: Icons.handshake_outlined,
            title: 'Got your item back?',
            subtitle: 'Let $otherName know it reached you.',
            action: FilledButton(
              onPressed: () => ClaimActions.markReturned(
                context,
                item,
                finderId: otherId,
                finderName: otherName,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.found,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text('I got it back'),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            "Returned it? Ask $otherName to tap 'I got it back' in this chat.",
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        );
      },
    );
  }

  Widget _returnCard({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.3,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action],
        ],
      ),
    );
  }

  Widget _answerBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.4,
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'No answer provided.' : value,
            style: TextStyle(
              fontSize: 15.5,
              height: 1.4,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemHeader(ConversationModel conversation) {
    final type = conversation.itemType.isEmpty
        ? ''
        : conversation.itemType[0].toUpperCase() +
            conversation.itemType.substring(1).toLowerCase();

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.track,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            clipBehavior: Clip.antiAlias,
            child: conversation.itemImageUrl.isEmpty
                ? Icon(Icons.image_outlined, color: AppColors.muted)
                : Image(
                    image: CachedNetworkImageProvider(
                      optimizedImageUrl(conversation.itemImageUrl, width: 300),
                      maxWidth: 300,
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.image_outlined,
                      color: AppColors.muted,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chatting about',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  conversation.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          if (type.isNotEmpty) ...[
            const SizedBox(width: 8),
            StatusPill(label: type, color: statusColor(type)),
          ],
        ],
      ),
    );
  }

  /// Long-press on someone else's message -> option to report it.
  Future<void> _showMessageOptions(MessageModel message) async {
    final report = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: ListTile(
          leading: const Icon(Icons.flag_outlined, color: AppColors.lost),
          title: const Text('Report message'),
          subtitle: const Text('Abusive, harassing, scam or spam'),
          onTap: () => Navigator.pop(sheetContext, true),
        ),
      ),
    );
    if (report == true && mounted) {
      await ReportSheet.showForMessage(context, message);
    }
  }

  Widget _buildMessageBubble(
    MessageModel message,
    String currentUserId, {
    required bool firstInGroup,
    required bool lastInGroup,
  }) {
    final isMine = message.senderId == currentUserId;
    final isRemoved = message.text == ReportTarget.removedMessageText;

    const big = Radius.circular(20);
    const small = Radius.circular(6);
    final radius = BorderRadius.only(
      topLeft: !isMine && !firstInGroup ? small : big,
      topRight: isMine && !firstInGroup ? small : big,
      bottomLeft: !isMine && !lastInGroup ? small : (isMine ? big : small),
      bottomRight: isMine && !lastInGroup ? small : (isMine ? small : big),
    );

    final textColor = isRemoved
        ? AppColors.muted
        : isMine
            ? Colors.white
            : AppColors.ink;
    final metaColor = isMine && !isRemoved ? Colors.white70 : AppColors.muted;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMine || isRemoved
            ? null
            : () => _showMessageOptions(message),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * .8,
          ),
          margin: EdgeInsets.only(
            bottom: lastInGroup ? 10 : 3,
            left: isMine ? 48 : 0,
            right: isMine ? 0 : 48,
          ),
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 9),
          decoration: BoxDecoration(
            color: isRemoved
                ? AppColors.track
                : isMine
                    ? AppColors.primary
                    : AppColors.surface,
            borderRadius: radius,
            boxShadow: isMine || isRemoved
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16.5,
                  height: 1.35,
                  fontStyle: isRemoved ? FontStyle.italic : null,
                ),
              ),
              if (lastInGroup) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMessageTime(message.timestamp),
                      style: TextStyle(color: metaColor, fontSize: 12),
                    ),
                    if (isMine && !isRemoved) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 15,
                        color: message.isRead ? Colors.white : metaColor,
                        semanticLabel: message.isRead ? 'Seen' : 'Sent',
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
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
    String tooltip = 'Send';
    if (_isSending) {
      onPressed = null;
      icon = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
      );
    } else if (showOptionsButton) {
      onPressed = () => _showClaimOptions(claim);
      tooltip = 'Review claim';
      icon = const Icon(Icons.checklist_rtl, color: Colors.white);
    } else if (hasText) {
      onPressed = _sendMessage;
      icon = const Icon(Icons.send_rounded, color: Colors.white);
    } else {
      onPressed = null;
      icon = Icon(Icons.send_rounded, color: AppColors.muted);
    }
    final enabled = onPressed != null || _isSending;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _inputFocus,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  style: const TextStyle(fontSize: 16.5, height: 1.3),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Message',
                    filled: true,
                    fillColor: AppColors.bg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(26),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(26),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(26),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: tooltip,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !enabled
                        ? AppColors.track
                        : showOptionsButton
                            ? AppColors.warn
                            : AppColors.primary,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onPressed,
                      child: Center(child: icon),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showClaimOptions(ClaimModel claim) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Claim request',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
                ),
                const SizedBox(height: 4),
                Text(
                  '${claim.claimantName} says this item belongs to them.',
                  style: TextStyle(color: AppColors.muted, fontSize: 15),
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
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.lost,
                        ),
                        icon: const Icon(Icons.close_rounded),
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
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.found,
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Accept claim'),
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
