import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item_model.dart';
import '../providers/item_provider.dart';
import '../services/item_matching_service.dart';
import 'item_details_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final matches =
          await context.read<ItemProvider>().findPotentialMatches(widget.itemId);

      if (!mounted) return;
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _matches = [];
        _isLoading = false;
      });
    }
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    return _buildMatchCard(_matches[index]);
                  },
                ),
    );
  }

  Widget _buildMatchCard(ItemMatch match) {
    final item = match.item;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemDetailsScreen(item: item),
            ),
          );
        },
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
                    item.category,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: match.score.clamp(0.0, 1.0).toDouble(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(match.score * 100).round()}% name match',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailsScreen(item: item),
                          ),
                        );
                      },
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
    final isFound = item.status.toLowerCase() == 'found';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: (isFound ? Colors.green : Colors.red).withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isFound ? 'FOUND' : 'LOST',
        style: TextStyle(
          color: isFound ? Colors.green : Colors.red,
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
              'We checked the same category and similar item names. '
              'You can check again later as new reports are added.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
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
