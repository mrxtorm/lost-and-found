import 'package:drift/drift.dart';

/// Local cache of a conversation's `messages` subcollection.
///
/// [id] is the Firestore message document id. Like items, Firestore can
/// generate this id locally without a network call, so a message written
/// offline keeps a stable id and is never duplicated once it syncs - the
/// sync manager just uploads whatever the local id already is.
@DataClassName('MessageRow')
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text().withDefault(const Constant(''))();
  TextColumn get senderId => text().withDefault(const Constant(''))();
  TextColumn get senderName => text().withDefault(const Constant('User'))();

  /// The message body. Named `content` (not `text`) to avoid clashing with
  /// Drift's `text()` column builder.
  TextColumn get content => text().withDefault(const Constant(''))();
  DateTimeColumn get timestamp =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  BoolColumn get synced => boolean().withDefault(const Constant(true))();
  BoolColumn get pendingCreate =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
