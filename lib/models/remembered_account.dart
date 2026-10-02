/// A previously signed-in account, remembered on this device so it can be
/// shown as a quick-pick tile on the login screen - similar to the account
/// switcher on apps like Facebook or Gmail.
///
/// This is intentionally a *local-only, non-secret* record: it never stores
/// a password or auth token, just enough to recognise the account and let
/// the person jump back into the login form with their email already
/// filled in. Because it's persisted with [SharedPreferences] (see
/// [RememberedAccountsService]) it lives entirely on-device, so the list
/// renders instantly even with no network connection.
class RememberedAccount {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime lastSignedInAt;

  const RememberedAccount({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.lastSignedInAt,
  });

  /// What to show as the account's name: falls back to the email (minus
  /// the domain) when no display name was set.
  String get label {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  /// A single initial for the fallback avatar.
  String get initial {
    final source = label.trim();
    return source.isEmpty ? '?' : source[0].toUpperCase();
  }

  RememberedAccount copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? lastSignedInAt,
  }) {
    return RememberedAccount(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      lastSignedInAt: lastSignedInAt ?? this.lastSignedInAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'lastSignedInAt': lastSignedInAt.toIso8601String(),
      };

  factory RememberedAccount.fromJson(Map<String, dynamic> json) {
    return RememberedAccount(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      lastSignedInAt: DateTime.tryParse(json['lastSignedInAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
