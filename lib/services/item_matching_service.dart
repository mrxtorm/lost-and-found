import '../models/item_model.dart';

/// Dependency-free matcher for "possible matches".
///
/// A candidate is shown only when it is the OPPOSITE report type
/// (Lost <-> Found) AND its item name shares a keyword with the new report.
/// Same category is NOT enough on its own - it only ranks name matches higher.
class ItemMatchingService {
  /// Words that carry no identifying meaning.
  static const Set<String> _stopWords = {
    'a', 'an', 'the', 'of', 'my', 'and', 'with', 'for', 'in', 'on',
    'lost', 'found', 'new', 'old', 'small', 'big', 'large', 'medium',
    'black', 'white', 'blue', 'red', 'green', 'yellow', 'pink', 'gray',
    'grey', 'brown', 'orange', 'purple',
  };

  /// Different words that mean the same thing, mapped to one keyword.
  /// Add more here as you notice gaps (keys are already lowercase/singular).
  static const Map<String, String> _synonyms = {
    // phones
    'mobile': 'phone',
    'cellphone': 'phone',
    'cell': 'phone',
    'smartphone': 'phone',
    'telephone': 'phone',
    'iphone': 'phone',
    'android': 'phone',
    // tablets
    'ipad': 'tablet',
    'tab': 'tablet',
    // laptops
    'macbook': 'laptop',
    // audio
    'earphone': 'earphone',
    'earbud': 'earphone',
    'headphone': 'earphone',
    'headset': 'earphone',
    'airpod': 'earphone',
    // wallets
    'purse': 'wallet',
    'billfold': 'wallet',
    // keys
    'keychain': 'key',
    'keyring': 'key',
    // bags
    'backpack': 'bag',
    'handbag': 'bag',
    'knapsack': 'bag',
    // bottles
    'tumbler': 'bottle',
    'flask': 'bottle',
    // glasses
    'eyeglass': 'glasse',
    'eyeglasse': 'glasse',
    'spectacle': 'glasse',
  };

  /// Accessories/parts. A phone should not match a phone charger, and a
  /// laptop charger should not match a phone charger.
  static const Set<String> _accessoryWords = {
    'charger', 'cable', 'adapter', 'case', 'cover', 'protector', 'strap',
    'holder', 'pouch', 'sleeve', 'lanyard', 'stand', 'mount',
  };

  /// Matches for an item that is already saved.
  static List<ItemMatch> findMatches({
    required ItemModel item,
    required Iterable<ItemModel> candidates,
    String? currentUserId,
  }) {
    return findMatchesForDraft(
      title: item.title,
      category: item.category,
      status: item.status,
      candidates: candidates,
      currentUserId: currentUserId,
      excludeItemId: item.id,
    );
  }

  /// Matches for a report that has NOT been submitted yet.
  static List<ItemMatch> findMatchesForDraft({
    required String title,
    required String category,
    required String status,
    required Iterable<ItemModel> candidates,
    String? currentUserId,
    String? excludeItemId,
    int limit = 10,
  }) {
    final draftType = _reportType(status);
    if (draftType == null) return const [];

    final draftCategory = _normalize(category);
    final draftName = _normalize(title);
    final draftTokens = _keywords(title);

    // Nothing meaningful to compare (e.g. the name was only "black").
    if (draftTokens.isEmpty) return const [];

    final matches = <ItemMatch>[];

    for (final candidate in candidates) {
      if (excludeItemId != null && candidate.id == excludeItemId) continue;

      // Never suggest the user's own posts.
      if (currentUserId != null &&
          currentUserId.isNotEmpty &&
          candidate.ownerId == currentUserId) {
        continue;
      }

      // Lost <-> Found only.
      final candidateType = _reportType(candidate.status);
      if (candidateType == null || candidateType == draftType) continue;

      // 1) The item names must share at least one keyword.
      final candidateTokens = _keywords(candidate.title);
      final shared = draftTokens.intersection(candidateTokens);
      if (shared.isEmpty) continue;

      // 2) Accessory guard: "phone" must not match "phone charger".
      final draftAccessories = draftTokens.intersection(_accessoryWords);
      final candidateAccessories =
      candidateTokens.intersection(_accessoryWords);
      if (draftAccessories.length != candidateAccessories.length ||
          !draftAccessories.containsAll(candidateAccessories)) {
        continue;
      }

      // 3) If the only shared word is an accessory word ("charger"), the
      //    devices they belong to must not conflict
      //    ("phone charger" vs "laptop charger").
      if (shared.difference(_accessoryWords).isEmpty) {
        final draftMain = draftTokens.difference(_accessoryWords);
        final candidateMain = candidateTokens.difference(_accessoryWords);
        if (draftMain.isNotEmpty && candidateMain.isNotEmpty) continue;
      }

      final sameCategory = draftCategory.isNotEmpty &&
          _normalize(candidate.category) == draftCategory;

      final nameScore = _nameSimilarity(
        draftName,
        _normalize(candidate.title),
        draftTokens,
        candidateTokens,
      );

      // Name is the main signal; same category is a bonus.
      final score = (0.7 * nameScore) + (sameCategory ? 0.3 : 0.0);

      matches.add(ItemMatch(
        item: candidate,
        score: score.clamp(0.0, 1.0).toDouble(),
        sameCategory: sameCategory,
        sharedKeywords: shared.toList()..sort(),
      ));
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.take(limit).toList();
  }

  /// 'lost' / 'found' (a Pending item is publicly a Found item).
  /// Returns null for anything that shouldn't be matched (e.g. Claimed).
  static String? _reportType(String status) {
    switch (status.trim().toLowerCase()) {
      case 'lost':
        return 'lost';
      case 'found':
      case 'pending':
        return 'found';
      default:
        return null;
    }
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Meaningful words of a name: lowercased, plurals removed, synonyms
  /// folded together ("mobile" -> "phone"). Stop words and plain numbers
  /// are dropped so "Room 13 key" doesn't match "iPhone 13".
  static Set<String> _keywords(String value) {
    final tokens = <String>{};

    for (final raw in _normalize(value).split(' ')) {
      if (raw.length < 2) continue;
      if (_stopWords.contains(raw)) continue;
      if (RegExp(r'^\d+$').hasMatch(raw)) continue;

      final stemmed = _stem(raw);
      tokens.add(_synonyms[stemmed] ?? stemmed);
    }

    return tokens;
  }

  static String _stem(String token) {
    if (token.length > 4 && token.endsWith('sses')) {
      return token.substring(0, token.length - 2);
    }
    if (token.length > 3 &&
        token.endsWith('s') &&
        !token.endsWith('ss') &&
        !token.endsWith('us') &&
        !token.endsWith('is')) {
      return token.substring(0, token.length - 1);
    }
    return token;
  }

  static double _nameSimilarity(
      String a,
      String b,
      Set<String> aTokens,
      Set<String> bTokens,
      ) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1.0;
    if (aTokens.isEmpty || bTokens.isEmpty) return 0;

    final intersection = aTokens.intersection(bTokens).length;
    if (intersection == 0) return 0;

    // Same keywords, possibly worded differently ("mobile phone" vs "phone").
    if (aTokens.length == bTokens.length &&
        aTokens.containsAll(bTokens)) {
      return 0.95;
    }

    // One name's keywords contain the other's ("wallet" vs "leather wallet").
    if (aTokens.containsAll(bTokens) || bTokens.containsAll(aTokens)) {
      return 0.85;
    }

    final union = aTokens.union(bTokens).length;
    final jaccard = intersection / union;

    // Sharing at least one keyword always counts for something.
    return jaccard < 0.4 ? 0.4 : jaccard;
  }
}

class ItemMatch {
  final ItemModel item;
  final double score;

  /// True when the candidate is in the same category as the new report.
  final bool sameCategory;

  /// Keywords the two item names have in common.
  final List<String> sharedKeywords;

  const ItemMatch({
    required this.item,
    required this.score,
    this.sameCategory = false,
    this.sharedKeywords = const [],
  });
}