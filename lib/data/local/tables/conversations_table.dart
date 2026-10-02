import 'package:drift/drift.dart';

/// Local cache of the `conversations` Firestore collection.
///
/// Conversations are only ever created online (see `ChatRepository`), so
/// there's no `pendingCreate` here - only [pendingMarkRead], for the "mark
/// as read" action done while offline.
///
/// [viewerId] records which signed-in account this cached row belongs to.
/// It's used to make sure one account never sees another account's cached
/// conversations on a shared device (see `AppDatabase.clearUserScopedCache`).
@DataClassName('ConversationRow')
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get viewerId => text().withDefault(const Constant(''))();
  TextColumn get postId => text().withDefault(const Constant(''))();
  TextColumn get itemName => text().withDefault(const Constant('Item'))();
  TextColumn get itemImageUrl => text().withDefault(const Constant(''))();
  TextColumn get itemType => text().withDefault(const Constant(''))();

  /// JSON-encoded `List<String>` of participant ids.
  TextColumn get participantIdsJson =>
      text().withDefault(const Constant('[]'))();

  TextColumn get otherUserId => text().withDefault(const Constant(''))();
  TextColumn get otherUserName => text().withDefault(const Constant('User'))();
  TextColumn get lastMessage => text().withDefault(const Constant(''))();
  DateTimeColumn get lastMessageTime =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  /// True once a local "mark as read" still needs to be pushed to Firestore.
  BoolColumn get pendingMarkRead =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
