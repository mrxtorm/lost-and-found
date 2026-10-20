import 'dart:async';

import 'package:flutter/material.dart';

import '../models/feedback_model.dart';
import '../models/report_model.dart';
import '../models/suspended_user.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/item_ui.dart';
import 'item_details_screen.dart';

/// Admin-only: review reported posts/messages, see past decisions and read
/// user feedback.
///
/// The screen re-checks admin status on open, but the real protection is
/// firestore.rules - a non-admin who somehow reaches this screen still
/// cannot read reports, the moderation log or feedback.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _service = AdminService();
  late final Future<bool> _isAdmin = _service.isCurrentUserAdmin();

  // One listener per collection, shared by the overview header and the
  // tabs. Created lazily, i.e. only after admin status is confirmed.
  late final Stream<List<ReportModel>> _pending = _service
      .streamPendingReports();
  late final Stream<List<ModerationLogEntry>> _history = _service
      .streamHistory();
  late final Stream<List<FeedbackEntry>> _feedback = _service.streamFeedback();
  late final Stream<List<SuspendedUser>> _suspended = _service
      .streamSuspendedUsers();

  // Time-based things change without any new data arriving: suspensions
  // expire, "2h ago" / "5 days left" labels age. Rebuild periodically so
  // the screen never needs to be reopened to look current.
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Dashboard')),
            body: const EmptyState(
              icon: Icons.lock_outline,
              title: 'Admins only',
              message: 'You do not have permission to view this page.',
              color: AppColors.lost,
            ),
          );
        }

        return StreamBuilder<List<ReportModel>>(
          stream: _pending,
          builder: (context, pending) =>
              StreamBuilder<List<ModerationLogEntry>>(
                stream: _history,
                builder: (context, history) =>
                    StreamBuilder<List<FeedbackEntry>>(
                      stream: _feedback,
                      builder: (context, feedback) =>
                          StreamBuilder<List<SuspendedUser>>(
                            stream: _suspended,
                            builder: (context, suspended) => _DashboardBody(
                              service: _service,
                              pending: pending,
                              history: history,
                              feedback: feedback,
                              suspended: suspended,
                            ),
                          ),
                    ),
              ),
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final AdminService service;
  final AsyncSnapshot<List<ReportModel>> pending;
  final AsyncSnapshot<List<ModerationLogEntry>> history;
  final AsyncSnapshot<List<FeedbackEntry>> feedback;
  final AsyncSnapshot<List<SuspendedUser>> suspended;

  const _DashboardBody({
    required this.service,
    required this.pending,
    required this.history,
    required this.feedback,
    required this.suspended,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _groupByTarget(pending.data ?? const []);

    final suspendedCount = suspended.data?.where((u) => u.isActive).length ?? 0;

    return DefaultTabController(
      length: 4,
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Moderation and user feedback',
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              _OverviewHeader(
                pendingCount: pending.hasData ? groups.length : null,
                suspendedCount: suspended.hasData ? suspendedCount : null,
                averageRating: feedback.hasData && feedback.data!.isNotEmpty
                    ? _average(feedback.data!)
                    : null,
                hasFeedback: feedback.hasData,
                onTapTile: (index) =>
                    DefaultTabController.of(context).animateTo(index),
              ),
              Material(
                color: AppColors.surface,
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(
                      child: _TabLabel(
                        text: 'Reports',
                        count: pending.hasData ? groups.length : 0,
                      ),
                    ),
                    Tab(
                      child: _TabLabel(
                        text: 'Suspended',
                        count: suspendedCount,
                      ),
                    ),
                    const Tab(child: _TabLabel(text: 'History')),
                    const Tab(child: _TabLabel(text: 'Feedback')),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.line),
              Expanded(
                child: TabBarView(
                  children: [
                    _ReportsTab(service: service, snapshot: pending),
                    _SuspendedTab(
                      service: service,
                      snapshot: suspended,
                      history: history.data ?? const [],
                    ),
                    _HistoryTab(service: service, snapshot: history),
                    _FeedbackTab(service: service, snapshot: feedback),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SHARED HELPERS
// ---------------------------------------------------------------------------

/// Several users may report the same post/message; review them together.
List<List<ReportModel>> _groupByTarget(List<ReportModel> reports) {
  final groups = <String, List<ReportModel>>{};
  for (final report in reports) {
    groups
        .putIfAbsent('${report.targetType}_${report.targetId}', () => [])
        .add(report);
  }
  return groups.values.toList();
}

double _average(List<FeedbackEntry> entries) =>
    entries.fold<int>(0, (sum, e) => sum + e.rating) / entries.length;

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _clock(DateTime d) {
  final hour = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
  return '$hour:${d.minute.toString().padLeft(2, '0')} '
      '${d.hour >= 12 ? 'PM' : 'AM'}';
}

String _fullDate(DateTime? d) {
  if (d == null) return 'Unknown date';
  return '${_months[d.month - 1]} ${d.day}, ${d.year} · ${_clock(d)}';
}

/// "Today", "Yesterday", or e.g. "Mon, Oct 13".
String _dayLabel(DateTime? d) {
  if (d == null) return 'Earlier';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  final year = d.year == now.year ? '' : ', ${d.year}';
  return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}$year';
}

/// Shows loading / error / empty states around a list from Firestore.
class _AsyncSection<T> extends StatelessWidget {
  final AsyncSnapshot<List<T>> snapshot;
  final String errorMessage;
  final Widget empty;
  final Widget Function(List<T> data) builder;

  const _AsyncSection({
    required this.snapshot,
    required this.errorMessage,
    required this.empty,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) return ErrorState(message: errorMessage);
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    final data = snapshot.data!;
    return data.isEmpty ? empty : builder(data);
  }
}

class _TabLabel extends StatelessWidget {
  final String text;
  final int count;
  const _TabLabel({required this.text, this.count = 0});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Badge(
            backgroundColor: AppColors.error,
            textColor: Colors.white,
            label: Text(count > 99 ? '99+' : '$count'),
          ),
        ],
      ],
    );
  }
}

/// Small rounded label with an optional icon.
class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Tag({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded square icon used as a leading visual on cards.
class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const _IconTile({required this.icon, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Horizontal row of single-select filter chips.
class _FilterBar extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final Widget? trailing;
  final EdgeInsets padding;

  const _FilterBar({
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 8, 4),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(labels[i]),
                        selected: selected == i,
                        showCheckmark: false,
                        onSelected: (_) => onSelected(i),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: selected == i
                              ? AppColors.primary
                              : AppColors.line,
                        ),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected == i ? Colors.white : AppColors.ink,
                        ),
                        shape: const StadiumBorder(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  final String message;
  const _NoMatches(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// OVERVIEW
// ---------------------------------------------------------------------------

class _OverviewHeader extends StatelessWidget {
  final int? pendingCount;
  final int? suspendedCount;
  final double? averageRating;
  final bool hasFeedback;
  final ValueChanged<int> onTapTile;

  const _OverviewHeader({
    required this.pendingCount,
    required this.suspendedCount,
    required this.averageRating,
    required this.hasFeedback,
    required this.onTapTile,
  });

  @override
  Widget build(BuildContext context) {
    final pending = pendingCount;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: pending == 0
                  ? Icons.verified_user_outlined
                  : Icons.flag_rounded,
              color: pending == 0 ? AppColors.found : AppColors.lost,
              value: pending?.toString(),
              label: 'To review',
              onTap: () => onTapTile(0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.block_rounded,
              color: suspendedCount == 0 ? AppColors.muted : AppColors.warn,
              value: suspendedCount?.toString(),
              label: 'Suspended',
              onTap: () => onTapTile(1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.star_rounded,
              color: AppColors.warn,
              value: averageRating != null
                  ? averageRating!.toStringAsFixed(1)
                  : (hasFeedback ? '–' : null),
              label: 'Avg rating',
              onTap: () => onTapTile(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? value; // null while loading
  final String label;
  final VoidCallback onTap;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              SizedBox(
                height: 28,
                child: value == null
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Text(
                        value!,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// REPORTS
// ---------------------------------------------------------------------------

/// Many reports, or a serious reason, puts a group at the top of the queue.
bool _isHighPriority(List<ReportModel> reports) =>
    reports.length >= 3 ||
    reports.any((r) => r.reason == 'scam' || r.reason == 'harassment');

DateTime _latest(List<ReportModel> reports) => reports
    .map((r) => r.createdAt ?? DateTime.now())
    .reduce((a, b) => a.isAfter(b) ? a : b);

class _ReportsTab extends StatefulWidget {
  final AdminService service;
  final AsyncSnapshot<List<ReportModel>> snapshot;

  const _ReportsTab({required this.service, required this.snapshot});

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  int _filter = 0; // 0 all, 1 posts, 2 messages
  bool _mostReportedFirst = false;

  @override
  Widget build(BuildContext context) {
    return _AsyncSection<ReportModel>(
      snapshot: widget.snapshot,
      errorMessage: 'Unable to load reports.',
      empty: const EmptyState(
        icon: Icons.verified_user_outlined,
        title: 'All clear',
        message: 'There are no reports waiting for review.',
        color: AppColors.found,
      ),
      builder: (reports) {
        final all = _groupByTarget(reports);
        final posts = all.where((g) => g.first.isItem).length;
        final groups =
            all.where((g) {
              if (_filter == 1) return g.first.isItem;
              if (_filter == 2) return !g.first.isItem;
              return true;
            }).toList()..sort((a, b) {
              // High priority first, then by the chosen order.
              final p =
                  (_isHighPriority(b) ? 1 : 0) - (_isHighPriority(a) ? 1 : 0);
              if (p != 0) return p;
              if (_mostReportedFirst && a.length != b.length) {
                return b.length - a.length;
              }
              return _latest(b).compareTo(_latest(a));
            });

        return Column(
          children: [
            _FilterBar(
              labels: [
                'All (${all.length})',
                'Posts ($posts)',
                'Messages (${all.length - posts})',
              ],
              selected: _filter,
              onSelected: (i) => setState(() => _filter = i),
              trailing: PopupMenuButton<bool>(
                tooltip: 'Sort',
                icon: Icon(Icons.sort_rounded, color: AppColors.ink),
                initialValue: _mostReportedFirst,
                onSelected: (v) => setState(() => _mostReportedFirst = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: false, child: Text('Newest first')),
                  PopupMenuItem(value: true, child: Text('Most reported')),
                ],
              ),
            ),
            Expanded(
              child: groups.isEmpty
                  ? const _NoMatches('No reports match this filter.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: groups.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ReportGroupCard(
                        reports: groups[i],
                        onTap: () => _ReviewSheet.show(
                          context,
                          widget.service,
                          groups[i],
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ReportGroupCard extends StatelessWidget {
  final List<ReportModel> reports;
  final VoidCallback onTap;

  const _ReportGroupCard({required this.reports, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final first = reports.first;
    final reasons = reports.map((r) => r.reason).toSet();
    final urgent = _isHighPriority(reports);
    final accent = urgent ? AppColors.lost : AppColors.warn;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TargetIcon(isItem: first.isItem),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  first.isItem
                                      ? 'Reported post'
                                      : 'Reported message',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  first.contentPreview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          UserAvatar(name: first.reportedUserName, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${first.reportedUserName} · '
                              '${timeAgo(_latest(reports))}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (urgent)
                            const _Tag(
                              label: 'High priority',
                              color: AppColors.lost,
                              icon: Icons.priority_high_rounded,
                            ),
                          _Tag(
                            label:
                                '${reports.length} report${reports.length == 1 ? '' : 's'}',
                            color: accent,
                            icon: Icons.flag_rounded,
                          ),
                          for (final reason in reasons)
                            _Tag(
                              label: ReportReason.label(reason),
                              color: AppColors.muted,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetIcon extends StatelessWidget {
  final bool isItem;
  final double size;
  const _TargetIcon({required this.isItem, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return _IconTile(
      icon: isItem ? Icons.inventory_2_outlined : Icons.chat_bubble_outline,
      color: isItem ? AppColors.primary : Colors.purple,
      size: size,
    );
  }
}

/// Full report details plus the dismiss / remove / suspend decision.
class _ReviewSheet extends StatefulWidget {
  final AdminService service;
  final List<ReportModel> reports;

  const _ReviewSheet({required this.service, required this.reports});

  static Future<void> show(
    BuildContext context,
    AdminService service,
    List<ReportModel> reports,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReviewSheet(service: service, reports: reports),
    );
  }

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _note = TextEditingController();
  bool _busy = false;

  // Follows the pending queue while open: reports that arrive are added,
  // and if another admin handles this content the sheet says so instead of
  // offering actions that would fail.
  late final Stream<List<ReportModel>> _live = widget.service
      .streamPendingReports();
  late List<ReportModel> _reports = widget.reports;

  ReportModel get _target => _reports.first;

  bool _sameTarget(ReportModel r) =>
      r.targetType == widget.reports.first.targetType &&
      r.targetId == widget.reports.first.targetId;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _openPost() async {
    setState(() => _busy = true);
    try {
      final item = await widget.service.fetchItem(_target.targetId);
      if (!mounted) return;
      if (item == null) {
        AppSnack.info(context, 'This post no longer exists.');
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: item)),
      );
    } catch (e) {
      if (mounted) AppSnack.error(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decide(String action) async {
    final what = _target.isItem ? 'post' : 'message';
    final name = _target.reportedUserName;
    final count = _reports.length;
    final reportsText = count == 1 ? 'The report' : 'All $count reports';

    final (title, body, button) = switch (action) {
      ModerationAction.dismiss => (
        'Dismiss ${count == 1 ? 'this report' : 'these reports'}?',
        '$reportsText will be closed and the $what stays up. $name is not '
            'notified.',
        'Dismiss',
      ),
      ModerationAction.remove => (
        'Remove this $what?',
        'The $what will be removed and $name will be notified. '
            '$reportsText will be closed.',
        'Remove',
      ),
      _ => (
        'Remove and suspend $name?',
        'The $what will be removed and $name will be blocked from creating '
            'or editing posts for ${AdminService.suspensionDays} days. They '
            'will be notified.',
        'Remove & suspend',
      ),
    };
    final destructive = action != ModerationAction.dismiss;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text('$body\n\nYou can undo this later from History.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.lost)
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(button),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await widget.service.resolve(
        reports: _reports,
        action: action,
        note: _note.text,
      );
      if (!mounted) return;
      AppSnack.success(context, ModerationAction.label(action));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppSnack.error(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportModel>>(
      stream: _live,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data != null) {
          final group = data.where(_sameTarget).toList();
          // Handled elsewhere (not by us mid-request): nothing left to do.
          if (group.isEmpty && !_busy) return const _AlreadyHandledView();
          if (group.isNotEmpty) _reports = group;
        }
        return _buildSheet(context);
      },
    );
  }

  Widget _buildSheet(BuildContext context) {
    final count = _reports.length;
    final what = _target.isItem ? 'post' : 'message';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                _TargetIcon(isItem: _target.isItem, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reported $what',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          UserAvatar(name: _target.reportedUserName, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_target.isItem ? 'Posted' : 'Sent'} by '
                              '${_target.reportedUserName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // CONTENT
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border(
                  left: BorderSide(
                    color: _target.isItem ? AppColors.primary : Colors.purple,
                    width: 4,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Text(
                _target.contentPreview,
                style: const TextStyle(fontSize: 15.5, height: 1.45),
              ),
            ),
            if (_target.isItem) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _openPost,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('View full post'),
              ),
            ],
            const SizedBox(height: 20),

            // REPORTS
            Row(
              children: [
                Text(
                  '$count report${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isHighPriority(_reports))
                  const _Tag(
                    label: 'High priority',
                    color: AppColors.lost,
                    icon: Icons.priority_high_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            for (final report in _reports)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Tag(
                          label: ReportReason.label(report.reason),
                          color: AppColors.lost,
                          icon: Icons.flag_rounded,
                        ),
                        const Spacer(),
                        Text(
                          timeAgo(report.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.details.isEmpty
                          ? 'No details given.'
                          : report.details,
                      style: TextStyle(
                        color: report.details.isEmpty
                            ? AppColors.muted
                            : AppColors.ink,
                        fontStyle: report.details.isEmpty
                            ? FontStyle.italic
                            : null,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // DECISION
            const Text(
              'Decision',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Dismiss keeps the $what. Remove deletes it and notifies '
              '${_target.reportedUserName}.',
              style: TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              enabled: !_busy,
              maxLength: 300,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Admin note (optional)',
                helperText: 'Saved in the moderation history',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 4),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _decide(ModerationAction.dismiss),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lost,
                    ),
                    onPressed: _busy
                        ? null
                        : () => _decide(ModerationAction.remove),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style:
                    OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB4232A),
                    ).copyWith(
                      // Red outline, muted while an action is running.
                      side: WidgetStateProperty.resolveWith(
                        (states) => BorderSide(
                          color: states.contains(WidgetState.disabled)
                              ? AppColors.line
                              : const Color(0xFFB4232A),
                          width: 1.5,
                        ),
                      ),
                    ),
                onPressed: _busy
                    ? null
                    : () => _decide(ModerationAction.removeAndSuspend),
                icon: const Icon(Icons.block_rounded),
                label: Text(
                  'Remove & suspend posting for '
                  '${AdminService.suspensionDays} days',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlreadyHandledView extends StatelessWidget {
  const _AlreadyHandledView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _IconTile(
            icon: Icons.task_alt_rounded,
            color: AppColors.found,
            size: 56,
          ),
          const SizedBox(height: 14),
          const Text(
            'Already handled',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Another admin has already made a decision on this. See '
            'History for details.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUSPENDED
// ---------------------------------------------------------------------------

const _noneSuspended = EmptyState(
  icon: Icons.how_to_reg_outlined,
  title: 'No one is suspended',
  message:
      'Users suspended from posting will appear here until their '
      'suspension ends.',
  color: AppColors.found,
);

class _SuspendedTab extends StatelessWidget {
  final AdminService service;
  final AsyncSnapshot<List<SuspendedUser>> snapshot;

  /// Used to name users whose suspension predates saved display names.
  final List<ModerationLogEntry> history;

  const _SuspendedTab({
    required this.service,
    required this.snapshot,
    required this.history,
  });

  String _nameFor(SuspendedUser user) {
    if (user.displayName.isNotEmpty) return user.displayName;
    for (final e in history) {
      if (e.reportedUserId == user.uid && e.reportedUserName.isNotEmpty) {
        return e.reportedUserName;
      }
    }
    return 'Unknown user';
  }

  Future<void> _confirmLift(BuildContext context, SuspendedUser user) async {
    final name = _nameFor(user);
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.lock_open_rounded),
        title: Text('Lift $name\'s suspension?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$name will be able to report and edit items again right '
              'away and will be notified. Their offense count '
              '(${user.offenseCount}) is kept.',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.found),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Lift suspension'),
          ),
        ],
      ),
    );
    final note = noteController.text;
    noteController.dispose();
    if (confirmed != true || !context.mounted) return;

    try {
      await service.liftSuspension(user, displayName: name, note: note);
      if (context.mounted) {
        AppSnack.success(context, '$name can post again.');
      }
    } catch (e) {
      if (context.mounted) AppSnack.error(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AsyncSection<SuspendedUser>(
      snapshot: snapshot,
      errorMessage: 'Unable to load suspended users.',
      empty: _noneSuspended,
      builder: (all) {
        // Filtered here, not in the stream, so a suspension that ends while
        // this is open disappears on the next rebuild.
        final users = all.where((u) => u.isActive).toList();
        if (users.isEmpty) return _noneSuspended;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _SuspendedUserCard(
            // Keyed by user so a card never shows another user's state
            // when the list changes underneath it.
            key: ValueKey(users[i].uid),
            user: users[i],
            name: _nameFor(users[i]),
            onLift: () => _confirmLift(context, users[i]),
          ),
        );
      },
    );
  }
}

class _SuspendedUserCard extends StatelessWidget {
  final SuspendedUser user;
  final String name;
  final VoidCallback onLift;

  const _SuspendedUserCard({
    super.key,
    required this.user,
    required this.name,
    required this.onLift,
  });

  String _remaining() {
    final left = user.bannedUntil.difference(DateTime.now());
    if (left.inDays >= 1) {
      return '${left.inDays} day${left.inDays == 1 ? '' : 's'} left';
    }
    if (left.inHours >= 1) {
      return '${left.inHours} hour${left.inHours == 1 ? '' : 's'} left';
    }
    return 'Ends soon';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(name: name, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Tag(
                          label: _remaining(),
                          color: AppColors.warn,
                          icon: Icons.timer_outlined,
                        ),
                        _Tag(
                          label:
                              '${user.offenseCount} '
                              'offense${user.offenseCount == 1 ? '' : 's'}',
                          color: user.offenseCount >= 3
                              ? AppColors.lost
                              : AppColors.muted,
                          icon: Icons.flag_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MetaLine(
            icon: Icons.event_busy_outlined,
            text: 'Suspended until ${_fullDate(user.bannedUntil)}',
          ),
          if (user.suspendedAt != null)
            _MetaLine(
              icon: Icons.history_rounded,
              text: 'Suspended ${_fullDate(user.suspendedAt)}',
            ),
          _MetaLine(icon: Icons.badge_outlined, text: 'User ID: ${user.uid}'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.found,
                side: const BorderSide(color: AppColors.found),
              ),
              onPressed: onLift,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Lift suspension'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HISTORY
// ---------------------------------------------------------------------------

class _ActionStyle {
  final IconData icon;
  final Color color;
  const _ActionStyle(this.icon, this.color);

  static _ActionStyle of(String action) => switch (action) {
    ModerationAction.dismiss => _ActionStyle(
      Icons.close_rounded,
      AppColors.muted,
    ),
    ModerationAction.remove => const _ActionStyle(
      Icons.delete_outline_rounded,
      AppColors.lost,
    ),
    ModerationAction.unban => const _ActionStyle(
      Icons.lock_open_rounded,
      AppColors.found,
    ),
    ModerationAction.undo => const _ActionStyle(
      Icons.undo_rounded,
      AppColors.primary,
    ),
    _ => const _ActionStyle(Icons.block_rounded, Color(0xFFB4232A)),
  };
}

class _HistoryTab extends StatefulWidget {
  final AdminService service;
  final AsyncSnapshot<List<ModerationLogEntry>> snapshot;
  const _HistoryTab({required this.service, required this.snapshot});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  static const _filters = [
    null,
    ModerationAction.dismiss,
    ModerationAction.remove,
    ModerationAction.removeAndSuspend,
    ModerationAction.undo,
  ];
  int _filter = 0;

  Future<void> _confirmUndo(ModerationLogEntry entry) async {
    final what = entry.targetType == ReportTarget.item ? 'post' : 'message';
    final effects = <String>[
      if (ModerationAction.isRemoval(entry.action))
        'The $what will be restored and ${entry.reportedUserName} notified.',
      if (entry.action == ModerationAction.removeAndSuspend)
        'The posting suspension will be lifted.',
      'The ${entry.reportCount == 1 ? 'report goes' : '${entry.reportCount} reports go'} '
          'back to the review queue.',
    ];
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.undo_rounded),
        title: const Text('Undo this decision?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in effects)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(line)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Reason for undo (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Undo'),
          ),
        ],
      ),
    );
    final note = noteController.text;
    noteController.dispose();
    if (confirmed != true || !mounted) return;

    try {
      await widget.service.undo(entry, note: note);
      if (mounted) AppSnack.success(context, 'Decision undone.');
    } catch (e) {
      if (mounted) AppSnack.error(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AsyncSection<ModerationLogEntry>(
      snapshot: widget.snapshot,
      errorMessage: 'Unable to load history.',
      empty: const EmptyState(
        icon: Icons.history_rounded,
        title: 'No decisions yet',
        message: 'Actions taken on reports will appear here.',
      ),
      builder: (entries) {
        final action = _filters[_filter];
        final shown = action == null
            ? entries
            : entries.where((e) => e.action == action).toList();
        final undoneIds = {
          for (final e in entries)
            if (e.isUndo) e.undoOf,
        };
        final byId = {for (final e in entries) e.id: e};

        // Flatten into day headers + entries.
        final rows = <Widget>[];
        String? lastDay;
        for (final e in shown) {
          final day = _dayLabel(e.createdAt);
          if (day != lastDay) {
            rows.add(_SectionLabel(day));
            lastDay = day;
          }
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HistoryCard(
                entry: e,
                undone: undoneIds.contains(e.id),
                revertedAction: byId[e.undoOf]?.action,
                onUndo:
                    e.isUndo ||
                        e.action == ModerationAction.unban ||
                        undoneIds.contains(e.id)
                    ? null
                    : () => _confirmUndo(e),
              ),
            ),
          );
        }

        return Column(
          children: [
            _FilterBar(
              labels: const [
                'All',
                'Dismissed',
                'Removed',
                'Suspended',
                'Undone',
              ],
              selected: _filter,
              onSelected: (i) => setState(() => _filter = i),
            ),
            Expanded(
              child: rows.isEmpty
                  ? const _NoMatches('No decisions match this filter.')
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: rows,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ModerationLogEntry entry;

  /// A later undo entry reverted this decision.
  final bool undone;

  /// For undo entries: the action that was reverted (if still loaded).
  final String? revertedAction;
  final VoidCallback? onUndo;

  const _HistoryCard({
    required this.entry,
    this.undone = false,
    this.revertedAction,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final style = _ActionStyle.of(entry.action);
    final isItem = entry.targetType == ReportTarget.item;
    final reasons = entry.reasons.map(ReportReason.label).join(', ');

    return Opacity(
      // Reverted decisions are kept for the record but visually muted.
      opacity: undone ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, size: 19, color: style.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${ModerationAction.label(entry.action)} · '
                          '${isItem ? 'Post' : (entry.targetType == 'user' ? 'User' : 'Message')}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: style.color == AppColors.muted
                                ? AppColors.ink
                                : style.color,
                          ),
                        ),
                      ),
                      if (entry.createdAt != null)
                        Text(
                          _clock(entry.createdAt!),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                  if (undone) ...[
                    const SizedBox(height: 6),
                    const _Tag(
                      label: 'Undone',
                      color: AppColors.primary,
                      icon: Icons.undo_rounded,
                    ),
                  ],
                  if (entry.isUndo && revertedAction != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Reverted: ${ModerationAction.label(revertedAction!)}',
                      style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    entry.contentPreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MetaLine(
                    icon: Icons.person_outline_rounded,
                    text: entry.reportedUserName,
                  ),
                  _MetaLine(
                    icon: Icons.flag_outlined,
                    text:
                        '${entry.reportCount} '
                        'report${entry.reportCount == 1 ? '' : 's'}'
                        '${reasons.isEmpty ? '' : ' · $reasons'}',
                  ),
                  _MetaLine(
                    icon: Icons.admin_panel_settings_outlined,
                    text: entry.adminEmail.isEmpty
                        ? entry.adminId
                        : entry.adminEmail,
                  ),
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Text(
                        entry.note,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                  if (onUndo != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onUndo,
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: const Text('Undo'),
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
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FEEDBACK
// ---------------------------------------------------------------------------

Color _ratingColor(int rating) {
  if (rating >= 4) return AppColors.found;
  if (rating == 3) return AppColors.warn;
  return AppColors.lost;
}

class _FeedbackTab extends StatefulWidget {
  final AdminService service;
  final AsyncSnapshot<List<FeedbackEntry>> snapshot;

  const _FeedbackTab({required this.service, required this.snapshot});

  @override
  State<_FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<_FeedbackTab> {
  int _filter = 0; // 0 all, 1 positive (4-5), 2 neutral (3), 3 negative (1-2)

  bool _matches(FeedbackEntry e) => switch (_filter) {
    1 => e.rating >= 4,
    2 => e.rating == 3,
    3 => e.rating <= 2,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    return _AsyncSection<FeedbackEntry>(
      snapshot: widget.snapshot,
      errorMessage: 'Unable to load feedback.',
      empty: const EmptyState(
        icon: Icons.reviews_outlined,
        title: 'No feedback yet',
        message: 'Ratings left after completed returns will appear here.',
      ),
      builder: (entries) {
        final shown = entries.where(_matches).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _FeedbackSummary(entries: entries),
            _FilterBar(
              labels: const ['All', 'Positive', 'Neutral', 'Negative'],
              selected: _filter,
              onSelected: (i) => setState(() => _filter = i),
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
            ),
            if (shown.isEmpty)
              const _NoMatches('No feedback matches this filter.')
            else
              for (final entry in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FeedbackCard(
                    entry: entry,
                    onTap: () => _FeedbackDetailSheet.show(
                      context,
                      widget.service,
                      entry,
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _FeedbackSummary extends StatelessWidget {
  final List<FeedbackEntry> entries;
  const _FeedbackSummary({required this.entries});

  @override
  Widget build(BuildContext context) {
    final average = _average(entries);
    final counts = List<int>.filled(6, 0);
    for (final e in entries) {
      if (e.rating >= 1 && e.rating <= 5) counts[e.rating]++;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                average.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: AppColors.ink,
                ),
              ),
              _Stars(rating: average.round(), size: 16),
              const SizedBox(height: 4),
              Text(
                '${entries.length} rating${entries.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                for (var star = 5; star >= 1; star--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          child: Text(
                            '$star',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: counts[star] / entries.length,
                              minHeight: 7,
                              color: _ratingColor(star),
                              backgroundColor: AppColors.track,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${counts[star]}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final FeedbackEntry entry;
  final VoidCallback onTap;
  const _FeedbackCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(entry.rating);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${entry.rating}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1,
                      ),
                    ),
                    Icon(Icons.star_rounded, size: 13, color: color),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.itemTitle.isEmpty
                                ? 'Returned item'
                                : entry.itemTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Text(
                          timeAgo(entry.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _RolePill(role: entry.role),
                    const SizedBox(height: 6),
                    // Full text is in the detail sheet.
                    _Comment(text: entry.recommendation, maxLines: 2),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String role;
  const _RolePill({required this.role});

  @override
  Widget build(BuildContext context) {
    final isFinder = role == 'finder';
    return _Tag(
      label: isFinder ? 'From finder' : 'From claimant',
      color: isFinder ? AppColors.found : AppColors.primary,
      icon: isFinder ? Icons.volunteer_activism_outlined : Icons.person_outline,
    );
  }
}

class _Comment extends StatelessWidget {
  final String text;
  final int? maxLines;
  const _Comment({required this.text, this.maxLines});

  @override
  Widget build(BuildContext context) {
    final empty = text.isEmpty;
    return Text(
      empty ? 'No written feedback.' : text,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: TextStyle(
        color: empty ? AppColors.muted : AppColors.ink,
        fontStyle: empty ? FontStyle.italic : null,
        height: 1.4,
      ),
    );
  }
}

/// Full feedback plus the other participant's feedback for the same
/// return, so the admin sees both sides of the transaction.
class _FeedbackDetailSheet extends StatefulWidget {
  final AdminService service;
  final FeedbackEntry entry;

  const _FeedbackDetailSheet({required this.service, required this.entry});

  static Future<void> show(
    BuildContext context,
    AdminService service,
    FeedbackEntry entry,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FeedbackDetailSheet(service: service, entry: entry),
    );
  }

  @override
  State<_FeedbackDetailSheet> createState() => _FeedbackDetailSheetState();
}

class _FeedbackDetailSheetState extends State<_FeedbackDetailSheet> {
  late final Future<FeedbackEntry?> _counterpart = widget.service
      .fetchCounterpartFeedback(widget.entry);

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final otherRole = entry.role == 'finder' ? 'claimant' : 'finder';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _IconTile(
                  icon: Icons.reviews_outlined,
                  color: AppColors.warn,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.itemTitle.isEmpty
                            ? 'Returned item'
                            : entry.itemTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Feedback after a completed return',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FeedbackBlock(entry: entry),
            const SizedBox(height: 20),
            const Text(
              'Other side of this return',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            FutureBuilder<FeedbackEntry?>(
              future: _counterpart,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'Unable to load the other feedback.',
                    style: TextStyle(color: AppColors.muted),
                  );
                }
                final other = snapshot.data;
                if (other == null) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      'The $otherRole has not left feedback for this return.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                return _FeedbackBlock(entry: other);
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Reference',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _IdRow(label: 'Author ID (${entry.role})', value: entry.authorId),
            _IdRow(
              label: 'Other user ID ($otherRole)',
              value: entry.otherUserId,
            ),
            _IdRow(label: 'Return ID', value: entry.returnId),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBlock extends StatelessWidget {
  final FeedbackEntry entry;
  const _FeedbackBlock({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border(
          left: BorderSide(color: _ratingColor(entry.rating), width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RolePill(role: entry.role),
              const Spacer(),
              _Stars(rating: entry.rating),
              const SizedBox(width: 6),
              Text(
                '${entry.rating}/5',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _fullDate(entry.createdAt),
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          _Comment(text: entry.recommendation),
        ],
      ),
    );
  }
}

class _IdRow extends StatelessWidget {
  final String label;
  final String value;
  const _IdRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted)),
          SelectableText(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int rating;
  final double size;
  const _Stars({required this.rating, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$rating out of 5 stars',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 5; i++)
              Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: i < rating ? AppColors.warn : AppColors.muted,
              ),
          ],
        ),
      ),
    );
  }
}
