import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import 'edit_profile_screen.dart';

class PersonalInformationScreen extends StatelessWidget {
  const PersonalInformationScreen({super.key});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${_months[local.month - 1]} ${local.day}, ${local.year} '
        '· $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.displayName?.trim();
    final verified = user?.emailVerified ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Personal Information'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _InfoCard(children: [
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Full name',
              value: (name == null || name.isEmpty) ? 'Not set' : name,
            ),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user?.email ?? 'No email',
              trailing: Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(
                  verified ? Icons.verified : Icons.error_outline,
                  size: 16,
                  color: verified ? AppColors.success : AppColors.warn,
                ),
                label: Text(verified ? 'Verified' : 'Not verified'),
                backgroundColor:
                    verified ? AppColors.foundSoft : AppColors.warnSoft,
                side: BorderSide.none,
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _InfoCard(children: [
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Member since',
              value: _formatDate(user?.metadata.creationTime),
            ),
            _InfoRow(
              icon: Icons.login,
              label: 'Last sign-in',
              value: _formatDate(user?.metadata.lastSignInTime),
            ),
            _InfoRow(
              icon: Icons.fingerprint,
              label: 'User ID',
              value: user?.uid ?? '-',
              trailing: IconButton(
                tooltip: 'Copy user ID',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: user == null
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: user.uid));
                        AppSnack.success(context, 'User ID copied.');
                      },
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Share your User ID with an admin if you need help with your '
            'account.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 56),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 15,
          color: AppColors.ink,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
    );
  }
}
