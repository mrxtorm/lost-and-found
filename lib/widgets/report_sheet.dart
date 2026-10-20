import 'package:flutter/material.dart';

import '../models/item_model.dart';
import '../models/message_model.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import 'app_feedback.dart';

/// Bottom sheet for reporting a post or a message: pick a reason, add
/// optional details, submit. Shows a notice instead if the user already
/// reported this content.
class ReportSheet {
  ReportSheet._();

  static Future<void> showForItem(BuildContext context, ItemModel item) {
    final service = ReportService();
    return _show(
      context,
      title: 'Report post',
      subtitle:
          'Tell us what is wrong with "${item.title}". '
          'Your report is anonymous to the poster.',
      reasons: ReportReason.forItems,
      alreadyReported: service.hasReportedItem(item.id),
      onSubmit: (reason, details) =>
          service.reportItem(item: item, reason: reason, details: details),
    );
  }

  static Future<void> showForMessage(
    BuildContext context,
    MessageModel message,
  ) {
    final service = ReportService();
    return _show(
      context,
      title: 'Report message',
      subtitle:
          'Only this message is shared with admins, not the rest of '
          'your conversation.',
      reasons: ReportReason.forMessages,
      alreadyReported: service.hasReportedMessage(message.id),
      onSubmit: (reason, details) => service.reportMessage(
        message: message,
        reason: reason,
        details: details,
      ),
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<String> reasons,
    required Future<bool> alreadyReported,
    required Future<void> Function(String reason, String details) onSubmit,
  }) async {
    if (await alreadyReported) {
      if (context.mounted) {
        AppSnack.info(
          context,
          'You already reported this. An admin will review it.',
        );
      }
      return;
    }
    if (!context.mounted) return;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReportForm(
        title: title,
        subtitle: subtitle,
        reasons: reasons,
        onSubmit: onSubmit,
      ),
    );

    if (submitted == true && context.mounted) {
      AppSnack.success(context, 'Thanks. Your report was sent to the admins.');
    }
  }
}

class _ReportForm extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> reasons;
  final Future<void> Function(String reason, String details) onSubmit;

  const _ReportForm({
    required this.title,
    required this.subtitle,
    required this.reasons,
    required this.onSubmit,
  });

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _controller = TextEditingController();
  String? _reason;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) return;
    // A report can only be sent once per post/message, so make sure.
    final ok = await confirmAction(
      context,
      title: 'Send this report?',
      message:
          'Admins will review it for "${ReportReason.label(reason)}". '
          'You can only report this once.',
      confirmLabel: 'Send report',
      icon: Icons.flag_outlined,
    );
    if (!ok || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(reason, _controller.text);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = friendlyError(e);
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
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(widget.subtitle, style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            RadioGroup<String>(
              groupValue: _reason,
              onChanged: (value) {
                if (!_saving) setState(() => _reason = value);
              },
              child: Column(
                children: [
                  for (final reason in widget.reasons)
                    RadioListTile<String>(
                      value: reason,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(ReportReason.label(reason)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              enabled: !_saving,
              maxLines: 3,
              maxLength: ReportService.maxDetailsLength,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                hintText: 'Anything that helps the admins review this',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.lost),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lost,
                    ),
                    onPressed: (_saving || _reason == null) ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit report'),
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
