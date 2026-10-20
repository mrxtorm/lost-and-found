import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  /// How long a claimed post stays in its owner's archive (where the claim
  /// can still be undone) before it and its chat are deleted for good.
  static const archiveDays = 3;

  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String date;
  final String status; // Lost, Found, Claimed, Pending
  final String imageUrl;

  /// Every uploaded photo URL, in display order. [imageUrl] mirrors the first
  /// entry so older code/documents that only know about one photo still work.
  final List<String> imageUrls;
  final String username;

  /// The author's profile photo URL ('' if none). Kept current on old posts
  /// by ProfileSyncService when the author edits their profile.
  final String ownerPhotoUrl;
  final String ownerId;
  final String? verificationQuestion;
  final DateTime? createdAt;

  /// Path to a locally-picked photo that hasn't been uploaded to Cloudinary
  /// yet (set while the item was created offline). Null once [imageUrl] is
  /// available. This never comes from/goes to Firestore - it's populated
  /// only when this model is built from the local offline cache.
  final String? localImagePath;

  /// Local paths of photos not yet uploaded (offline-created posts).
  final List<String> localImagePaths;

  /// True while this item has a local create/edit that hasn't reached
  /// Firestore yet (e.g. it was reported while offline and is waiting for
  /// a connection). Always false for items loaded straight from Firestore.
  final bool isSyncPending;

  /// When the post was marked Claimed. Null unless [status] is Claimed.
  final DateTime? claimedAt;

  /// The other person in the return: the claimant on a Found post, the
  /// finder on a Lost post. '' when the owner marked it claimed without
  /// naming anyone.
  final String? claimedBy;
  final String? claimedByName;

  /// The status before it was claimed ('Lost' or 'Found'), restored if the
  /// claim is undone.
  final String? claimedFrom;

  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.date,
    required this.status,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.username,
    this.ownerPhotoUrl = '',
    this.ownerId = '',
    this.verificationQuestion,
    this.createdAt,
    this.localImagePath,
    this.localImagePaths = const [],
    this.isSyncPending = false,
    this.claimedAt,
    this.claimedBy,
    this.claimedByName,
    this.claimedFrom,
  });

  bool get isClaimed => status.toLowerCase() == 'claimed';

  /// When an archived (claimed) post gets deleted for good.
  DateTime? get archiveDeletesAt =>
      claimedAt?.add(const Duration(days: archiveDays));

  /// The status to go back to if the claim is undone.
  String get statusBeforeClaim =>
      (claimedFrom == null || claimedFrom!.isEmpty) ? 'Lost' : claimedFrom!;

  /// All photo URLs to display, falling back to the legacy single [imageUrl].
  List<String> get allImageUrls {
    if (imageUrls.isNotEmpty) return imageUrls;
    return imageUrl.isNotEmpty ? [imageUrl] : const [];
  }

  /// All not-yet-uploaded local photo paths, falling back to the legacy
  /// single [localImagePath].
  List<String> get allLocalImagePaths {
    if (localImagePaths.isNotEmpty) return localImagePaths;
    final single = localImagePath;
    return (single != null && single.isNotEmpty) ? [single] : const [];
  }

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
      imageUrls: (data['imageUrls'] as List<dynamic>?)
              ?.whereType<String>()
              .where((u) => u.isNotEmpty)
              .toList() ??
          const [],
      username: data['username'] as String? ?? 'Unknown',
      ownerPhotoUrl: data['ownerPhotoUrl'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      verificationQuestion: data['verificationQuestion'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      claimedAt: (data['claimedAt'] as Timestamp?)?.toDate(),
      claimedBy: data['claimedBy'] as String?,
      claimedByName: data['claimedByName'] as String?,
      claimedFrom: data['claimedFrom'] as String?,
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
      'imageUrls': imageUrls,
      'username': username,
      'ownerPhotoUrl': ownerPhotoUrl,
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
    List<String>? imageUrls,
    String? username,
    String? ownerPhotoUrl,
    String? ownerId,
    String? verificationQuestion,
    DateTime? createdAt,
    String? localImagePath,
    List<String>? localImagePaths,
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
      imageUrls: imageUrls ?? this.imageUrls,
      username: username ?? this.username,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      ownerId: ownerId ?? this.ownerId,
      verificationQuestion: verificationQuestion ?? this.verificationQuestion,
      createdAt: createdAt ?? this.createdAt,
      localImagePath: localImagePath ?? this.localImagePath,
      localImagePaths: localImagePaths ?? this.localImagePaths,
      isSyncPending: isSyncPending ?? this.isSyncPending,
      claimedAt: claimedAt,
      claimedBy: claimedBy,
      claimedByName: claimedByName,
      claimedFrom: claimedFrom,
    );
  }
}