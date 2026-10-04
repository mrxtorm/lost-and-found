import 'dart:io';

import 'package:flutter/material.dart';

import '../models/item_model.dart';
import '../services/item_matching_service.dart';
import 'item_details_screen.dart';

/// Shown BEFORE a report is submitted. Pops with:
///   true  -> the user wants to continue posting their report
///   false / null -> the user went back to edit (or cancelled)
class DraftMatchesScreen extends StatelessWidget {
  final List<ItemMatch> matches;
  final String reportType; // "Lost" or "Found"

  const DraftMatchesScreen({
    super.key,
    required this.matches,
    required this.reportType,
  });

  bool get _isLost => reportType.toLowerCase() == 'lost';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Possible Matches',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLost
                      ? 'Your item may already have been found'
                      : 'The owner may already have reported it',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We found ${matches.length} '
                      '${matches.length == 1 ? 'report' : 'reports'} with a '
                      'similar item name. Tap one to take a closer look '
                      'before you post.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) =>
                  _buildMatchCard(context, matches[index]),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.send),
                      label: const Text(
                        'None of these - Continue Posting',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Go Back and Edit My Report'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, ItemMatch match) {
    final item = match.item;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: item)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _thumbnail(item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _typeBadge(item),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.category}  •  ${item.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    if (item.date.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.date,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (match.sameCategory)
                          _reasonChip('Same category', Colors.blue),
                        for (final keyword in match.sharedKeywords.take(3))
                          _reasonChip('Keyword: $keyword', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(ItemModel item) {
    Widget placeholder() => Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.image, color: Colors.grey),
    );

    Widget child;
    if (item.imageUrl.isNotEmpty) {
      child = Image.network(
        item.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder(),
      );
    } else if (item.localImagePath != null &&
        item.localImagePath!.isNotEmpty) {
      child = Image.file(
        File(item.localImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder(),
      );
    } else {
      child = placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(width: 84, height: 84, child: child),
    );
  }

  Widget _typeBadge(ItemModel item) {
    final isLost = item.status.toLowerCase() == 'lost';
    final color = isLost ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isLost ? 'LOST' : 'FOUND',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _reasonChip(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}