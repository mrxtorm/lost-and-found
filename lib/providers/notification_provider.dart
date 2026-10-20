import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/notification_repository.dart';
import '../models/notification_model.dart';
import '../services/notification_preferences_service.dart';

/// Owns the live notifications list and unread count.
///
/// Data comes from [NotificationRepository], which caches notifications
/// locally so they're viewable offline, and queues "mark as read" locally
/// when there's no connection.
///
/// [NotificationRepository] requires a signed-in user, so this only
/// subscribes once [setCurrentUserId] has been called with a real uid
/// (done from [AuthGate] whenever auth state changes).
class NotificationProvider with ChangeNotifier {
  final NotificationRepository _notificationRepository;
  final NotificationPreferencesService _preferencesService =
      NotificationPreferencesService();

  StreamSubscription<List<NotificationModel>>? _sub;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _currentUserId;
  Set<NotificationCategory> _muted = {};

  NotificationProvider(this._notificationRepository);

  void setCurrentUserId(String? uid) {
    if (uid == _currentUserId) return;
    _currentUserId = uid;
    _sub?.cancel();
    _notifications = [];
    _muted = {};

    if (uid == null) {
      _notificationRepository.stopRemoteSync();
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _preferencesService.getMuted(uid).then((muted) {
      if (uid != _currentUserId) return;
      _muted = muted;
      notifyListeners();
    });

    _notificationRepository.startRemoteSync(uid);
    _sub = _notificationRepository.watchNotifications(uid).listen((items) {
      _notifications = items;
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Notifications the user hasn't muted in Notification Settings.
  List<NotificationModel> get notifications =>
      _muted.isEmpty ? _notifications : _notifications.where(_isVisible).toList();
  bool get isLoading => _isLoading;
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  bool _isVisible(NotificationModel n) {
    final category = NotificationCategory.forType(n.type);
    return category == null || !_muted.contains(category);
  }

  bool isCategoryEnabled(NotificationCategory category) =>
      !_muted.contains(category);

  Future<void> setCategoryEnabled(
    NotificationCategory category,
    bool enabled,
  ) async {
    final uid = _currentUserId;
    if (uid == null) return;
    _muted = {..._muted};
    enabled ? _muted.remove(category) : _muted.add(category);
    notifyListeners();
    await _preferencesService.setMuted(uid, _muted);
  }

  /// Pull-to-refresh entry point for the Notifications screen.
  Future<void> refreshNotifications() async {
    final uid = _currentUserId;
    if (uid == null) return;
    try {
      await _notificationRepository.refreshNotifications(uid);
    } catch (_) {
      // No connection or a transient error - keep showing what's cached.
    }
  }

  Future<void> markAsRead(String notificationId) {
    return _notificationRepository.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() {
    final uid = _currentUserId;
    if (uid == null) return Future.value();
    return _notificationRepository.markAllAsRead(uid);
  }

  /// Drops the notification from the in-memory list right away (a swiped
  /// Dismissible must not reappear on the next rebuild), then deletes it.
  Future<void> deleteNotification(String notificationId) {
    _notifications =
        _notifications.where((n) => n.id != notificationId).toList();
    notifyListeners();
    return _notificationRepository.deleteNotification(notificationId);
  }

  Future<void> deleteAllNotifications() {
    final uid = _currentUserId;
    if (uid == null) return Future.value();
    _notifications = [];
    notifyListeners();
    return _notificationRepository.deleteAllNotifications(uid);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}