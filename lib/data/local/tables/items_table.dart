import 'package:drift/drift.dart';

/// Local cache of the `items` Firestore collection, plus the bookkeeping
/// columns needed to make the app work offline:
///
/// * [synced] - true once this row matches what's on the server.
/// * [pendingCreate] - true for a brand-new item created while offline that
///   has never been written to Firestore yet.
/// * [pendingUpdate] - true when a field changed locally and still needs to
///   be pushed to Firestore.
/// * [pendingDelete] - true when the user deleted the item locally but the
///   delete has not been pushed to Firestore yet. Rows with this flag are
///   hidden from normal queries but kept until the delete is confirmed, so
///   the app never loses a pending change if it's closed early.
/// * [localImagePath] - path to a photo picked while offline, before it has
///   been uploaded to Cloudinary. Once uploaded, [imageUrl] is filled in and
///   this is cleared.
@DataClassName('ItemRow')
class Items extends Table {
  /// Matches the Firestore document id. Firestore can generate this id
  /// locally (no network needed), so offline-created items keep the same id
  /// end-to-end and never need to be "renamed" after syncing.
  TextColumn get id => text()();

  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get location => text().withDefault(const Constant(''))();
  TextColumn get date => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('Pending'))();
  TextColumn get imageUrl => text().withDefault(const Constant(''))();

  /// Local file path for an image that hasn't been uploaded to Cloudinary
  /// yet. Null once [imageUrl] is populated.
  TextColumn get localImagePath => text().nullable()();

  TextColumn get username => text().withDefault(const Constant('Unknown'))();
  TextColumn get ownerId => text().withDefault(const Constant(''))();
  TextColumn get verificationQuestion => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  /// Last time this row changed locally. Used for last-write-wins conflict
  /// resolution against the server's `createdAt`/incoming snapshot data.
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  BoolColumn get synced => boolean().withDefault(const Constant(true))();
  BoolColumn get pendingCreate =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get pendingUpdate =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get pendingDelete =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
