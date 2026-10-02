import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String date;
  final String status; // Lost, Found, Claimed, Pending
  final String imageUrl;
  final String username;
  final String ownerId;
  final String? verificationQuestion;
  final DateTime? createdAt;

  /// Path to a locally-picked photo that hasn't been uploaded to Cloudinary
  /// yet (set while the item was created offline). Null once [imageUrl] is
  /// available. This never comes from/goes to Firestore - it's populated
  /// only when this model is built from the local offline cache.
  final String? localImagePath;

  /// True while this item has a local create/edit that hasn't reached
  /// Firestore yet (e.g. it was reported while offline and is waiting for
  /// a connection). Always false for items loaded straight from Firestore.
  final bool isSyncPending;

  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.date,
    required this.status,
    required this.imageUrl,
    required this.username,
    this.ownerId = '',
    this.verificationQuestion,
    this.createdAt,
    this.localImagePath,
    this.isSyncPending = false,
  });

  /// Build an ItemModel from a Firestore document.
  factory ItemModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ItemModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      location: data['location'] as String? ?? '',
      date: data['date'] as String? ?? '',
      status: data['status'] as String? ?? 'Pending',
      imageUrl: data['imageUrl'] as String? ?? '',
      username: data['username'] as String? ?? 'Unknown',
      ownerId: data['ownerId'] as String? ?? '',
      verificationQuestion: data['verificationQuestion'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to a map for writing to Firestore. `id` is not included since
  /// it's the document id.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'date': date,
      'status': status,
      'imageUrl': imageUrl,
      'username': username,
      'ownerId': ownerId,
      'verificationQuestion': verificationQuestion,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  ItemModel copyWith({
    String? title,
    String? description,
    String? category,
    String? location,
    String? date,
    String? status,
    String? imageUrl,
    String? username,
    String? ownerId,
    String? verificationQuestion,
    DateTime? createdAt,
    String? localImagePath,
    bool? isSyncPending,
  }) {
    return ItemModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      date: date ?? this.date,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      username: username ?? this.username,
      ownerId: ownerId ?? this.ownerId,
      verificationQuestion: verificationQuestion ?? this.verificationQuestion,
      createdAt: createdAt ?? this.createdAt,
      localImagePath: localImagePath ?? this.localImagePath,
      isSyncPending: isSyncPending ?? this.isSyncPending,
    );
  }
}