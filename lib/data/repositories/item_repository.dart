import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../models/item_model.dart';
import '../../models/notification_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/item_service.dart';
import '../local/app_database.dart';

/// Offline-first access point for lost/found items.
///
/// Reads always come from [AppDatabase] (Drift/SQLite) so the UI has
/// something to show instantly, even with no connection. Writes are saved
/// to Drift first (so they're never lost and show up immediately), then
/// pushed to Firestore/Cloudinary right away if possible; if that push
/// fails or there's no connection, the row stays flagged as pending and
/// [pushPending] (called by `SyncManager`) retries it later.
class ItemRepository {
  final AppDatabase _db;
  final ItemService _itemService;
  final CloudinaryService _cloudinaryService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<List<ItemModel>>? _remoteSub;

  ItemRepository({
    required AppDatabase database,
    ItemService? itemService,
    CloudinaryService? cloudinaryService,
  })  : _db = database,
        _itemService = itemService ?? ItemService(),
        _cloudinaryService = cloudinaryService ?? CloudinaryService();

  /// Starts a live Firestore listener that keeps the local cache up to
  /// date whenever the app has a connection. Items are public (not scoped
  /// to a signed-in user), so this can run for the app's whole lifetime.
  /// Safe to call more than once - only the first call subscribes.
  void startRemoteSync() {
    _remoteSub ??= _itemService.streamItems().listen(
          (serverItems) {
        _db.syncItemsFromServer(serverItems.map(_toCompanion).toList());
      },
      onError: (_) {
        // No connection, or a transient Firestore error. The local cache
        // keeps serving the UI; the stream retries on its own once
        // connectivity returns.
      },
    );
  }

  void dispose() {
    _remoteSub?.cancel();
  }

  /// One-off refresh for pull-to-refresh. The live listener from
  /// [startRemoteSync] already keeps things up to date while online, but
  /// this gives the UI an explicit "check now" moment - and a real network
  /// round trip to show the refresh indicator for - rather than just
  /// spinning for a fixed delay. Any pending offline edits are left alone,
  /// same as the live listener (see [AppDatabase.syncItemsFromServer]).
  Future<void> refreshItems() async {
    final serverItems = await _itemService.fetchItemsOnce();
    await _db.syncItemsFromServer(serverItems.map(_toCompanion).toList());
  }

  // ---------------------------------------------------------------------
  // READS - always from Drift.
  // ---------------------------------------------------------------------

  /// All items (Home feed). [currentUserId] is used only to make sure an
  /// item this same account created offline - and that hasn't synced yet -
  /// is still visible to its own author.
  Stream<List<ItemModel>> watchAllItems(String? currentUserId) {
    return _db.watchVisibleItems(currentUserId).map(_toModelList);
  }

  Stream<List<ItemModel>> watchUserItems(String ownerId) {
    return _db.watchUserItems(ownerId).map(_toModelList);
  }

  // ---------------------------------------------------------------------
  // WRITES - saved locally first, then pushed opportunistically.
  // ---------------------------------------------------------------------

  Future<String> reportItem({
    required String title,
    required String description,
    required String category,
    required String location,
    required String date,
    required String status,
    File? imageFile,
    String? verificationQuestion,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to report an item.');
    }

    final id = const Uuid().v4();
    final username = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (user.email ?? 'Unknown User');
    final now = DateTime.now();

    await _db.upsertLocalItem(ItemsCompanion.insert(
      id: id,
      title: Value(title),
      description: Value(description),
      category: Value(category),
      location: Value(location),
      date: Value(date),
      status: Value(status),
      imageUrl: const Value(''),
      localImagePath: Value(imageFile?.path),
      username: Value(username),
      ownerId: Value(user.uid),
      verificationQuestion: Value(verificationQuestion),
      createdAt: Value(now),
      updatedAt: Value(now),
      synced: const Value(false),
      pendingCreate: const Value(true),
    ));

    // Best-effort immediate push. If it fails (offline, transient error)
    // the item stays queued locally and the sync manager retries later -
    // the caller never sees that as a failure, since the report is
    // already saved and already visible in the UI.
    unawaited(_pushCreate(id));

    return id;
  }

  Future<void> deleteItem(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in.');
    }

    final row = await _db.getItem(itemId);
    if (row == null) {
      throw Exception('Post not found.');
    }
    if (row.ownerId != user.uid) {
      throw Exception('You can only delete your own posts.');
    }

    if (row.pendingCreate) {
      // Never made it to the server - nothing to delete remotely.
      await _db.deleteItemRow(itemId);
      return;
    }

    await _db.upsertLocalItem(ItemsCompanion(
      id: Value(itemId),
      pendingDelete: const Value(true),
      synced: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));

    unawaited(_pushDelete(itemId));
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> fields) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in.');
    }

    final row = await _db.getItem(itemId);
    if (row == null) {
      throw Exception('Post not found.');
    }
    if (row.ownerId != user.uid) {
      throw Exception('You can only edit your own posts.');
    }

    await _db.upsertLocalItem(ItemsCompanion(
      id: Value(itemId),
      title: fields.containsKey('title')
          ? Value(fields['title'] as String)
          : const Value.absent(),
      description: fields.containsKey('description')
          ? Value(fields['description'] as String)
          : const Value.absent(),
      category: fields.containsKey('category')
          ? Value(fields['category'] as String)
          : const Value.absent(),
      location: fields.containsKey('location')
          ? Value(fields['location'] as String)
          : const Value.absent(),
      date: fields.containsKey('date')
          ? Value(fields['date'] as String)
          : const Value.absent(),
      status: fields.containsKey('status')
          ? Value(fields['status'] as String)
          : const Value.absent(),
      pendingUpdate: const Value(true),
      synced: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));

    unawaited(_pushUpdate(itemId, fields));
  }

  Future<void> updateStatus(String itemId, String status) {
    return updateItem(itemId, {'status': status});
  }

  // ---------------------------------------------------------------------
  // SYNC - called by SyncManager on startup / reconnect / retry.
  // ---------------------------------------------------------------------

  Future<void> pushPending(String currentUserId) async {
    final pending = await _db.pendingItemOps();
    for (final row in pending) {
      // Only push this account's own queued changes.
      if (row.ownerId != currentUserId) continue;
      if (row.pendingDelete) {
        await _pushDelete(row.id);
      } else if (row.pendingCreate) {
        await _pushCreate(row.id);
      } else if (row.pendingUpdate) {
        await _pushFullUpdate(row);
      }
    }
  }

  Future<bool> hasPendingWork(String currentUserId) async {
    final pending = await _db.pendingItemOps();
    return pending.any((row) => row.ownerId == currentUserId);
  }

  Future<void> _pushCreate(String id) async {
    try {
      final row = await _db.getItem(id);
      if (row == null || !row.pendingCreate) return;

      var imageUrl = row.imageUrl;
      if (imageUrl.isEmpty && row.localImagePath != null) {
        imageUrl =
        await _cloudinaryService.uploadImage(File(row.localImagePath!));
      }

      await _itemService.setItemDoc(id, {
        'title': row.title,
        'description': row.description,
        'category': row.category,
        'location': row.location,
        'date': row.date,
        'status': row.status,
        'imageUrl': imageUrl,
        'username': row.username,
        'ownerId': row.ownerId,
        'verificationQuestion': row.verificationQuestion,
        'createdAt': row.createdAt != null
            ? Timestamp.fromDate(row.createdAt!)
            : FieldValue.serverTimestamp(),
      });

      await _db.markItemSynced(id, imageUrl: imageUrl);
      await _notifyReportPosted(row.copyWith(imageUrl: imageUrl));
    } catch (_) {
      // Leave pendingCreate=true - retried on the next sync pass.
    }
  }

  /// Adds a local-only notification (never sent to Firestore) letting the
  /// user know an item they reported - possibly while offline - has now
  /// been successfully posted.
  Future<void> _notifyReportPosted(ItemRow row) async {
    try {
      await _db.insertLocalNotification(NotificationsCompanion.insert(
        id: const Uuid().v4(),
        recipientId: Value(row.ownerId),
        type: const Value(NotificationType.reportPosted),
        title: const Value('Report Posted'),
        message: Value(
          'Your report "${row.title}" is now live and visible to others.',
        ),
        relatedItemId: Value(row.id),
        isRead: const Value(false),
        createdAt: Value(DateTime.now()),
      ));
    } catch (_) {
      // Non-critical - if this fails there's simply no confirmation
      // notification; the item itself already synced successfully.
    }
  }

  Future<void> _pushUpdate(String id, Map<String, dynamic> fields) async {
    try {
      await _itemService.updateItemFieldsRaw(id, fields);
      await _db.markItemSynced(id);
    } catch (_) {
      // Leave pendingUpdate=true - retried on the next sync pass.
    }
  }

  Future<void> _pushFullUpdate(ItemRow row) {
    return _pushUpdate(row.id, {
      'title': row.title,
      'description': row.description,
      'category': row.category,
      'location': row.location,
      'date': row.date,
      'status': row.status,
    });
  }

  Future<void> _pushDelete(String id) async {
    try {
      await _itemService.deleteItemRaw(id);
      await _db.deleteItemRow(id);
    } catch (_) {
      // Leave pendingDelete=true - retried on the next sync pass.
    }
  }

  // ---------------------------------------------------------------------
  // MAPPING
  // ---------------------------------------------------------------------

  ItemsCompanion _toCompanion(ItemModel item) {
    return ItemsCompanion.insert(
      id: item.id,
      title: Value(item.title),
      description: Value(item.description),
      category: Value(item.category),
      location: Value(item.location),
      date: Value(item.date),
      status: Value(item.status),
      imageUrl: Value(item.imageUrl),
      username: Value(item.username),
      ownerId: Value(item.ownerId),
      verificationQuestion: Value(item.verificationQuestion),
      createdAt: Value(item.createdAt),
      updatedAt: Value(DateTime.now()),
    );
  }

  List<ItemModel> _toModelList(List<ItemRow> rows) {
    final models = rows.map(_toModel).toList();
    models.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return models;
  }

  ItemModel _toModel(ItemRow row) {
    return ItemModel(
      id: row.id,
      title: row.title,
      description: row.description,
      category: row.category,
      location: row.location,
      date: row.date,
      status: row.status,
      imageUrl: row.imageUrl,
      username: row.username,
      ownerId: row.ownerId,
      verificationQuestion: row.verificationQuestion,
      createdAt: row.createdAt,
      localImagePath: row.localImagePath,
      isSyncPending: row.pendingCreate || row.pendingUpdate,
    );
  }
}