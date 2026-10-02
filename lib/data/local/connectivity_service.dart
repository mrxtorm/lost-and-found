import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around `connectivity_plus` that the rest of the app depends
/// on instead of the plugin directly, so repositories/sync code only need
/// one simple question answered: "is there a network connection right now?"
///
/// Note this reports network *reachability* (e.g. "connected to wifi"), not
/// a guarantee that Firestore/Cloudinary are reachable - repositories and
/// the sync manager still catch failed requests and fall back to queuing
/// locally rather than trusting this alone.
class ConnectivityService {
  final Connectivity _connectivity;
  final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  bool get isOnlineNow => _isOnline;

  /// Emits whenever connectivity flips between online and offline.
  Stream<bool> get onConnectivityChanged => _onlineController.stream;

  Future<void> initialize() async {
    final initial = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(initial);

    _subscription =
        _connectivity.onConnectivityChanged.listen((results) {
      final nowOnline = _hasConnection(results);
      if (nowOnline == _isOnline) return;
      _isOnline = nowOnline;
      _onlineController.add(_isOnline);
    });
  }

  Future<bool> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(result);
    return _isOnline;
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
  }
}
