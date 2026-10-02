import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/item_model.dart';
import 'cloudinary_service.dart';

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');

  // ============================================================
  // HOME
  // Returns all posts. Home will exclude the current user's posts.
  // ============================================================

  Stream<List<ItemModel>> streamItems() {
    return _items.snapshots().map((snapshot) {
      final items = snapshot.docs.map(ItemModel.fromDoc).toList();

      items.sort((a, b) {
        final aDate =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return items;
    });
  }

  /// One-off fetch (as opposed to [streamItems]'s live listener). Used for
  /// pull-to-refresh, where the user wants an explicit "check now" rather
  /// than waiting on the listener.
  Future<List<ItemModel>> fetchItemsOnce() async {
    final snapshot = await _items.get();
    final items = snapshot.docs.map(ItemModel.fromDoc).toList();

    items.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return items;
  }

  // ============================================================
  // MY POSTS
  // ============================================================

  Stream<List<ItemModel>> streamUserItems(String ownerId) {
    return _items
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map(ItemModel.fromDoc).toList();

      items.sort((a, b) {
        final aDate =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return items;
    });
  }

  // ============================================================
  // CREATE POST
  // ============================================================

  Future<String> reportItem({
    required String title,
    required String description,
    required String category,
    required String location,
    required String date,
    required String status,
    File? imageFile,
    String? verificationQuestion,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('You must be signed in to report an item.');
    }

    String imageUrl = '';

    // Upload to Cloudinary.
    if (imageFile != null) {
      imageUrl = await _cloudinaryService.uploadImage(imageFile);
    }

    final docRef = _items.doc();

    final username =
    user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (user.email ?? 'Unknown User');

    final item = ItemModel(
      id: docRef.id,
      title: title,
      description: description,
      category: category,
      location: location,
      date: date,
      status: status,
      imageUrl: imageUrl,
      username: username,

      // IMPORTANT
      ownerId: user.uid,

      verificationQuestion: verificationQuestion,
      createdAt: DateTime.now(),
    );

    await docRef.set(item.toMap());

    return docRef.id;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteItem(String itemId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('You must be signed in.');
    }

    final doc = await _items.doc(itemId).get();

    if (!doc.exists) {
      throw Exception('Post not found.');
    }

    final ownerId = doc.data()?['ownerId'];

    if (ownerId != user.uid) {
      throw Exception('You can only delete your own posts.');
    }

    await _items.doc(itemId).delete();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> updateItem(
      String itemId,
      Map<String, dynamic> fields,
      ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('You must be signed in.');
    }

    final doc = await _items.doc(itemId).get();

    if (!doc.exists) {
      throw Exception('Post not found.');
    }

    if (doc.data()?['ownerId'] != user.uid) {
      throw Exception('You can only edit your own posts.');
    }

    await _items.doc(itemId).update(fields);
  }

  Future<void> updateStatus(
      String itemId,
      String status,
      ) async {
    await updateItem(itemId, {
      'status': status,
    });
  }

  // ============================================================
  // OFFLINE SYNC HELPERS
  //
  // These are used by ItemRepository to push a locally-queued change
  // once connectivity returns. Unlike reportItem/updateItem/deleteItem
  // above, they skip the pre-read ownership check: the caller already
  // owns the local record (it's in that user's own cache), and doing a
  // network read first would defeat the point of a fast, offline-aware
  // sync pass.
  // ============================================================

  /// Writes (or overwrites) the item document at [id] with [data]. Used to
  /// push an item that was created while offline, using the same id it was
  /// given locally so it's never duplicated.
  Future<void> setItemDoc(String id, Map<String, dynamic> data) {
    return _items.doc(id).set(data);
  }

  /// Pushes an offline edit for an item that's already known to exist.
  Future<void> updateItemFieldsRaw(String id, Map<String, dynamic> fields) {
    return _items.doc(id).update(fields);
  }

  /// Deletes an item document without first reading it back.
  Future<void> deleteItemRaw(String id) {
    return _items.doc(id).delete();
  }
}