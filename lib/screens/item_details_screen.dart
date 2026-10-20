import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/local/app_database.dart';
import '../data/repositories/claim_repository.dart';
import '../data/repositories/item_repository.dart';
import '../models/claim_model.dart';
import '../models/item_category.dart';
import '../models/item_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/item_ui.dart';
import '../widgets/message_button.dart';
import '../widgets/report_sheet.dart';
import 'claim_item_screen.dart';

/// How far the white content sheet's rounded top overlaps the photo.
const double _sheetOverlap = 28;

/// Shows a post and keeps it current: edits, status changes (e.g. marked
/// claimed) and removals made while it's open - by the owner, another
/// device or an admin - show up without leaving and re-opening the screen.
class ItemDetailsScreen extends StatefulWidget {
  /// The post as it was when opened; shown until the live copy loads (and
  /// used as-is for posts that aren't in the local cache).
  final ItemModel item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  late final Stream<ItemRow?> _live = context.read<AppDatabase>().watchItem(
    widget.item.id,
  );

  /// Whether the local cache has had this post at some point. A post that
  /// was there and then disappears has been deleted.
  bool _seenInCache = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ItemRow?>(
      stream: _live,
      builder: (context, snapshot) {
        final row = snapshot.data;
        if (row != null && !row.pendingDelete) {
          _seenInCache = true;
          return _ItemDetailsView(item: ItemRepository.modelFromRow(row));
        }
        // Being deleted on this device, or it was in the cache and is gone.
        if (row?.pendingDelete == true || (_seenInCache && row == null)) {
          return const _PostGoneView();
        }
        return _ItemDetailsView(item: widget.item);
      },
    );
  }
}

class _PostGoneView extends StatelessWidget {
  const _PostGoneView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Post no longer available',
        message:
            'It was deleted, removed by an admin, or returned to its '
            'owner.',
      ),
    );
  }
}

class _ItemDetailsView extends StatelessWidget {
  final ItemModel item;

  const _ItemDetailsView({required this.item});

  String get _heroTag => 'item_photo_${item.id}';

  void _openPhoto(BuildContext context, int index) {
    final providers = itemImageProviders(item);
    if (providers.isEmpty) return;
    FullScreenImageViewer.show(
      context,
      images: providers,
      initialIndex: index,
      heroTag: '${_heroTag}_$index',
      caption: item.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid =
        context.watch<AuthProvider>().user?.uid ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';
    final type = publicTypeOf(item);
    final accent = statusColor(type);
    final isOwnPost = currentUid.isNotEmpty && currentUid == item.ownerId;
    final hasPhoto = itemImageProvider(item) != null;
    final media = MediaQuery.of(context);
    final heroHeight = (media.size.height * 0.48).clamp(320.0, 480.0);

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
        final hasVerification =
            type == 'Found' &&
            !isOwnPost &&
            (item.verificationQuestion?.trim().isNotEmpty ?? false);

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: CustomScrollView(
            slivers: [
              // PHOTO (tap to open full screen). Collapses into a plain
              // white toolbar that shows the item title.
              SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: heroHeight,
                backgroundColor: AppColors.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leadingWidth: 64,
                leading: Center(
                  child: _circleButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: () => Navigator.maybePop(context),
                  ),
                ),
                actions: [
                  // Report (hidden on your own post and on posts that
                  // haven't reached the server yet).
                  if (!isOwnPost && !item.isSyncPending)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _circleButton(
                        icon: Icons.flag_outlined,
                        tooltip: 'Report post',
                        onTap: () => ReportSheet.showForItem(context, item),
                      ),
                    ),
                ],
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final collapsedHeight = media.padding.top + kToolbarHeight;
                    // 1 when fully expanded, 0 when pinned at the top.
                    final expanded =
                        ((constraints.maxHeight - collapsedHeight) / 80).clamp(
                          0.0,
                          1.0,
                        );

                    return AnnotatedRegion<SystemUiOverlayStyle>(
                      value: expanded > 0.5
                          ? SystemUiOverlayStyle.light
                          : SystemUiOverlayStyle.dark,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ItemImageCarousel(
                            item: item,
                            width: 1200,
                            overlayInsets: EdgeInsets.fromLTRB(
                              16,
                              collapsedHeight + 6,
                              16,
                              _sheetOverlap + 14,
                            ),
                            onTapPhoto: hasPhoto
                                ? (i) => _openPhoto(context, i)
                                : null,
                          ),

                          // Top scrim so the status bar and buttons stay
                          // readable on bright photos.
                          if (hasPhoto)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: collapsedHeight + 40,
                              child: const IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0x66000000),
                                        Color(0x00000000),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          if (hasPhoto)
                            Positioned(
                              right: 16,
                              bottom: _sheetOverlap + 10,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: expanded,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.zoom_out_map_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Tap to view',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Rounded top edge of the content sheet.
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: -1,
                            height: _sheetOverlap + 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(_sheetOverlap),
                                ),
                              ),
                            ),
                          ),

                          // Collapsed toolbar: white with the item title.
                          if (expanded < 1)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: 1 - expanded,
                                  child: Container(
                                    color: AppColors.surface,
                                    padding: EdgeInsets.fromLTRB(
                                      72,
                                      media.padding.top,
                                      72,
                                      0,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                sliver: SliverList.list(
                  children: [
                    // STATUS + TIME
                    Row(
                      children: [
                        StatusPill(label: type, color: accent, large: true),
                        if (isOwnPost) ...[
                          const SizedBox(width: 8),
                          const StatusPill(
                            label: 'Your post',
                            color: AppColors.primary,
                            large: true,
                          ),
                        ],
                        const Spacer(),
                        if (posted.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 17,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                posted,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // TITLE
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.6,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // LOCATION (the most important fact, right under title)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: type == 'Lost'
                                      ? 'Last seen at '
                                      : 'Found at ',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                                TextSpan(
                                  text: item.location,
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(
                              fontSize: 16.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // STATE BANNERS
                    if (item.isSyncPending)
                      _banner(
                        icon: Icons.cloud_upload_outlined,
                        color: AppColors.muted,
                        text:
                            'Waiting for internet. This post will upload '
                            'automatically.',
                      ),
                    if (ownerHasPendingClaim)
                      _banner(
                        icon: Icons.hourglass_top_rounded,
                        color: AppColors.warn,
                        text:
                            'Someone sent a claim for this item. Review '
                            'it in Messages.',
                      ),
                    if (hasPendingClaimFromMe)
                      _banner(
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.warn,
                        text:
                            'Your claim request was sent. The finder will '
                            'review it.',
                      ),
                    if (hasRejectedClaimFromMe)
                      _banner(
                        icon: Icons.cancel_outlined,
                        color: AppColors.lost,
                        text:
                            'Your claim was rejected. You can update your '
                            'answer and resend it.',
                      ),

                    const SizedBox(height: 24),

                    // QUICK FACTS
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _factTile(
                              icon: Icons.category_rounded,
                              color: AppColors.primary,
                              label: 'Category',
                              value: ItemCategory.canonical(item.category),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _factTile(
                              icon: Icons.event_rounded,
                              color: const Color(0xFF7C3AED),
                              label: type == 'Lost'
                                  ? 'Date lost'
                                  : 'Date found',
                              value: item.date,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // DESCRIPTION
                    if (item.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _sectionTitle('About this item'),
                      const SizedBox(height: 10),
                      Text(
                        item.description.trim(),
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.6,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],

                    // OWNERSHIP CHECK
                    if (hasVerification) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              color: AppColors.primary,
                              size: 26,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ownership check',
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'To claim this, you\'ll answer a question '
                                    'only the real owner would know.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.45,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // POSTED BY
                    const SizedBox(height: 28),
                    _sectionTitle(type == 'Lost' ? 'Lost by' : 'Found by'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(color: AppColors.line, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          UserAvatar(
                            name: item.username,
                            photoUrl: item.ownerPhotoUrl,
                            size: 56,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isOwnPost ? 'You' : item.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                if (posted.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Posted $posted',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ACTIONS (hidden on your own post)
          bottomNavigationBar: isOwnPost
              ? null
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _messageButton(
                              context,
                              type: type,
                              primary: type == 'Lost',
                            ),
                          ),
                          if (type == 'Found') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 56,
                                child: FilledButton.icon(
                                  onPressed: hasPendingClaimFromMe
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ClaimItemScreen(
                                                item: item,
                                                isResend:
                                                    hasRejectedClaimFromMe,
                                                initialAnswer:
                                                    hasRejectedClaimFromMe
                                                    ? claim.answer
                                                    : '',
                                                initialDetails:
                                                    hasRejectedClaimFromMe
                                                    ? claim.additionalDetails
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
                                    size: 22,
                                  ),
                                  label: Text(
                                    hasPendingClaimFromMe
                                        ? 'Claim sent'
                                        : hasRejectedClaimFromMe
                                        ? 'Resend claim'
                                        : 'Claim item',
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
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
                ),
        );
      },
    );
  }

  /// The shared [MessageButton], restyled: a filled primary button when it
  /// is the only action (Lost posts), otherwise a large outlined one.
  Widget _messageButton(
    BuildContext context, {
    required String type,
    required bool primary,
  }) {
    final theme = Theme.of(context);
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      textStyle: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
      iconSize: 22,
      foregroundColor: primary ? Colors.white : AppColors.ink,
      backgroundColor: primary ? AppColors.primary : AppColors.surface,
      disabledBackgroundColor: primary
          ? AppColors.primary.withValues(alpha: 0.6)
          : null,
      side: primary
          ? BorderSide.none
          : BorderSide(color: AppColors.line, width: 1.5),
    );

    return Theme(
      data: theme.copyWith(
        outlinedButtonTheme: OutlinedButtonThemeData(style: style),
      ),
      child: SizedBox(
        height: 56,
        child: MessageButton(
          postId: item.id,
          itemName: item.title,
          itemType: type.toUpperCase(),
          otherUserId: item.ownerId,
          otherUserName: item.username,
          imageUrl: item.imageUrl,
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 44,
        child: Material(
          color: Colors.black.withValues(alpha: 0.4),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Icon(icon, color: Colors.white, size: 23),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: AppColors.ink,
      ),
    );
  }

  Widget _factTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value.trim().isEmpty ? '—' : value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: AppColors.ink,
            ),
          ),
        ],
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
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
