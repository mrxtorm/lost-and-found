import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/claim_repository.dart';
import '../models/claim_model.dart';
import '../models/item_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/item_ui.dart';
import '../widgets/message_button.dart';
import 'claim_item_screen.dart';

class ItemDetailsScreen extends StatelessWidget {
  final ItemModel item;

  const ItemDetailsScreen({super.key, required this.item});

  String get _heroTag => 'item_photo_${item.id}';

  void _openPhoto(BuildContext context) {
    final provider = itemImageProvider(item);
    if (provider == null) return;
    FullScreenImageViewer.show(
      context,
      image: provider,
      heroTag: _heroTag,
      caption: item.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.watch<AuthProvider>().user?.uid ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';
    final type = publicTypeOf(item);
    final isOwnPost = currentUid.isNotEmpty && currentUid == item.ownerId;
    final hasPhoto = itemImageProvider(item) != null;

    return StreamBuilder<ClaimModel?>(
      stream: context.read<ClaimRepository>().watchClaimForItem(item.id),
      builder: (context, snapshot) {
        final claim = snapshot.data;
        final claimStatus = claim?.status.toLowerCase();

        final hasPendingClaimFromMe =
            claim != null &&
                claim.claimantId == currentUid &&
                claimStatus == 'pending';
        final hasRejectedClaimFromMe =
            claim != null &&
                claim.claimantId == currentUid &&
                claimStatus == 'rejected';
        final ownerHasPendingClaim =
            claim != null &&
                claim.ownerId == currentUid &&
                claimStatus == 'pending';

        final posted = timeAgo(item.createdAt);

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: CustomScrollView(
            slivers: [
              // PHOTO (tap to open full screen)
              SliverAppBar(
                pinned: true,
                expandedHeight: 360,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                leading: Padding(
                  padding: const EdgeInsets.all(6),
                  child: _circleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: GestureDetector(
                    onTap: hasPhoto ? () => _openPhoto(context) : null,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(tag: _heroTag, child: ItemImage(item: item)),
                        if (hasPhoto)
                          Positioned(
                            right: 14,
                            bottom: 14,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fullscreen_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // TITLE, POSTER, STATE
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusPill(
                        label: type,
                        color: statusColor(type),
                        large: true,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.4,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          UserAvatar(name: item.username, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                if (posted.isNotEmpty)
                                  Text(
                                    'Posted $posted',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (item.isSyncPending)
                        _banner(
                          icon: Icons.cloud_upload_outlined,
                          color: AppColors.muted,
                          text: 'Waiting for internet. This post will upload '
                              'automatically.',
                        ),
                      if (ownerHasPendingClaim)
                        _banner(
                          icon: Icons.hourglass_top_rounded,
                          color: AppColors.warn,
                          text: 'Someone sent a claim for this item. Review '
                              'it in Messages.',
                        ),
                      if (hasPendingClaimFromMe)
                        _banner(
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.warn,
                          text: 'Your claim request was sent. The finder will '
                              'review it.',
                        ),
                      if (hasRejectedClaimFromMe)
                        _banner(
                          icon: Icons.cancel_outlined,
                          color: AppColors.lost,
                          text: 'Your claim was rejected. You can update your '
                              'answer and resend it.',
                        ),
                    ],
                  ),
                ),
              ),

              // CATEGORY / LOCATION / DATE
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _infoRow(
                        Icons.category_outlined,
                        'Category',
                        item.category,
                      ),
                      const SizedBox(height: 16),
                      _infoRow(
                        Icons.location_on_outlined,
                        type == 'Lost' ? 'Last seen' : 'Found at',
                        item.location,
                      ),
                      const SizedBox(height: 16),
                      _infoRow(
                        Icons.calendar_today_outlined,
                        'Date',
                        item.date,
                      ),
                    ],
                  ),
                ),
              ),

              // DESCRIPTION
              if (item.description.trim().isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 15.5,
                            height: 1.5,
                            color: Color(0xFF3B4250),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),

          // ACTIONS (hidden on your own post)
          bottomNavigationBar: isOwnPost
              ? null
              : Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: MessageButton(
                        postId: item.id,
                        itemName: item.title,
                        itemType: type.toUpperCase(),
                        otherUserId: item.ownerId,
                        otherUserName: item.username,
                        imageUrl: item.imageUrl,
                      ),
                    ),
                  ),
                  if (type == 'Found') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: hasPendingClaimFromMe
                              ? null
                              : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClaimItemScreen(
                                  item: item,
                                  isResend: hasRejectedClaimFromMe,
                                  initialAnswer:
                                  hasRejectedClaimFromMe
                                      ? (claim.answer)
                                      : '',
                                  initialDetails:
                                  hasRejectedClaimFromMe
                                      ? (claim
                                      .additionalDetails)
                                      : '',
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            hasPendingClaimFromMe
                                ? Icons.check_rounded
                                : hasRejectedClaimFromMe
                                ? Icons.refresh_rounded
                                : Icons.assignment_turned_in_rounded,
                            size: 20,
                          ),
                          label: Text(
                            hasPendingClaimFromMe
                                ? 'Claim sent'
                                : hasRejectedClaimFromMe
                                ? 'Resend claim'
                                : 'Claim item',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return SizedBox.square(
      dimension: 40,
      child: Material(
        color: Colors.black.withValues(alpha: 0.38),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _banner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}