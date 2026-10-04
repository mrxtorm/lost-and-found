import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/repositories/item_repository.dart';
import '../models/item_model.dart';
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

  // My Posts screen filter.
  String myPostsFilter = 'All';

  ItemProvider(this._itemRepository) {
    _itemRepository.startRemoteSync();
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

      final query = searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query);

      final matchesStatus = selectedStatus == 'All' ||
          item.status.toLowerCase() == selectedStatus.toLowerCase();

      final matchesCategory = selectedCategory == 'All' ||
          item.category.toLowerCase() == selectedCategory.toLowerCase();

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

  /// The signed-in user's own posts, with the My Posts status filter applied.
  List<ItemModel> get myPosts {
    if (myPostsFilter == 'All') return _myItems;
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
    File? imageFile,
    String? verificationQuestion,
  }) {
    return _itemRepository.reportItem(
      title: title,
      description: description,
      category: category,
      location: location,
      date: date,
      status: status,
      imageFile: imageFile,
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