import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/notification_repository.dart';
import '../models/notification_model.dart';

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

  StreamSubscription<List<NotificationModel>>? _sub;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _currentUserId;

  NotificationProvider(this._notificationRepository);

  void setCurrentUserId(String? uid) {
    if (uid == _currentUserId) return;
    _currentUserId = uid;
    _sub?.cancel();
    _notifications = [];

    if (uid == null) {
      _notificationRepository.stopRemoteSync();
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

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

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}