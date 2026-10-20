import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/claim_repository.dart';
import '../models/claim_model.dart';
import '../models/item_model.dart';
import '../screens/item_details_screen.dart';
import '../theme/app_theme.dart';
import 'item_ui.dart';

/// A feed post: who posted it, the photo, and the item name.
/// Everything else lives on the details screen.
class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback? onTap;

  const ItemCard({super.key, required this.item, this.onTap});

  void _open(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: item)),
    );
  }

  Widget _overlayPill({required Widget leading, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Private claim state: only the finder and the claimant can see it.
  Widget _claimPill(ClaimModel claim, String currentUid) {
    final isOwner = claim.ownerId == currentUid;
    final isClaimant = claim.claimantId == currentUid;
    if (!isOwner && !isClaimant) return const SizedBox.shrink();
    if (claim.status.toLowerCase() != 'pending') {
      return const SizedBox.shrink();
    }

    return _overlayPill(
      leading: Icon(
        isOwner
            ? Icons.hourglass_top_rounded
            : Icons.check_circle_outline_rounded,
        size: 13,
        color: Colors.white,
      ),
      label: isOwner ? 'Claim pending' : 'Claim sent',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final type = publicTypeOf(item);

    final posted = timeAgo(item.createdAt);
    final subtitle = posted.isNotEmpty ? posted : item.date;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        container: true,
        button: true,
        label: '$type item: ${item.title}, posted by ${item.username}'
            '${subtitle.isNotEmpty ? ', $subtitle' : ''}. Double tap to open.',
        child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // WHO POSTED
                Row(
                  children: [
                    UserAvatar(
                      name: item.username,
                      photoUrl: item.ownerPhotoUrl,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    StatusPill(label: type, color: statusColor(type)),
                  ],
                ),
                const SizedBox(height: 12),

                // PHOTO
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ItemImageCarousel(item: item),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              StreamBuilder<ClaimModel?>(
                                stream: context
                                    .read<ClaimRepository>()
                                    .watchClaimForItem(item.id),
                                builder: (context, snapshot) {
                                  final claim = snapshot.data;
                                  if (claim == null || currentUid.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return _claimPill(claim, currentUid);
                                },
                              ),
                              if (item.isSyncPending)
                                _overlayPill(
                                  leading: const SizedBox(
                                    width: 11,
                                    height: 11,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  label: 'Waiting for internet',
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ITEM NAME
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.2,
                    color: AppColors.ink,
                  ),
                ),

                // WHERE
                if (item.location.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${type == 'Lost' ? 'Last seen at' : 'Found at'} '
                          '${item.location.trim()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // WHAT YOU CAN DO (plain-language hint for new users)
                if (item.ownerId != currentUid) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor(type).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          type == 'Lost'
                              ? Icons.chat_bubble_outline_rounded
                              : Icons.back_hand_outlined,
                          size: 18,
                          color: statusColor(type),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            type == 'Lost'
                                ? 'Seen this? Tap to message the owner.'
                                : 'Is this yours? Tap to claim it.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: statusColor(type),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: statusColor(type),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}