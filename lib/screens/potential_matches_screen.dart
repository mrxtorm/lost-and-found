import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item_model.dart';
import '../providers/item_provider.dart';
import '../services/item_matching_service.dart';
import 'item_details_screen.dart';

/// Possible matches for one of the user's saved posts. Opened from
/// My Posts -> "Check Matches". Every check first refreshes posts from the
/// server (when online) so newly reported items are included.
class PotentialMatchesScreen extends StatefulWidget {
  final String itemId;

  const PotentialMatchesScreen({
    super.key,
    required this.itemId,
  });

  @override
  State<PotentialMatchesScreen> createState() => _PotentialMatchesScreenState();
}

class _PotentialMatchesScreenState extends State<PotentialMatchesScreen> {
  bool _isLoading = true;
  List<ItemMatch> _matches = [];
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }

    final provider = context.read<ItemProvider>();

    try {
      // Pull the latest posts first so "check again" really sees new
      // reports. Errors (e.g. offline) are swallowed inside refreshHome,
      // so this falls back to the local cache.
      await provider.refreshHome();

      final matches = await provider.findPotentialMatches(widget.itemId);

      if (!mounted) return;
      setState(() {
        _matches = matches;
        _lastChecked = DateTime.now();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _matches = [];
        _lastChecked = DateTime.now();
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

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
        actions: [
          IconButton(
            tooltip: 'Check again',
            onPressed: _isLoading ? null : _loadMatches,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadMatches,
        child: _matches.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [_buildEmptyState()],
        )
            : ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _matches.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildSummary();
            return _buildMatchCard(_matches[index - 1]);
          },
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_matches.length} possible '
                  '${_matches.length == 1 ? 'match' : 'matches'}',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          if (_lastChecked != null)
            Text(
              'Checked ${_formatTime(_lastChecked!)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
        ],
      ),
    );
  }

  void _openItem(ItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: item)),
    );
  }

  Widget _buildMatchCard(ItemMatch match) {
    final item = match.item;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: () => _openItem(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 190,
              child: _buildImage(item),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _typeBadge(item),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.category}  •  ${item.location}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.date.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.date,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openItem(item),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('View Item'),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildImage(ItemModel item) {
    if (item.imageUrl.isNotEmpty) {
      return Image.network(
        item.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    if (item.localImagePath != null && item.localImagePath!.isNotEmpty) {
      return Image.file(
        File(item.localImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image, size: 64, color: Colors.grey),
      ),
    );
  }

  Widget _typeBadge(ItemModel item) {
    final isLost = item.status.toLowerCase() == 'lost';
    final color = isLost ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isLost ? 'LOST' : 'FOUND',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.search_off,
              size: 76,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 18),
            const Text(
              'No Possible Matches Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We checked for reports with a similar item name. '
                  'New reports are added all the time, so check again later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            if (_lastChecked != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last checked ${_formatTime(_lastChecked!)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: _loadMatches,
              icon: const Icon(Icons.refresh),
              label: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }
}