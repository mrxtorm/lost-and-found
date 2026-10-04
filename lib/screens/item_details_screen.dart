import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';

import '../models/claim_model.dart';
import '../data/repositories/claim_repository.dart';
import '../models/item_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/message_button.dart';
import 'claim_item_screen.dart';


class ItemDetailsScreen extends StatelessWidget {
  final ItemModel item;

  const ItemDetailsScreen({
    super.key,
    required this.item,
  });

  String get publicType {
    final value = item.status.toLowerCase();
    return value == 'pending' || value == 'claimed'
        ? 'FOUND'
        : value.toUpperCase();
  }

  Color get typeColor => publicType == 'LOST' ? Colors.red : Colors.green;

  IconData get typeIcon => publicType == 'LOST'
      ? Icons.report_problem
      : Icons.check_circle;

  Widget _buildHeroImage() {
    final localPath = item.localImagePath;
    if (item.imageUrl.isEmpty && localPath != null && localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        width: double.infinity,
        height: 280,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholderImage(),
      );
    }

    if (item.imageUrl.isEmpty) return _placeholderImage();

    return Image.network(
      item.imageUrl,
      width: double.infinity,
      height: 280,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholderImage(),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: double.infinity,
      height: 280,
      color: Colors.grey.shade300,
      child: const Icon(Icons.image, size: 80, color: Colors.grey),
    );
  }

  Widget _publicTypeBadge() {
    return Positioned(
      top: 14,
      left: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: typeColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(typeIcon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              publicType,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _privateClaimBadge(ClaimModel claim, String currentUid) {
    if (claim.status.toLowerCase() != 'pending') {
      return const SizedBox.shrink();
    }

    final isOwner = claim.ownerId == currentUid;
    final isClaimant = claim.claimantId == currentUid;
    if (!isOwner && !isClaimant) return const SizedBox.shrink();

    return Positioned(
      top: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
            Icon(
              isOwner ? Icons.hourglass_top : Icons.check_circle_outline,
              size: 15,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              isOwner ? 'CLAIM PENDING' : 'CLAIM REQUEST SENT',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rejectedClaimBadge() {
    return Positioned(
      top: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, size: 15, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'CLAIM REJECTED',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.watch<AuthProvider>().user?.uid ??
        FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        centerTitle: true,
      ),
      body: StreamBuilder<ClaimModel?>(
        stream: context.read<ClaimRepository>().watchClaimForItem(item.id),
        builder: (context, claimSnapshot) {
          final claim = claimSnapshot.data;

          final isOwnPost = currentUid.isNotEmpty && currentUid == item.ownerId;
          final hasPendingClaimFromMe = claim != null &&
              claim.claimantId == currentUid &&
              claim.status.toLowerCase() == 'pending';
          final hasRejectedClaimFromMe = claim != null &&
              claim.claimantId == currentUid &&
              claim.status.toLowerCase() == 'rejected';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Hero(tag: item.id, child: _buildHeroImage()),
                    _publicTypeBadge(),
                    if (claim != null) _privateClaimBadge(claim, currentUid),
                    if (hasRejectedClaimFromMe) _rejectedClaimBadge(),
                    if (item.isSyncPending)
                      Positioned(
                        top: 58,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Waiting for internet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildDetailRow(
                        icon: Icons.category_outlined,
                        title: 'Category',
                        value: item.category,
                      ),
                      const SizedBox(height: 18),
                      _buildDetailRow(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        value: item.location,
                      ),
                      const SizedBox(height: 18),
                      _buildDetailRow(
                        icon: Icons.calendar_today_outlined,
                        title: 'Date',
                        value: item.date,
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // MESSAGE BUTTON
                      if (!isOwnPost &&
                          (publicType == 'LOST' || publicType == 'FOUND'))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
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

                      // CLAIM / RESEND CLAIM BUTTON
                      // Hidden only while the user's own claim is pending.
                      // After a rejection it becomes "Resend Claim".
                      if (!isOwnPost &&
                          publicType == 'FOUND' &&
                          hasRejectedClaimFromMe)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Text(
                            'Your claim was rejected. You can update your '
                                'answer and resend it.',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),

                      if (!isOwnPost &&
                          publicType == 'FOUND' &&
                          !hasPendingClaimFromMe)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClaimItemScreen(
                                    item: item,
                                    isResend: hasRejectedClaimFromMe,
                                    initialAnswer: hasRejectedClaimFromMe
                                        ? (claim?.answer ?? '')
                                        : '',
                                    initialDetails: hasRejectedClaimFromMe
                                        ? (claim?.additionalDetails ?? '')
                                        : '',
                                  ),
                                ),
                              );
                            },
                            icon: Icon(
                              hasRejectedClaimFromMe
                                  ? Icons.refresh
                                  : Icons.assignment_turned_in,
                            ),
                            label: Text(
                              hasRejectedClaimFromMe
                                  ? 'Resend Claim'
                                  : 'Claim Item',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
