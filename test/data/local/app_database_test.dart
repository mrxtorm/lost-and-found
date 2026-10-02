import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found_app/data/local/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // A fresh in-memory database for every test - no files, no platform
    // channels, so this runs the same on any machine/CI.
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Items - local insert/update/delete', () {
    test('a newly reported item is queryable immediately', () async {
      await db.upsertLocalItem(ItemsCompanion.insert(
        id: 'item-1',
        title: const Value('Blue backpack'),
        ownerId: const Value('user-a'),
        pendingCreate: const Value(true),
        synced: const Value(false),
      ));

      final row = await db.getItem('item-1');
      expect(row, isNotNull);
      expect(row!.title, 'Blue backpack');
      expect(row.pendingCreate, isTrue);
      expect(row.synced, isFalse);
    });

    test('updating an item sets pendingUpdate without touching other fields',
        () async {
      await db.upsertLocalItem(ItemsCompanion.insert(
        id: 'item-1',
        title: const Value('Blue backpack'),
        category: const Value('Bag'),
        ownerId: const Value('user-a'),
        synced: const Value(true),
      ));

      await db.upsertLocalItem(ItemsCompanion(
        id: const Value('item-1'),
        title: const Value('Blue backpack (found near gym)'),
        pendingUpdate: const Value(true),
        synced: const Value(false),
      ));

      final row = await db.getItem('item-1');
      expect(row!.title, 'Blue backpack (found near gym)');
      // Untouched field survives the partial update.
      expect(row.category, 'Bag');
      expect(row.pendingUpdate, isTrue);
    });

    test('deleting an unsynced (pendingCreate) item removes it outright',
        () async {
      await db.upsertLocalItem(ItemsCompanion.insert(
        id: 'item-1',
        ownerId: const Value('user-a'),
        pendingCreate: const Value(true),
        synced: const Value(false),
      ));

      await db.deleteItemRow('item-1');

      expect(await db.getItem('item-1'), isNull);
    });

    test('a synced item marked pendingDelete is hidden from visible queries',
        () async {
      await db.upsertLocalItem(ItemsCompanion.insert(
        id: 'item-1',
        ownerId: const Value('user-a'),
        synced: const Value(true),
      ));

      await db.upsertLocalItem(ItemsCompanion(
        id: const Value('item-1'),
        pendingDelete: const Value(true),
      ));

      final visible = await db.watchVisibleItems('user-a').first;
      expect(visible, isEmpty);

      // But the row itself is still there until the delete is confirmed
      // against the server - so a pending change is never silently lost.
      final row = await db.getItem('item-1');
      expect(row, isNotNull);
      expect(row!.pendingDelete, isTrue);
    });

    test('pendingItemOps returns only rows with an outstanding change',
        () async {
      await db.upsertLocalItem(ItemsCompanion.insert(
        id: 'synced-item',
        ownerId: const Value('user-a'),
        synced: const Value(true),
      ));
      await db.upsertLocalItem(ItemsCompanion.insert(
        id: 'pending-item',
        ownerId: const Value('user-a'),
        pendingCreate: const Value(true),
        synced: const Value(false),
      ));

      final pending = await db.pendingItemOps();
      expect(pending.map((r) => r.id), ['pending-item']);
    });
  });

  group('Items - cross-account visibility', () {
    test('a not-yet-synced item is only visible to its own author',
        () async {
      await db.upsertLocalItem(ItemsCompanion.insert(
        id: 'item-1',
        ownerId: const Value('user-a'),
        pendingCreate: const Value(true),
        synced: const Value(false),
      ));

      final visibleToAuthor = await db.watchVisibleItems('user-a').first;
      expect(visibleToAuthor.map((r) => r.id), ['item-1']);

      final visibleToOther = await db.watchVisibleItems('user-b').first;
      expect(visibleToOther, isEmpty);
    });

    test('once synced, the item becomes visible to everyone', () async {
      await db.upsertLocalItem(ItemsCompanion.insert(
        id: 'item-1',
        ownerId: const Value('user-a'),
        synced: const Value(true),
      ));

      final visibleToOther = await db.watchVisibleItems('user-b').first;
      expect(visibleToOther.map((r) => r.id), ['item-1']);
    });
  });

  group('Items - sync from server', () {
    test('server data overwrites a row with no pending local change',
        () async {
      await db.upsertLocalItem(ItemsCompanion.insert(
        id: 'item-1',
        title: const Value('Old title'),
        ownerId: const Value('user-a'),
        synced: const Value(true),
      ));

      await db.syncItemsFromServer([
        ItemsCompanion.insert(
          id: 'item-1',
          title: const Value('Server title'),
          ownerId: const Value('user-a'),
        ),
      ]);

      final row = await db.getItem('item-1');
      expect(row!.title, 'Server title');
      expect(row.synced, isTrue);
    });

    test('server data does not clobber a row with a pending local edit',
        () async {
      await db.upsertLocalItem(ItemsCompanion.insert(
        id: 'item-1',
        title: const Value('My unsynced edit'),
        ownerId: const Value('user-a'),
        pendingUpdate: const Value(true),
        synced: const Value(false),
      ));

      await db.syncItemsFromServer([
        ItemsCompanion.insert(
          id: 'item-1',
          title: const Value('Stale server title'),
          ownerId: const Value('user-a'),
        ),
      ]);

      final row = await db.getItem('item-1');
      expect(row!.title, 'My unsynced edit');
      expect(row.pendingUpdate, isTrue);
    });

    test('a row removed from the server disappears locally once synced',
        () async {
      await db.upsertLocalItem(ItemsCompanion.insert(
        id: 'item-1',
        ownerId: const Value('user-a'),
        synced: const Value(true),
      ));

      await db.syncItemsFromServer(const []);

      expect(await db.getItem('item-1'), isNull);
    });

    test('a row pending a create/delete is never removed just because it '
        "isn't on the server yet", () async {
      await db.upsertLocalItem(ItemsCompanion.insert(
        id: 'item-1',
        ownerId: const Value('user-a'),
        pendingCreate: const Value(true),
        synced: const Value(false),
      ));

      await db.syncItemsFromServer(const []);

      expect(await db.getItem('item-1'), isNotNull);
    });
  });

  group('Messages - duplicate prevention', () {
    test('re-syncing the same message id does not create a duplicate',
        () async {
      await db.upsertLocalMessage(MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: const Value('conv-1'),
        senderId: const Value('user-a'),
        content: const Value('Hello'),
      ));

      await db.syncMessagesFromServer('conv-1', [
        MessagesCompanion.insert(
          id: 'msg-1',
          conversationId: const Value('conv-1'),
          senderId: const Value('user-a'),
          content: const Value('Hello'),
        ),
      ]);

      final all = await db.watchMessages('conv-1').first;
      expect(all.length, 1);
    });

    test('a pending (unsynced) message is not overwritten by a server sync '
        'that does not include it yet', () async {
      await db.upsertLocalMessage(MessagesCompanion.insert(
        id: 'msg-offline',
        conversationId: const Value('conv-1'),
        senderId: const Value('user-a'),
        content: const Value('Sent while offline'),
        pendingCreate: const Value(true),
        synced: const Value(false),
      ));

      await db.syncMessagesFromServer('conv-1', const []);

      final row = await db.getMessage('msg-offline');
      expect(row, isNotNull);
      expect(row!.pendingCreate, isTrue);
    });

    test('markMessageSynced clears the pending flag', () async {
      await db.upsertLocalMessage(MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: const Value('conv-1'),
        senderId: const Value('user-a'),
        content: const Value('Hi'),
        pendingCreate: const Value(true),
        synced: const Value(false),
      ));

      await db.markMessageSynced('msg-1');

      final row = await db.getMessage('msg-1');
      expect(row!.pendingCreate, isFalse);
      expect(row.synced, isTrue);
    });
  });

  group('Claims', () {
    test('a claim submitted offline is queryable by the item owner',
        () async {
      await db.upsertLocalClaim(ClaimsCompanion.insert(
        id: 'item-1',
        itemId: const Value('item-1'),
        claimantId: const Value('user-b'),
        ownerId: const Value('user-a'),
        status: const Value('Pending'),
        pendingCreate: const Value(true),
        synced: const Value(false),
      ));

      final claims = await db.watchClaimsForOwner('user-a').first;
      expect(claims.map((c) => c.id), ['item-1']);
      expect(claims.single.pendingCreate, isTrue);
    });

    test('markClaimSynced clears the pending flag', () async {
      await db.upsertLocalClaim(ClaimsCompanion.insert(
        id: 'item-1',
        ownerId: const Value('user-a'),
        pendingCreate: const Value(true),
        synced: const Value(false),
      ));

      await db.markClaimSynced('item-1');

      final claims = await db.watchClaimsForOwner('user-a').first;
      expect(claims.single.pendingCreate, isFalse);
      expect(claims.single.synced, isTrue);
    });
  });

  group('Notifications and conversations - offline mark-as-read', () {
    test('marking a notification read locally is optimistic and reversible '
        'once pushed', () async {
      await db.into(db.notifications).insert(NotificationsCompanion.insert(
            id: 'notif-1',
            recipientId: const Value('user-a'),
            isRead: const Value(false),
          ));

      await db.setNotificationReadLocally('notif-1', pending: true);
      var pending = await db.pendingMarkReadNotifications('user-a');
      expect(pending.map((n) => n.id), ['notif-1']);

      await db.clearPendingMarkRead(['notif-1']);
      pending = await db.pendingMarkReadNotifications('user-a');
      expect(pending, isEmpty);
    });

    test('marking a conversation read locally zeroes the unread count',
        () async {
      await db.upsertLocalConversation(ConversationsCompanion.insert(
        id: 'conv-1',
        viewerId: const Value('user-a'),
        unreadCount: const Value(3),
      ));

      await db.setConversationReadLocally('conv-1', pending: true);

      final conversation = await db.getConversation('conv-1');
      expect(conversation!.unreadCount, 0);
      expect(conversation.pendingMarkRead, isTrue);
    });
  });

  group('Account switching', () {
    test('logging out clears synced conversations/notifications for that '
        'account but keeps unsynced ones', () async {
      await db.upsertLocalConversation(ConversationsCompanion.insert(
        id: 'conv-1',
        viewerId: const Value('user-a'),
      ));
      await db.into(db.notifications).insert(NotificationsCompanion.insert(
            id: 'notif-1',
            recipientId: const Value('user-a'),
          ));

      await db.clearUserScopedCacheOnLogout('user-a');

      expect(await db.getConversation('conv-1'), isNull);
      final remainingNotifications =
          await db.watchNotifications('user-a').first;
      expect(remainingNotifications, isEmpty);
    });

    test('logging out never deletes an unsynced (pending) claim', () async {
      await db.upsertLocalClaim(ClaimsCompanion.insert(
        id: 'item-1',
        ownerId: const Value('user-a'),
        pendingCreate: const Value(true),
        synced: const Value(false),
      ));

      await db.clearUserScopedCacheOnLogout('user-a');

      final claims = await db.watchClaimsForOwner('user-a').first;
      expect(claims, isNotEmpty);
    });
  });
}
