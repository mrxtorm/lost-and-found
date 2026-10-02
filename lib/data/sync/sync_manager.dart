import 'dart:async';

import '../local/connectivity_service.dart';
import '../repositories/chat_repository.dart';
import '../repositories/claim_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/notification_repository.dart';

/// Coordinates pushing every repository's queued offline changes to
/// Firestore/Cloudinary.
///
/// Pulling server data into the local cache happens continuously via each
/// repository's own Firestore listener (started from `startRemoteSync`), so
/// this only needs to handle the "push what's pending" half of syncing:
///  * once on app startup / sign-in,
///  * whenever connectivity comes back after being offline,
///  * on a light retry timer while something is still left pending (e.g.
///    connectivity briefly flickered mid-push, or a request just failed).
class SyncManager {
  final ConnectivityService connectivity;
  final ItemRepository itemRepository;
  final ClaimRepository claimRepository;
  final ChatRepository chatRepository;
  final NotificationRepository notificationRepository;

  StreamSubscription<bool>? _connectivitySub;
  Timer? _retryTimer;
  bool _isSyncing = false;
  String? _currentUserId;

  SyncManager({
    required this.connectivity,
    required this.itemRepository,
    required this.claimRepository,
    required this.chatRepository,
    required this.notificationRepository,
  });

  void start() {
    _connectivitySub = connectivity.onConnectivityChanged.listen((online) {
      if (online) syncNow();
    });
  }

  /// Call whenever the signed-in user changes (including sign-out). Kicks
  /// off an immediate sync for the newly signed-in account.
  void setCurrentUserId(String? uid) {
    _currentUserId = uid;
    _retryTimer?.cancel();
    if (uid != null) syncNow();
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    final uid = _currentUserId;
    if (uid == null) return;

    _isSyncing = true;
    try {
      final online = await connectivity.checkNow();
      if (!online) return;

      await itemRepository.pushPending(uid);
      await claimRepository.pushPending(uid);
      await chatRepository.pushPending(uid);
      await notificationRepository.pushPending(uid);
    } catch (_) {
      // Swallowed - we'll retry on the next connectivity change / timer.
    } finally {
      _isSyncing = false;
      await _scheduleRetryIfNeeded();
    }
  }

  Future<void> _scheduleRetryIfNeeded() async {
    _retryTimer?.cancel();
    final uid = _currentUserId;
    if (uid == null) return;

    final stillPending = await _hasAnyPendingWork(uid);
    if (!stillPending) return;

    _retryTimer = Timer(const Duration(seconds: 30), syncNow);
  }

  Future<bool> _hasAnyPendingWork(String uid) async {
    final results = await Future.wait([
      itemRepository.hasPendingWork(uid),
      claimRepository.hasPendingWork(uid),
      chatRepository.hasPendingWork(uid),
      notificationRepository.hasPendingWork(uid),
    ]);
    return results.any((hasPending) => hasPending);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _retryTimer?.cancel();
  }
}
