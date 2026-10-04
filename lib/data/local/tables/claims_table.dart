import 'package:drift/drift.dart';

/// Local cache of the `claims` Firestore collection. Mirrors [ClaimModel].
///
/// Claims use a deterministic `${itemId}_${claimantId}` document id, so
/// one user cannot create duplicate claims for the same item while multiple
/// users can still claim the same item.
@DataClassName('ClaimRow')
class Claims extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().withDefault(const Constant(''))();
  TextColumn get itemTitle => text().withDefault(const Constant(''))();
  TextColumn get itemImageUrl => text().withDefault(const Constant(''))();
  TextColumn get claimantId => text().withDefault(const Constant(''))();
  TextColumn get claimantName => text().withDefault(const Constant(''))();
  TextColumn get ownerId => text().withDefault(const Constant(''))();
  TextColumn get answer => text().withDefault(const Constant(''))();
  TextColumn get additionalDetails => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('Pending'))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  BoolColumn get synced => boolean().withDefault(const Constant(true))();
  BoolColumn get pendingCreate =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get pendingUpdate =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
