import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/remembered_account.dart';
import '../services/auth_service.dart';
import '../services/remembered_accounts_service.dart';

/// Holds the signed-in [User] and exposes auth actions to the UI.
///
/// Screens read [user] / [isSignedIn] via `context.watch` instead of
/// each screen creating its own [AuthService] and juggling `setState`.
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final RememberedAccountsService _rememberedAccountsService =
      RememberedAccountsService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _user = _authService.currentUser;
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Registers a new account. Returns true on success.
  Future<bool> register(String email, String password, String name) {
    return _run(() => _authService.register(email, password, name));
  }

  /// Signs in an existing account. Returns true on success.
  Future<bool> login(String email, String password) {
    return _run(() => _authService.login(email, password));
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Accounts that have signed in on this device before, most-recent first.
  /// Backed by local storage, so this resolves instantly - even offline -
  /// which is what lets the login screen show them without a network call.
  Future<List<RememberedAccount>> getRememberedAccounts() {
    return _rememberedAccountsService.getAccounts();
  }

  /// Removes an account from this device's remembered list (shown on the
  /// login screen). Does not affect the account itself or its data.
  Future<void> forgetRememberedAccount(String uid) {
    return _rememberedAccountsService.forget(uid);
  }

  Future<bool> _run(Future<User?> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await action();
      _user = user;
      if (user != null) {
        // Remember this account on-device so it shows up as a quick-pick
        // tile on the login screen next time - including after signing
        // out, and even without a network connection.
        await _rememberedAccountsService.remember(
          RememberedAccount(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            photoUrl: user.photoURL,
            lastSignedInAt: DateTime.now(),
          ),
        );
      }
      return user != null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
