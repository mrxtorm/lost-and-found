import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/app_database.dart';

/// Copies the signed-in user's current display name (and, on posts, their
/// profile photo) onto everything they created before a profile edit.
///
/// Names are denormalised onto each document when it's written (posts,
/// claims, conversations, messages), so renaming the account alone would
/// leave old activity showing the previous name. Moderation records
/// (reports, moderation log) are deliberately left as they were.
///
/// The last name/photo successfully copied is remembered per account. On every
/// sync [SyncManager] compares it with the account's current name, so a
/// rename made offline, on another device, or before this existed still
/// catches up on its own. The work is idempotent - it always writes the
/// *current* name.
class ProfileSyncService {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Firestore allows 500 writes per batch.
  static const _batchLimit = 450;

  // Read from the server, not the offline cache, so no document is missed;
  // offline this throws and the rename stays pending.
  static const _serverOnly = GetOptions(source: Source.server);

  ProfileSyncService({
    required AppDatabase database,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = database,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static String _syncedKey(String uid) => 'profile_synced_v2_$uid';

  // What has to match for old activity to be up to date.
  String _signature(User user) => '${_nameFor(user)}|${user.photoURL ?? ''}';

  /// Call right after the display name or photo changes. Returns false if the
  /// Firestore part couldn't finish yet (it is retried automatically).
  Future<bool> applyNameChange(String uid) => pushPending(uid);

  Future<bool> hasPendingWork(String uid) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != uid) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_syncedKey(uid)) != _signature(user);
  }

  /// Copies the current name/photo to Firestore if it hasn't been yet.
  /// Returns true when nothing is left to do.
  Future<bool> pushPending(String uid) async {
    if (!await hasPendingWork(uid)) return true;
    final user = _auth.currentUser!;
    final name = _nameFor(user);
    final photoUrl = user.photoURL ?? '';
    try {
      await _db.applyProfileLocally(uid, name, photoUrl);
      // Offline writes would otherwise wait for a connection forever.
      final count =
          await _propagate(uid, name, photoUrl)
              .timeout(const Duration(seconds: 30));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_syncedKey(uid), _signature(user));
      debugPrint('ProfileSync: updated $count document(s) for "$name".');
      return true;
    } catch (e) {
      debugPrint('ProfileSync: rename to "$name" not finished yet: $e');
      return false;
    }
  }

  // Same fallback the repositories use when creating documents.
  String _nameFor(User user) {
    final name = user.displayName?.trim();
    return (name != null && name.isNotEmpty)
        ? name
        : (user.email ?? 'Unknown User');
  }

  /// Returns how many documents were updated.
  Future<int> _propagate(String uid, String name, String photoUrl) async {
    final updates = <(DocumentReference, Map<String, Object?>)>[];

    final items = await _firestore
        .collection('items')
        .where('ownerId', isEqualTo: uid)
        .get(_serverOnly);
    for (final doc in items.docs) {
      final data = doc.data();
      if (data['username'] != name ||
          (data['ownerPhotoUrl'] ?? '') != photoUrl) {
        updates.add((
          doc.reference,
          {'username': name, 'ownerPhotoUrl': photoUrl},
        ));
      }
    }

    final claims = await _firestore
        .collection('claims')
        .where('claimantId', isEqualTo: uid)
        .get(_serverOnly);
    for (final doc in claims.docs) {
      if (doc.data()['claimantName'] != name) {
        updates.add((doc.reference, {'claimantName': name}));
      }
    }

    final conversations = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: uid)
        .get(_serverOnly);
    for (final conversation in conversations.docs) {
      final names = conversation.data()['participantNames'];
      if (names is! Map || names[uid] != name) {
        updates.add((conversation.reference, {'participantNames.$uid': name}));
      }

      final messages = await conversation.reference
          .collection('messages')
          .where('senderId', isEqualTo: uid)
          .get(_serverOnly);
      for (final doc in messages.docs) {
        if (doc.data()['senderName'] != name) {
          updates.add((doc.reference, {'senderName': name}));
        }
      }
    }

    debugPrint(
      'ProfileSync: found ${items.size} post(s), ${claims.size} claim(s), '
      '${conversations.size} chat(s); ${updates.length} need updating.',
    );

    for (var i = 0; i < updates.length; i += _batchLimit) {
      final chunk = updates.skip(i).take(_batchLimit).toList();
      final batch = _firestore.batch();
      for (final (ref, data) in chunk) {
        batch.update(ref, data);
      }
      try {
        await batch.commit();
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
        // One document the rules won't let us rename (e.g. an old-format
        // conversation) shouldn't block the rest: retry one by one and
        // skip only the rejected ones.
        for (final (ref, data) in chunk) {
          try {
            await ref.update(data);
          } on FirebaseException catch (e) {
            if (e.code != 'permission-denied' && e.code != 'not-found') {
              rethrow;
            }
          }
        }
      }
    }
    return updates.length;
  }
}
