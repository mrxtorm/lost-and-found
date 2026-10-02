import 'dart:async';

import 'package:drift/drift.dart' show Value;

import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../local/app_database.dart';

/// Offline-first access point for in-app notifications.
///
/// Notifications are only ever created by the server side of another
/// user's action (see `NotificationService`), so there's nothing to create
/// offline here - just caching for offline viewing, and queuing "mark as
/// read" while offline.
class NotificationRepository {
  final AppDatabase _db;
  final NotificationService _notificationService;

  StreamSubscription<List<NotificationModel>>? _remoteSub;
  String? _recipientId;

  NotificationRepository({
    required AppDatabase database,
    NotificationService? notificationService,
  })  : _db = database,
        _notificationService = notificationService ?? NotificationService();

  void startRemoteSync(String recipientId) {
    if (_recipientId == recipientId && _remoteSub != null) return;
    _recipientId = recipientId;
    _remoteSub?.cancel();
    _remoteSub = _notificationService.streamNotifications().listen(
          (serverNotifications) {
        _db.syncNotificationsFromServer(
          recipientId,
          serverNotifications.map(_toCompanion).toList(),
        );
      },
      onError: (_) {},
    );
  }

  void stopRemoteSync() {
    _remoteSub?.cancel();
    _remoteSub = null;
    _recipientId = null;
  }

  void dispose() => stopRemoteSync();

  // ---------------------------------------------------------------------
  // READS
  // ---------------------------------------------------------------------

  Stream<List<NotificationModel>> watchNotifications(String recipientId) {
    return _db
        .watchNotifications(recipientId)
        .map((rows) => rows.map(_toModel).toList());
  }

  /// One-off refresh for pull-to-refresh, same idea as
  /// [ItemRepository.refreshItems]: fetch now, merge through the same
  /// [AppDatabase.syncNotificationsFromServer] path the live listener uses.
  Future<void> refreshNotifications(String recipientId) async {
    final serverNotifications =
    await _notificationService.fetchNotificationsOnce();
    await _db.syncNotificationsFromServer(
      recipientId,
      serverNotifications.map(_toCompanion).toList(),
    );
  }

  // ---------------------------------------------------------------------
  // WRITES
  // ---------------------------------------------------------------------

  Future<void> markAsRead(String notificationId) async {
    await _db.setNotificationReadLocally(notificationId, pending: true);
    try {
      await _notificationService.markAsRead(notificationId);
      await _db.clearPendingMarkRead([notificationId]);
    } catch (_) {
      // Left pending=true - retried on the next sync pass.
    }
  }

  Future<void> markAllAsRead(String recipientId) async {
    await _db.setAllNotificationsReadLocally(recipientId, pending: true);
    try {
      await _notificationService.markAllAsRead();
      final stillPending =
      await _db.pendingMarkReadNotifications(recipientId);
      await _db.clearPendingMarkRead(stillPending.map((n) => n.id).toList());
    } catch (_) {
      // Left pending=true - retried on the next sync pass.
    }
  }

  // ---------------------------------------------------------------------
  // SYNC
  // ---------------------------------------------------------------------

  Future<void> pushPending(String currentUserId) async {
    if (_recipientId != currentUserId) return;
    final pending = await _db.pendingMarkReadNotifications(currentUserId);
    if (pending.isEmpty) return;
    try {
      // Every pending row here is already isRead=true locally; pushing a
      // single markAllAsRead covers all of them and is cheaper than one
      // call per notification.
      await _notificationService.markAllAsRead();
      await _db.clearPendingMarkRead(pending.map((n) => n.id).toList());
    } catch (_) {
      // Retried on the next sync pass.
    }
  }

  Future<bool> hasPendingWork(String currentUserId) async {
    if (_recipientId != currentUserId) return false;
    final pending = await _db.pendingMarkReadNotifications(currentUserId);
    return pending.isNotEmpty;
  }

  // ---------------------------------------------------------------------
  // MAPPING
  // ---------------------------------------------------------------------

  NotificationsCompanion _toCompanion(NotificationModel notification) {
    return NotificationsCompanion.insert(
      id: notification.id,
      recipientId: Value(notification.recipientId),
      type: Value(notification.type),
      title: Value(notification.title),
      message: Value(notification.message),
      relatedItemId: Value(notification.relatedItemId),
      relatedClaimId: Value(notification.relatedClaimId),
      isRead: Value(notification.isRead),
      createdAt: Value(notification.createdAt),
    );
  }

  NotificationModel _toModel(NotificationRow row) {
    return NotificationModel(
      id: row.id,
      recipientId: row.recipientId,
      type: row.type,
      title: row.title,
      message: row.message,
      relatedItemId: row.relatedItemId,
      relatedClaimId: row.relatedClaimId,
      isRead: row.isRead,
      createdAt: row.createdAt,
    );
  }
}