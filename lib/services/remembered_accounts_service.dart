import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/remembered_account.dart';

/// Persists the list of accounts that have signed in on this device, so the
/// login screen can show them as quick-pick tiles - even after the person
/// signs out, and even with no network connection.
///
/// [SharedPreferences] is local, on-device storage (backed by a plain file
/// on Android/iOS/desktop), so every method here works fully offline. This
/// is deliberately independent of [AppDatabase]/Firestore sync: the account
/// list is device-local by nature and should never require a round trip to
/// the server just to render the login screen.
class RememberedAccountsService {
  static const _storageKey = 'remembered_accounts_v1';

  /// Cap on how many accounts we keep around, oldest dropped first - keeps
  /// the chooser list short and the stored payload small.
  static const _maxAccounts = 5;

  /// Returns the remembered accounts, most recently signed-in first.
  /// Never throws: a corrupt/missing entry is simply skipped.
  Future<List<RememberedAccount>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final accounts = <RememberedAccount>[];
      for (final entry in decoded) {
        try {
          accounts.add(RememberedAccount.fromJson(entry as Map<String, dynamic>));
        } catch (_) {
          // Skip a single malformed entry rather than losing the whole list.
        }
      }
      accounts.sort((a, b) => b.lastSignedInAt.compareTo(a.lastSignedInAt));
      return accounts;
    } catch (_) {
      return [];
    }
  }

  /// Adds (or updates + bumps to most-recent) an account after a
  /// successful login or registration.
  Future<void> remember(RememberedAccount account) async {
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.uid == account.uid);
    accounts.insert(0, account);

    final trimmed = accounts.length > _maxAccounts
        ? accounts.sublist(0, _maxAccounts)
        : accounts;

    await _save(trimmed);
  }

  /// Removes a single account from the device's remembered list (e.g. the
  /// person tapped "Remove" from the account chooser). This never touches
  /// the account itself - only what this device remembers about it.
  Future<void> forget(String uid) async {
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.uid == uid);
    await _save(accounts);
  }

  Future<void> _save(List<RememberedAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
