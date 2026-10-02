import 'dart:io';

import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/claim_model.dart';
import '../models/item_model.dart';
import '../screens/item_details_screen.dart';
import '../data/repositories/claim_repository.dart';
import 'message_button.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback? onTap;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  String get publicType {
    // Older data may still have Pending because the previous implementation
    // stored the claim state inside the item. Pending always meant Found.
    final value = item.status.toLowerCase();
    return value == 'pending' || value == 'claimed' ? 'FOUND' : value.toUpperCase();
  }

  Color get typeColor => publicType == 'LOST' ? Colors.red : Colors.green;

  IconData get typeIcon => publicType == 'LOST'
      ? Icons.report_problem
      : Icons.check_circle;

  Widget _buildClaimBadge(ClaimModel claim, String currentUid) {
    final isOwner = claim.ownerId == currentUid;
    final isClaimant = claim.claimantId == currentUid;
    if (!isOwner && !isClaimant) return const SizedBox.shrink();

    final isPending = claim.status.toLowerCase() == 'pending';
    if (!isPending) return const SizedBox.shrink();

    final label = isOwner ? 'CLAIM PENDING' : 'CLAIM REQUEST SENT';
    final icon = isOwner ? Icons.hourglass_top : Icons.check_circle_outline;

    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade700,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 190,
                child: _buildItemImage(),
              ),

              // PUBLIC ITEM TYPE: always Lost/Found and always top-left.
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        publicType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // PRIVATE CLAIM STATE: only owner/claimant can read the claim.
              StreamBuilder<ClaimModel?>(
                stream: context.read<ClaimRepository>().watchClaimForItem(item.id),
                builder: (context, snapshot) {
                  final claim = snapshot.data;
                  if (claim == null || currentUid.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return _buildClaimBadge(claim, currentUid);
                },
              ),

              if (item.isSyncPending)
                Positioned(
                  top: 52,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Waiting for internet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.category_outlined, item.category),
                const SizedBox(height: 7),
                _infoRow(Icons.location_on_outlined, item.location),
                const SizedBox(height: 7),
                _infoRow(Icons.calendar_today_outlined, item.date),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (item.ownerId != currentUid) ...[
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: MessageButton(
                            postId: item.id,
                            itemName: item.title,
                            itemType: publicType,
                            otherUserId: item.ownerId,
                            otherUserName: item.username,
                            imageUrl: item.imageUrl,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ItemDetailsScreen(item: item),
                              ),
                            );
                          },
                          child: const Text(
                            'View Details',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildItemImage() {
    final localPath = item.localImagePath;
    if (item.imageUrl.isEmpty && localPath != null && localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
      );
    }
    if (item.imageUrl.isEmpty) return _buildPlaceholderImage();
    return Image.network(
      item.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(Icons.image_outlined, size: 50, color: Colors.grey.shade400),
      ),
    );
  }
}
