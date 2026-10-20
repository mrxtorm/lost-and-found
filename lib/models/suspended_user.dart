import 'package:cloud_firestore/cloud_firestore.dart';

/// users/{uid} for someone with an active posting suspension
/// (Admin Dashboard > Suspended).
class SuspendedUser {
  final String uid;

  /// Saved when suspended. Empty for suspensions made before names were
  /// recorded; the dashboard then falls back to the moderation history.
  final String displayName;
  final DateTime bannedUntil;
  final int offenseCount;
  final String suspendedBy;
  final DateTime? suspendedAt;

  const SuspendedUser({
    required this.uid,
    required this.displayName,
    required this.bannedUntil,
    required this.offenseCount,
    required this.suspendedBy,
    this.suspendedAt,
  });

  /// Still suspended right now. Check at display time - a suspension can
  /// end while the list is on screen.
  bool get isActive => bannedUntil.isAfter(DateTime.now());

  /// Null when the document has no suspension date (e.g. a pending local
  /// write). Expired suspensions are returned; filter with [isActive].
  static SuspendedUser? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final until = (data['bannedUntil'] as Timestamp?)?.toDate();
    if (until == null) return null;
    return SuspendedUser(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      bannedUntil: until,
      offenseCount: (data['offenseCount'] as num?)?.toInt() ?? 0,
      suspendedBy: data['suspendedBy'] as String? ?? '',
      suspendedAt: (data['suspendedAt'] as Timestamp?)?.toDate(),
    );
  }
}
