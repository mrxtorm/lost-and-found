import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/claim_model.dart';
import '../../models/item_model.dart';
import '../../services/claim_service.dart';
import '../local/app_database.dart';

/// Offline-first access point for claims (a user asserting ownership of a
/// "Found" item). Reads come from Drift; a claim submitted offline is saved
/// locally immediately and pushed to Firestore as soon as there's a
/// connection.
class ClaimRepository {
  final AppDatabase _db;
  final ClaimService _claimService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, StreamSubscription<List<ClaimModel>>> _remoteSubs = {};

  ClaimRepository({
    required AppDatabase database,
    ClaimService? claimService,
  })  : _db = database,
        _claimService = claimService ?? ClaimService();

  /// Starts a live Firestore listener for claims made against items owned
  /// by [ownerId]. Call once per signed-in user (see [stopRemoteSync]).
  void startRemoteSync(String ownerId) {
    if (_remoteSubs.containsKey(ownerId)) return;
    _remoteSubs[ownerId] = _claimService.streamClaimsForOwner(ownerId).listen(
      (serverClaims) {
        _db.syncClaimsFromServer(
          ownerId,
          serverClaims.map(_toCompanion).toList(),
        );
      },
      onError: (_) {},
    );
  }

  void stopRemoteSync(String ownerId) {
    _remoteSubs.remove(ownerId)?.cancel();
  }

  void dispose() {
    for (final sub in _remoteSubs.values) {
      sub.cancel();
    }
    _remoteSubs.clear();
  }

  // ---------------------------------------------------------------------
  // READS
  // ---------------------------------------------------------------------

  Stream<ClaimModel?> watchClaimForItem(String itemId) {
    return _db.watchClaimById(itemId).map((row) {
      if (row == null) return null;

      // Claim data is private even in the local cache. Only the finder or the
      // claimant involved in this claim may receive it from this repository.
      final uid = _auth.currentUser?.uid;
      if (uid == null || (row.ownerId != uid && row.claimantId != uid)) {
        return null;
      }

      return _toModel(row);
    });
  }

  Stream<List<ClaimModel>> watchClaimsForOwner(String ownerId) {
    return _db.watchClaimsForOwner(ownerId).map(
          (rows) => rows.map(_toModel).toList()
            ..sort((a, b) {
              final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            }),
        );
  }

  // ---------------------------------------------------------------------
  // WRITES
  // ---------------------------------------------------------------------

  Future<void> submitClaim({
    required ItemModel item,
    required String answer,
    required String additionalDetails,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to submit a claim.');
    }

    final claimantName =
        (user.displayName != null && user.displayName!.trim().isNotEmpty)
            ? user.displayName!
            : (user.email ?? 'Unknown User');
    final now = DateTime.now();

    // The claim id matches the item id (see ClaimService), so this is
    // idempotent even if pushed more than once.
    await _db.upsertLocalClaim(ClaimsCompanion.insert(
      id: item.id,
      itemId: Value(item.id),
      itemTitle: Value(item.title),
      itemImageUrl: Value(item.imageUrl),
      claimantId: Value(user.uid),
      claimantName: Value(claimantName),
      ownerId: Value(item.ownerId),
      answer: Value(answer),
      additionalDetails: Value(additionalDetails),
      status: const Value('Pending'),
      createdAt: Value(now),
      updatedAt: Value(now),
      synced: const Value(false),
      pendingCreate: const Value(true),
    ));

    // IMPORTANT: claim state is private and stored only in the claims table.
    // Never change the item's public Lost/Found status to Pending.

    unawaited(_pushClaim(item, answer, additionalDetails));
  }

  // ---------------------------------------------------------------------
  // SYNC
  // ---------------------------------------------------------------------

  Future<void> pushPending(String currentUserId) async {
    final pending = await _db.pendingClaimOps();
    for (final row in pending) {
      if (row.claimantId != currentUserId) continue;
      if (!row.pendingCreate) continue;
      final item = ItemModel(
        id: row.itemId,
        title: row.itemTitle,
        description: '',
        category: '',
        location: '',
        date: '',
        status: 'Found',
        imageUrl: row.itemImageUrl,
        username: '',
        ownerId: row.ownerId,
      );
      await _pushClaim(item, row.answer, row.additionalDetails);
    }
  }

  Future<bool> hasPendingWork(String currentUserId) async {
    final pending = await _db.pendingClaimOps();
    return pending.any((row) => row.claimantId == currentUserId);
  }

  Future<void> _pushClaim(
      ItemModel item,
      String answer,
      String additionalDetails,
      ) async {
    try {
      await _claimService.submitClaim(
        item: item,
        answer: answer,
        additionalDetails: additionalDetails,
      );
      await _db.markClaimSynced(item.id);
    } catch (_) {
      // Leave pendingCreate=true - retried on the next sync pass.
    }
  }

  // ---------------------------------------------------------------------
  // MAPPING
  // ---------------------------------------------------------------------

  ClaimsCompanion _toCompanion(ClaimModel claim) {
    return ClaimsCompanion.insert(
      id: claim.id,
      itemId: Value(claim.itemId),
      itemTitle: Value(claim.itemTitle),
      itemImageUrl: Value(claim.itemImageUrl),
      claimantId: Value(claim.claimantId),
      claimantName: Value(claim.claimantName),
      ownerId: Value(claim.ownerId),
      answer: Value(claim.answer),
      additionalDetails: Value(claim.additionalDetails),
      status: Value(claim.status),
      createdAt: Value(claim.createdAt),
      updatedAt: Value(DateTime.now()),
    );
  }

  ClaimModel _toModel(ClaimRow row) {
    return ClaimModel(
      id: row.id,
      itemId: row.itemId,
      itemTitle: row.itemTitle,
      itemImageUrl: row.itemImageUrl,
      claimantId: row.claimantId,
      claimantName: row.claimantName,
      ownerId: row.ownerId,
      answer: row.answer,
      additionalDetails: row.additionalDetails,
      status: row.status,
      createdAt: row.createdAt,
    );
  }
}
