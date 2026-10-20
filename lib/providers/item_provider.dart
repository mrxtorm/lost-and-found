import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/repositories/item_repository.dart';
import '../models/item_category.dart';
import '../models/item_model.dart';
import '../services/claim_service.dart';
import '../services/item_matching_service.dart';

/// Owns the live list of items and the Home / My Posts filter state, so
/// screens read from here instead of holding their own StreamBuilders and
/// filter variables.
///
/// Data comes from [ItemRepository], which is offline-first: reads are
/// served from the local database immediately, and writes (report/update/
/// delete) are saved locally first and pushed to Firestore/Cloudinary in
/// the background, so none of the methods below need to throw just because
/// the device is offline.
class ItemProvider with ChangeNotifier {
  final ItemRepository _itemRepository;

  StreamSubscription<List<ItemModel>>? _allItemsSub;
  StreamSubscription<List<ItemModel>>? _myItemsSub;

  List<ItemModel> _allItems = [];
  List<ItemModel> _myItems = [];
  bool _isLoadingAll = true;
  bool _isLoadingMine = true;
  String? _currentUserId;

  // Home screen filters.
  String searchQuery = '';
  String selectedStatus = 'All';
  String selectedCategory = 'All';

  // My Posts screen filter. 'Archived' shows claimed posts.
  String myPostsFilter = 'All';

  /// Archived posts already being deleted, so each is purged only once.
  final Set<String> _purging = {};

  ItemProvider(this._itemRepository) {
    // The Firestore listener starts in [setCurrentUserId]: before sign-in
    // (and Terms acceptance) Firestore would refuse it.
    _subscribeAllItems();
  }

  void _subscribeAllItems() {
    _allItemsSub?.cancel();
    _isLoadingAll = true;
    _allItemsSub =
        _itemRepository.watchAllItems(_currentUserId).listen((items) {
          _allItems = items;
          _isLoadingAll = false;
          notifyListeners();
        });
  }

  /// Call this whenever the signed-in user changes (including sign-out)
  /// so "My Posts" tracks the right owner.
  void setCurrentUserId(String? uid) {
    if (uid == _currentUserId) return;
    _currentUserId = uid;
    if (uid == null) {
      _itemRepository.stopRemoteSync();
    } else {
      _itemRepository.restartRemoteSync();
    }
    // The "all items" query also depends on the current user (so an
    // offline-created, not-yet-synced post is still visible to its own
    // author), so it needs to be re-subscribed too.
    _subscribeAllItems();

    _myItemsSub?.cancel();
    _myItems = [];

    if (uid == null) {
      _isLoadingMine = false;
      notifyListeners();
      return;
    }

    _isLoadingMine = true;
    _myItemsSub = _itemRepository.watchUserItems(uid).listen((items) {
      _myItems = items;
      _isLoadingMine = false;
      notifyListeners();
      _purgeExpiredArchive(items);
    });
  }

  /// Pull-to-refresh entry point for the Home screen. The list is already
  /// backed by a live stream, so this doesn't need to do anything with the
  /// result itself - [_itemRepository.refreshItems] updates the local
  /// database, and the existing stream subscription picks that up and
  /// calls [notifyListeners] on its own. Swallow errors (e.g. offline) so
  /// the refresh indicator just settles back down instead of throwing.
  Future<void> refreshHome() async {
    try {
      await _itemRepository.refreshItems();
    } catch (_) {
      // No connection or a transient error - the existing local/live data
      // stays on screen, same as everywhere else in this offline-first app.
    }
  }

  bool get isLoadingAll => _isLoadingAll;
  bool get isLoadingMine => _isLoadingMine;

  /// Items for the Home feed: everyone else's posts, with search/status/
  /// category filters applied.
  List<ItemModel> get homeItems {
    return _allItems.where((item) {
      if (_currentUserId != null && item.ownerId == _currentUserId) {
        return false;
      }
      // Claimed posts wait in their owner's archive; they're done here.
      if (item.isClaimed) return false;

      final query = searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query);

      final matchesStatus = selectedStatus == 'All' ||
          item.status.toLowerCase() == selectedStatus.toLowerCase();

      final matchesCategory = selectedCategory == 'All' ||
          ItemCategory.canonical(item.category) ==
              ItemCategory.canonical(selectedCategory);

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();
  }

  bool get hasActiveHomeFilters =>
      selectedCategory != 'All' ||
          selectedStatus != 'All' ||
          searchQuery.isNotEmpty;

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setSelectedStatus(String value) {
    selectedStatus = value;
    notifyListeners();
  }

  void toggleSelectedCategory(String value) {
    selectedCategory = selectedCategory == value ? 'All' : value;
    notifyListeners();
  }

  void clearHomeFilters() {
    searchQuery = '';
    selectedStatus = 'All';
    selectedCategory = 'All';
    notifyListeners();
  }

  /// Deletes this user's archived (claimed) posts whose archive time is up,
  /// along with their chat. There's no server job for this, so it runs
  /// whenever the owner's posts load; failures (e.g. offline) just retry on
  /// the next load.
  Future<void> _purgeExpiredArchive(List<ItemModel> items) async {
    final now = DateTime.now();
    for (final item in items) {
      final deletesAt = item.archiveDeletesAt;
      if (!item.isClaimed || deletesAt == null || deletesAt.isAfter(now)) {
        continue;
      }
      if (!_purging.add(item.id)) continue;
      try {
        await ClaimService().purgeArchivedItem(item);
        await refreshItem(item.id);
      } catch (_) {
        _purging.remove(item.id);
      }
    }
  }

  /// Pulls one post's latest server state into the cache now (after a
  /// claim, undo or delete). Never throws; the listener catches up anyway.
  Future<void> refreshItem(String itemId) async {
    try {
      await _itemRepository.refreshItem(itemId);
    } catch (_) {}
  }

  /// All of the signed-in user's own posts, ignoring the My Posts filter.
  List<ItemModel> get allMyPosts => _myItems;

  /// The signed-in user's own posts, with the My Posts status filter applied.
  List<ItemModel> get myPosts {
    if (myPostsFilter == 'Archived') {
      return _myItems.where((item) => item.isClaimed).toList();
    }
    if (myPostsFilter == 'All') {
      return _myItems.where((item) => !item.isClaimed).toList();
    }
    return _myItems
        .where((item) =>
    item.status.toLowerCase() == myPostsFilter.toLowerCase())
        .toList();
  }

  void setMyPostsFilter(String value) {
    myPostsFilter = value;
    notifyListeners();
  }

  Future<List<ItemMatch>> findPotentialMatches(String itemId) {
    return _itemRepository.findPotentialMatches(
      itemId,
      currentUserId: _currentUserId,
    );
  }

  Future<List<ItemMatch>> findMatchesForDraft({
    required String title,
    required String category,
    required String status,
  }) {
    return _itemRepository.findMatchesForDraft(
      title: title,
      category: category,
      status: status,
      currentUserId: _currentUserId,
    );
  }

  Future<String> reportItem({
    required String title,
    required String description,
    required String category,
    required String location,
    required String date,
    required String status,
    List<File> imageFiles = const [],
    String? verificationQuestion,
  }) {
    return _itemRepository.reportItem(
      title: title,
      description: description,
      category: category,
      location: location,
      date: date,
      status: status,
      imageFiles: imageFiles,
      verificationQuestion: verificationQuestion,
    );
  }

  Future<void> deleteItem(String itemId) {
    return _itemRepository.deleteItem(itemId);
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> fields) {
    return _itemRepository.updateItem(itemId, fields);
  }

  Future<void> updateStatus(String itemId, String status) {
    return _itemRepository.updateStatus(itemId, status);
  }

  @override
  void dispose() {
    _allItemsSub?.cancel();
    _myItemsSub?.cancel();
    super.dispose();
  }
}