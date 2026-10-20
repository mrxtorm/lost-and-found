import 'package:flutter/material.dart';

import '../models/feedback_model.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import 'app_feedback.dart';
import 'celebration_overlay.dart';

/// Celebrates a completed return, then (optionally) asks for feedback.
class ReturnCompletion {
  ReturnCompletion._();

  /// [returnId] is the claim id. Never throws; feedback is always optional.
  ///
  /// Takes a [NavigatorState] (not a BuildContext) so it keeps working after
  /// the calling screen has been popped.
  static Future<void> run(
    NavigatorState navigator, {
    required String returnId,
    bool celebrate = true,
  }) async {
    // The overlay's context sits below the Navigator, so Overlay/Navigator
    // lookups succeed (the Navigator's own context would not).
    if (celebrate) CelebrationOverlay.show(navigator.overlay);

    final service = FeedbackService();
    final completed = await service.fetchCompletedReturn(returnId);
    if (completed == null) return;
    if (await service.hasSubmitted(returnId)) return;

    // Let the confetti play before the sheet slides up.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final context = navigator.overlay?.context;
    if (context == null || !context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useRootNavigator: true,
      builder: (_) => _FeedbackSheet(service: service, completed: completed),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  final FeedbackService service;
  final CompletedReturn completed;
  const _FeedbackSheet({required this.service, required this.completed});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _controller = TextEditingController();
  int _rating = 0;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.submit(
        completedReturn: widget.completed,
        rating: _rating,
        recommendation: _controller.text,
      );
      if (!mounted) return;
      AppSnack.success(context, 'Thanks for your feedback!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How did it go?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Rate your experience returning "${widget.completed.itemTitle}". '
              'This is optional.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return IconButton(
                  iconSize: 38,
                  tooltip: '${i + 1} star${i == 0 ? '' : 's'}',
                  onPressed:
                      _saving ? null : () => setState(() => _rating = i + 1),
                  icon: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? AppColors.warn : AppColors.muted,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              enabled: !_saving,
              maxLines: 4,
              maxLength: FeedbackService.maxRecommendationLength,
              decoration: const InputDecoration(
                labelText: 'Recommendations (optional)',
                hintText: 'What could we improve?',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.lost)),
              ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: (_saving || _rating == 0) ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
