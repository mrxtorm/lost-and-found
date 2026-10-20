import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../models/item_model.dart';
import '../providers/item_provider.dart';
import '../services/claim_service.dart';
import '../theme/app_theme.dart';
import 'app_feedback.dart';
import 'return_feedback_sheet.dart';

/// Confirm-then-act flows for closing a post, shared by the chat screen and
/// My Posts so both ask the same question and say the same thing after.
class ClaimActions {
  ClaimActions._();

  /// "Deletes in 3 days" / "Deletes tomorrow" / "Deletes today".
  static String deletesInLabel(ItemModel item) {
    final deletesAt = item.archiveDeletesAt;
    if (deletesAt == null) return 'Kept in your archive';
    final days = deletesAt.difference(DateTime.now()).inHours / 24;
    if (days <= 1) return days <= 0 ? 'Deletes today' : 'Deletes tomorrow';
    return 'Deletes in ${days.ceil()} days';
  }

  /// The owner of a Lost post confirms they got it back. [finderId] /
  /// [finderName] name who returned it (from a chat); leave them empty when
  /// marking it from My Posts.
  static Future<bool> markReturned(
    BuildContext context,
    ItemModel item, {
    String finderId = '',
    String finderName = '',
  }) async {
    final named = finderId.isNotEmpty;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(named ? 'Got your item back?' : 'Mark as claimed?'),
        content: Text(
          '${named ? 'Confirm that $finderName returned "${item.title}" to you.' : 'Mark "${item.title}" as claimed.'}'
          '\n\nIt moves to your archive and leaves the Home feed. You can '
          'undo this for ${ItemModel.archiveDays} days, then the post'
          '${named ? ' and this chat are' : ' is'} deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.found),
            child: Text(named ? 'Yes, I got it' : 'Mark as claimed'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    final navigator = Navigator.of(context);
    final itemProvider = context.read<ItemProvider>();
    try {
      final returnId = await ClaimService().markLostItemReturned(
        item,
        finderId: finderId,
        finderName: finderName,
      );
      await itemProvider.refreshItem(item.id);
      // Confetti, then the feedback prompt when someone returned it.
      ReturnCompletion.run(navigator, returnId: returnId ?? '');
      return true;
    } catch (e) {
      if (context.mounted) {
        AppSnack.show(context, 'Could not mark it claimed: $e',
            kind: SnackKind.error);
      }
      return false;
    }
  }

  /// Puts an archived post back to Lost/Found.
  static Future<bool> undo(BuildContext context, ItemModel item) async {
    final restored = item.statusBeforeClaim;
    final other = item.claimedByName ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Undo claim?'),
        content: Text(
          '"${item.title}" goes back to ${restored.toLowerCase()} and shows '
          'on the Home feed again.'
          '${other.isEmpty ? '' : ' $other will be notified.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it claimed'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Undo claim'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    final itemProvider = context.read<ItemProvider>();
    try {
      await ClaimService().undoClaim(item);
      await itemProvider.refreshItem(item.id);
      if (context.mounted) {
        AppSnack.show(context, '"${item.title}" is $restored again.',
            kind: SnackKind.success);
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        AppSnack.show(context, 'Could not undo the claim: $e',
            kind: SnackKind.error);
      }
      return false;
    }
  }
}
