import 'package:drift/drift.dart';

/// Local cache of the `notifications` Firestore collection.
///
/// Notifications are only ever created server-side (client-side, but by the
/// *other* user's action - see `NotificationService`), so there's nothing to
/// create offline here, only to cache for offline viewing and to mark as
/// read while offline via [pendingMarkRead].
@DataClassName('NotificationRow')
class Notifications extends Table {
  TextColumn get id => text()();
  TextColumn get recipientId => text().withDefault(const Constant(''))();
  TextColumn get type => text().withDefault(const Constant(''))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get message => text().withDefault(const Constant(''))();
  TextColumn get relatedItemId => text().nullable()();
  TextColumn get relatedClaimId => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();

  /// True once a local "mark as read" still needs to be pushed to Firestore.
  BoolColumn get pendingMarkRead =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
