import '../models/item_model.dart';

/// Small, dependency-free matcher used for "possible matches".
///
/// A match must be the opposite report type, have the same category, and
/// have a reasonably similar item name. This intentionally stays simple and
/// explainable for the current app.
class ItemMatchingService {
  static List<ItemMatch> findMatches({
    required ItemModel item,
    required Iterable<ItemModel> candidates,
    String? currentUserId,
  }) {
    final matches = <ItemMatch>[];

    for (final candidate in candidates) {
      if (candidate.id == item.id) continue;
      if (currentUserId != null &&
          currentUserId.isNotEmpty &&
          candidate.ownerId == currentUserId) {
        continue;
      }

      final sameCategory =
          _normalize(candidate.category) == _normalize(item.category);
      if (!sameCategory) continue;

      final itemStatus = _normalize(item.status);
      final candidateStatus = _normalize(candidate.status);
      final oppositeTypes =
          (itemStatus == 'lost' && candidateStatus == 'found') ||
          (itemStatus == 'found' && candidateStatus == 'lost');
      if (!oppositeTypes) continue;

      final score = _nameSimilarity(item.title, candidate.title);
      if (score < 0.35) continue;

      matches.add(ItemMatch(item: candidate, score: score));
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.take(10).toList();
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static double _nameSimilarity(String first, String second) {
    final a = _normalize(first);
    final b = _normalize(second);

    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1.0;
    if (a.contains(b) || b.contains(a)) return 0.85;

    final aTokens = a.split(' ').where((token) => token.length > 1).toSet();
    final bTokens = b.split(' ').where((token) => token.length > 1).toSet();

    if (aTokens.isEmpty || bTokens.isEmpty) return 0;

    final intersection = aTokens.intersection(bTokens).length;
    final union = aTokens.union(bTokens).length;

    return union == 0 ? 0 : intersection / union;
  }
}

class ItemMatch {
  final ItemModel item;
  final double score;

  const ItemMatch({
    required this.item,
    required this.score,
  });
}
