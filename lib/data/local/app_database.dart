import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables/claims_table.dart';
import 'tables/conversations_table.dart';
import 'tables/items_table.dart';
import 'tables/messages_table.dart';
import 'tables/notifications_table.dart';

part 'app_database.g.dart';

/// The app's offline-first local database.
///
/// This is the local source of truth the UI reads from. Firestore remains
/// the cloud source of truth; a [SyncManager] (see `lib/data/sync/`) keeps
/// the two in sync in both directions.
@DriftDatabase(
  tables: [Items, Claims, Conversations, Messages, Notifications],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Used by tests to run entirely in memory.
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  // ===========================================================================
  // ITEMS
  // ===========================================================================

  /// All items visible on the Home feed: not deleted, and - for items that
  /// were created offline and haven't synced yet - visible only to the
  /// account that created them (so a not-yet-confirmed post never leaks to
  /// another account signed in on the same device).
  Stream<List<ItemRow>> watchVisibleItems(String? currentUserId) {
    final query = select(items)
      ..where(
            (t) =>
        t.pendingDelete.equals(false) &
        (t.pendingCreate.equals(false) |
        t.ownerId.equals(currentUserId ?? '')),
      );
    return query.watch();
  }

  /// A single user's own posts (My Posts screen).
  Stream<List<ItemRow>> watchUserItems(String ownerId) {
    final query = select(items)
      ..where(
            (t) => t.pendingDelete.equals(false) & t.ownerId.equals(ownerId),
      );
    return query.watch();
  }

  Future<ItemRow?> getItem(String id) {
    return (select(items)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Returns all locally cached, non-deleted items for offline matching.
  ///
  /// Matching is filtered in Dart so it works without requiring a new
  /// Firestore/SQLite composite index.
  Future<List<ItemRow>> getItemsForMatching() {
    return (select(items)
      ..where((t) => t.pendingDelete.equals(false)))
        .get();
  }

  /// Inserts or updates a single item as a local (not-yet-synced) write.
  Future<void> upsertLocalItem(ItemsCompanion row) {
    return into(items).insertOnConflictUpdate(row);
  }

  /// Clears the pending flags on an item once it's confirmed on the server,
  /// optionally recording the Cloudinary URL that resulted from an offline
  /// image upload.
  Future<void> markItemSynced(String id, {String? imageUrl}) {
    return (update(items)..where((t) => t.id.equals(id))).write(
      ItemsCompanion(
        synced: const Value(true),
        pendingCreate: const Value(false),
        pendingUpdate: const Value(false),
        imageUrl: imageUrl == null ? const Value.absent() : Value(imageUrl),
        localImagePath: imageUrl == null
            ? const Value.absent()
            : const Value(null),
      ),
    );
  }

  Future<void> deleteItemRow(String id) {
    return (delete(items)..where((t) => t.id.equals(id))).go();
  }

  Future<List<ItemRow>> pendingItemOps() {
    return (select(items)
      ..where(
            (t) =>
        t.pendingCreate.equals(true) |
        t.pendingUpdate.equals(true) |
        t.pendingDelete.equals(true),
      ))
        .get();
  }

  /// Merges a page of server truth into the local cache: rows without a
  /// local pending change are overwritten with the server's data; rows
  /// with a pending change are left alone until they've been pushed.
  /// Local rows that are no longer present on the server (and have no
  /// pending change of their own) are removed - they were deleted remotely.
  Future<void> syncItemsFromServer(List<ItemsCompanion> serverRows) async {
    await transaction(() async {
      final serverIds = serverRows.map((r) => r.id.value).toSet();
      final localRows = await select(items).get();
      final localById = {for (final r in localRows) r.id: r};

      for (final serverRow in serverRows) {
        final local = localById[serverRow.id.value];
        final hasPendingChange = local != null &&
            (local.pendingCreate || local.pendingUpdate || local.pendingDelete);
        if (hasPendingChange) continue;
        await into(items).insertOnConflictUpdate(
          serverRow.copyWith(
            synced: const Value(true),
            pendingCreate: const Value(false),
            pendingUpdate: const Value(false),
            pendingDelete: const Value(false),
          ),
        );
      }

      for (final local in localRows) {
        final stillOnServer = serverIds.contains(local.id);
        final hasPendingChange =
            local.pendingCreate || local.pendingUpdate || local.pendingDelete;
        if (!stillOnServer && !hasPendingChange) {
          await deleteItemRow(local.id);
        }
      }
    });
  }

  // ===========================================================================
  // CLAIMS
  // ===========================================================================

  Stream<List<ClaimRow>> watchClaimsForOwner(String ownerId) {
    return (select(claims)..where((t) => t.ownerId.equals(ownerId))).watch();
  }

  Stream<ClaimRow?> watchClaimById(String id) {
    return (select(claims)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Stream<List<ClaimRow>> watchClaimsForItem(String itemId) {
    return (select(claims)..where((t) => t.itemId.equals(itemId))).watch();
  }

  Future<void> upsertLocalClaim(ClaimsCompanion row) {
    return into(claims).insertOnConflictUpdate(row);
  }

  Future<void> deleteClaimRow(String id) {
    return (delete(claims)..where((t) => t.id.equals(id))).go();
  }

  Future<void> markClaimSynced(String id) {
    return (update(claims)..where((t) => t.id.equals(id))).write(
      const ClaimsCompanion(
        synced: Value(true),
        pendingCreate: Value(false),
        pendingUpdate: Value(false),
      ),
    );
  }

  Future<List<ClaimRow>> pendingClaimOps() {
    return (select(claims)
      ..where(
            (t) => t.pendingCreate.equals(true) | t.pendingUpdate.equals(true),
      ))
        .get();
  }

  Future<void> syncClaimsFromServer(
      String ownerId,
      List<ClaimsCompanion> serverRows,
      ) async {
    await transaction(() async {
      final serverIds = serverRows.map((r) => r.id.value).toSet();
      final localRows =
      await (select(claims)..where((t) => t.ownerId.equals(ownerId)))
          .get();
      final localById = {for (final r in localRows) r.id: r};

      for (final serverRow in serverRows) {
        final local = localById[serverRow.id.value];
        final hasPendingChange =
            local != null && (local.pendingCreate || local.pendingUpdate);
        if (hasPendingChange) continue;
        await into(claims).insertOnConflictUpdate(
          serverRow.copyWith(
            synced: const Value(true),
            pendingCreate: const Value(false),
            pendingUpdate: const Value(false),
          ),
        );
      }

      for (final local in localRows) {
        final hasPendingChange = local.pendingCreate || local.pendingUpdate;
        if (!serverIds.contains(local.id) && !hasPendingChange) {
          await (delete(claims)..where((t) => t.id.equals(local.id))).go();
        }
      }
    });
  }

  // ===========================================================================
  // CONVERSATIONS
  // ===========================================================================

  Stream<List<ConversationRow>> watchConversations(String viewerId) {
    return (select(conversations)
      ..where((t) => t.viewerId.equals(viewerId))
      ..orderBy([(t) => OrderingTerm.desc(t.lastMessageTime)]))
        .watch();
  }

  Future<ConversationRow?> getConversation(String id) {
    return (select(conversations)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertLocalConversation(ConversationsCompanion row) {
    return into(conversations).insertOnConflictUpdate(row);
  }

  Future<void> setConversationReadLocally(
      String id, {
        required bool pending,
      }) {
    return (update(conversations)..where((t) => t.id.equals(id))).write(
      ConversationsCompanion(
        unreadCount: const Value(0),
        pendingMarkRead: Value(pending),
      ),
    );
  }

  Future<List<ConversationRow>> pendingMarkReadConversations(
      String viewerId,
      ) {
    return (select(conversations)
      ..where(
            (t) =>
        t.viewerId.equals(viewerId) & t.pendingMarkRead.equals(true),
      ))
        .get();
  }

  Future<void> syncConversationsFromServer(
      String viewerId,
      List<ConversationsCompanion> serverRows,
      ) async {
    await transaction(() async {
      final localRows =
      await (select(conversations)..where((t) => t.viewerId.equals(viewerId)))
          .get();
      final localById = {for (final r in localRows) r.id: r};

      for (final serverRow in serverRows) {
        final local = localById[serverRow.id.value];
        // A pending local "mark as read" hasn't reached the server yet, so
        // keep showing 0 unread locally instead of the server's stale count.
        if (local != null && local.pendingMarkRead) {
          await into(conversations).insertOnConflictUpdate(
            serverRow.copyWith(
              unreadCount: const Value(0),
              pendingMarkRead: const Value(true),
            ),
          );
        } else {
          await into(conversations).insertOnConflictUpdate(serverRow);
        }
      }

      // Firestore is the source of truth. If a conversation disappeared from
      // the server (for example, after a claim was accepted), remove its local
      // messages and conversation too so private data does not remain cached.
      final serverIds = serverRows.map((r) => r.id.value).toSet();
      for (final local in localRows) {
        if (serverIds.contains(local.id) || local.pendingMarkRead) continue;

        await (delete(messages)
              ..where((t) => t.conversationId.equals(local.id)))
            .go();
        await (delete(conversations)
              ..where((t) => t.id.equals(local.id)))
            .go();
      }
    });
  }

  // ===========================================================================
  // MESSAGES
  // ===========================================================================

  Stream<List<MessageRow>> watchMessages(String conversationId) {
    return (select(messages)
      ..where((t) => t.conversationId.equals(conversationId))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .watch();
  }

  Future<void> upsertLocalMessage(MessagesCompanion row) {
    return into(messages).insertOnConflictUpdate(row);
  }

  Future<MessageRow?> getMessage(String id) {
    return (select(messages)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> markMessageSynced(String id) {
    return (update(messages)..where((t) => t.id.equals(id))).write(
      const MessagesCompanion(synced: Value(true), pendingCreate: Value(false)),
    );
  }

  Future<List<MessageRow>> pendingMessageOps(String conversationId) {
    return (select(messages)
      ..where(
            (t) =>
        t.conversationId.equals(conversationId) &
        t.pendingCreate.equals(true),
      ))
        .get();
  }

  Future<List<MessageRow>> allPendingMessageOps() {
    return (select(messages)..where((t) => t.pendingCreate.equals(true)))
        .get();
  }

  Future<void> syncMessagesFromServer(
      String conversationId,
      List<MessagesCompanion> serverRows,
      ) async {
    await transaction(() async {
      final localRows = await (select(messages)
        ..where((t) => t.conversationId.equals(conversationId)))
          .get();
      final localById = {for (final r in localRows) r.id: r};

      for (final serverRow in serverRows) {
        final local = localById[serverRow.id.value];
        if (local != null && local.pendingCreate) continue;
        await into(messages).insertOnConflictUpdate(
          serverRow.copyWith(
            synced: const Value(true),
            pendingCreate: const Value(false),
          ),
        );
      }
    });
  }

  Future<void> syncClaimsForClaimantFromServer(
      String claimantId,
      List<ClaimsCompanion> serverRows,
      ) async {
    await transaction(() async {
      final serverIds = serverRows.map((r) => r.id.value).toSet();
      final localRows = await (select(claims)
            ..where((t) => t.claimantId.equals(claimantId)))
          .get();
      final localById = {for (final r in localRows) r.id: r};

      for (final serverRow in serverRows) {
        final local = localById[serverRow.id.value];
        final hasPendingChange =
            local != null && (local.pendingCreate || local.pendingUpdate);
        if (hasPendingChange) continue;
        await into(claims).insertOnConflictUpdate(
          serverRow.copyWith(
            synced: const Value(true),
            pendingCreate: const Value(false),
            pendingUpdate: const Value(false),
          ),
        );
      }

      for (final local in localRows) {
        final hasPendingChange = local.pendingCreate || local.pendingUpdate;
        if (!serverIds.contains(local.id) && !hasPendingChange) {
          await (delete(claims)..where((t) => t.id.equals(local.id))).go();
        }
      }
    });
  }

  // ===========================================================================
  // NOTIFICATIONS
  // ===========================================================================

  Stream<List<NotificationRow>> watchNotifications(String recipientId) {
    return (select(notifications)
      ..where((t) => t.recipientId.equals(recipientId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Inserts a notification that originates purely on this device (never
  /// pushed to Firestore) - e.g. "your offline report just finished
  /// syncing". Safe to call even while offline; it's a plain local write.
  Future<void> insertLocalNotification(NotificationsCompanion row) {
    return into(notifications).insertOnConflictUpdate(row);
  }

  Future<void> setNotificationReadLocally(
      String id, {
        required bool pending,
      }) {
    return (update(notifications)..where((t) => t.id.equals(id))).write(
      NotificationsCompanion(
        isRead: const Value(true),
        pendingMarkRead: Value(pending),
      ),
    );
  }

  Future<void> setAllNotificationsReadLocally(
      String recipientId, {
        required bool pending,
      }) async {
    await (update(notifications)
      ..where((t) => t.recipientId.equals(recipientId)))
        .write(
      NotificationsCompanion(
        isRead: const Value(true),
        pendingMarkRead: Value(pending),
      ),
    );
  }

  Future<List<NotificationRow>> pendingMarkReadNotifications(
      String recipientId,
      ) {
    return (select(notifications)
      ..where(
            (t) =>
        t.recipientId.equals(recipientId) &
        t.pendingMarkRead.equals(true),
      ))
        .get();
  }

  Future<void> clearPendingMarkRead(List<String> ids) async {
    if (ids.isEmpty) return;
    await (update(notifications)..where((t) => t.id.isIn(ids)))
        .write(const NotificationsCompanion(pendingMarkRead: Value(false)));
  }

  Future<void> syncNotificationsFromServer(
      String recipientId,
      List<NotificationsCompanion> serverRows,
      ) async {
    await transaction(() async {
      final localRows = await (select(notifications)
        ..where((t) => t.recipientId.equals(recipientId)))
          .get();
      final localById = {for (final r in localRows) r.id: r};

      for (final serverRow in serverRows) {
        final local = localById[serverRow.id.value];
        if (local != null && local.pendingMarkRead) {
          // Keep the optimistic isRead=true until the push actually lands.
          await into(notifications).insertOnConflictUpdate(
            serverRow.copyWith(
              isRead: const Value(true),
              pendingMarkRead: const Value(true),
            ),
          );
        } else {
          await into(notifications).insertOnConflictUpdate(serverRow);
        }

        // Approved claims are deleted from Firestore together with the item
        // and conversation. Remove the claimant's cached private claim when
        // the approval notification arrives as well.
        if (serverRow.type.value == 'claim_approved' &&
            serverRow.relatedClaimId.value != null) {
          await deleteClaimRow(serverRow.relatedClaimId.value!);
        }
      }
    });
  }

  // ===========================================================================
  // ACCOUNT SWITCHING / LOGOUT
  // ===========================================================================

  /// Clears cached data that's private to [signedOutUserId] so it isn't
  /// visible if a different account signs in on this device afterwards.
  /// Anything still pending sync is left alone so it isn't lost - it will
  /// sync the next time this same account is online.
  Future<void> clearUserScopedCacheOnLogout(String signedOutUserId) async {
    await transaction(() async {
      await (delete(conversations)
        ..where((t) => t.viewerId.equals(signedOutUserId)))
          .go();
      await (delete(notifications)
        ..where((t) => t.recipientId.equals(signedOutUserId)))
          .go();
      // Claims the outgoing user owns (as the item owner) are private to
      // them too; anything already pushed to the server can simply be
      // re-downloaded next time they sign in.
      await (delete(claims)
        ..where(
              (t) => t.ownerId.equals(signedOutUserId) & t.pendingCreate.equals(false) & t.pendingUpdate.equals(false),
        ))
          .go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Make sure a native sqlite3 library is available on this platform.
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'lost_and_found.sqlite'));
    return NativeDatabase.createInBackground(file, setup: (db) {
      db.execute('PRAGMA foreign_keys = ON;');
    });
  });
}