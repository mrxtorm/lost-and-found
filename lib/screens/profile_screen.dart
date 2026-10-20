import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../data/local/app_database.dart';
import '../data/sync/sync_manager.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/claim_provider.dart';
import '../providers/item_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import '../services/admin_service.dart';
import '../widgets/profile_avatar.dart';
import 'admin_dashboard_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'login_screen.dart';
import 'notification_settings_screen.dart';
import 'personal_information_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _performLogout(BuildContext context) async {
    // Grab everything we need before the first `await`, since the
    // widget tree (and this context) may be torn down once navigation
    // starts.
    final authProvider = context.read<AuthProvider>();
    final itemProvider = context.read<ItemProvider>();
    final chatProvider = context.read<ChatProvider>();
    final claimProvider = context.read<ClaimProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final syncManager = context.read<SyncManager>();
    final database = context.read<AppDatabase>();
    final signedOutUserId = authProvider.user?.uid;

    await authProvider.signOut();

    // Clear per-user data so the next sign-in doesn't briefly show the
    // previous user's posts/conversations/notifications.
    itemProvider.setCurrentUserId(null);
    chatProvider.setCurrentUserId(null);
    claimProvider.setCurrentUserId(null);
    notificationProvider.setCurrentUserId(null);
    syncManager.setCurrentUserId(null);

    // Remove this account's cached conversations/notifications/claims from
    // the local database so they're not visible if a different account
    // signs in on this device. Anything still pending sync (e.g. a message
    // sent offline that hasn't reached Firestore yet) is left alone so it
    // isn't lost - it'll sync next time this same account is online.
    if (signedOutUserId != null) {
      await database.clearUserScopedCacheOnLogout(signedOutUserId);
    }

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Log Out"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performLogout(context);
              },
              child: const Text("Log Out"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final itemProvider = context.watch<ItemProvider>();

    final displayName =
        (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!
        : "Unnamed User";

    final email = user?.email ?? "No email";

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: AppColors.surface,
        title: Text(
          "Profile",
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: itemProvider.refreshHome,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // PROFILE HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  ProfileAvatar(
                    photoUrl: user?.photoURL,
                    name: user?.displayName,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    style: TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton.icon(
                    onPressed: () => _open(context, const EditProfileScreen()),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text("Edit Profile"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Activity",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _buildStatsRow(itemProvider),
            ),

            const SizedBox(height: 25),

            const Text(
              "Account",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _buildMenuCard(
              icon: Icons.person_outline,
              title: "Personal Information",
              subtitle: "Manage your account details",
              onTap: () => _open(context, const PersonalInformationScreen()),
            ),

            _buildMenuCard(
              icon: Icons.lock_outline,
              title: "Change Password",
              subtitle: "Update your account password",
              onTap: () => _open(context, const ChangePasswordScreen()),
            ),

            _buildMenuCard(
              icon: Icons.notifications_outlined,
              title: "Notification Settings",
              subtitle: "Manage your notifications",
              onTap: () => _open(context, const NotificationSettingsScreen()),
            ),

            // Shown only when admins/{uid} exists. Access to the data itself
            // is enforced by firestore.rules, not by hiding this entry.
            _AdminSection(
              key: ValueKey(user?.uid),
              builder: (onTap, pendingCount) => _buildMenuCard(
                icon: Icons.admin_panel_settings_outlined,
                title: "Admin Dashboard",
                subtitle: "Review reported posts and messages",
                onTap: onTap,
                badgeCount: pendingCount,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "App",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _buildMenuCard(
              icon: Icons.dark_mode_outlined,
              title: "Appearance",
              subtitle: _themeLabel(context.watch<ThemeController>().mode),
              onTap: () => _showAppearanceSheet(context),
            ),

            _buildMenuCard(
              icon: Icons.info_outline,
              title: "About FoundIt",
              subtitle: "Learn more about the application",
              onTap: () => _showAboutDialog(context),
            ),

            _buildMenuCard(
              icon: Icons.help_outline,
              title: "Help & Support",
              subtitle: "Get help with the application",
              onTap: () => _open(context, const HelpSupportScreen()),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, color: AppColors.lost),
                label: const Text(
                  "Log Out",
                  style: TextStyle(
                    color: AppColors.lost,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.lost),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                "FoundIt\nVersion 1.0.0",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Same red count badge as the bottom navigation bar.
            if (badgeCount > 0) ...[
              Badge(
                backgroundColor: AppColors.error,
                textColor: Colors.white,
                label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
              ),
              const SizedBox(width: 10),
            ],
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.muted),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  /// Post counts for the signed-in user (all of their posts, regardless of
  /// the My Posts filter).
  Widget _buildStatsRow(ItemProvider itemProvider) {
    final posts = itemProvider.allMyPosts;
    int count(String status) =>
        posts.where((p) => p.status.toLowerCase() == status).length;

    Widget stat(String label, int value, Color color) {
      return Expanded(
        child: Column(
          children: [
            Text(
              itemProvider.isLoadingMine ? '-' : '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      );
    }

    Widget divider() => Container(width: 1, height: 32, color: AppColors.line);

    return Row(
      children: [
        stat("Posts", posts.length, AppColors.ink),
        divider(),
        stat("Lost", count('lost'), AppColors.lost),
        divider(),
        stat("Found", count('found'), AppColors.found),
        divider(),
        stat("Claimed", count('claimed'), AppColors.primary),
      ],
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return "Light";
      case ThemeMode.dark:
        return "Dark";
      case ThemeMode.system:
        return "Same as device";
    }
  }

  void _showAppearanceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final controller = sheetContext.watch<ThemeController>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: RadioGroup<ThemeMode>(
              groupValue: controller.mode,
              onChanged: (mode) {
                if (mode == null) return;
                controller.setMode(mode);
                Navigator.pop(sheetContext);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      "Appearance",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  for (final mode in const [
                    ThemeMode.system,
                    ThemeMode.light,
                    ThemeMode.dark,
                  ])
                    RadioListTile<ThemeMode>(
                      value: mode,
                      title: Text(_themeLabel(mode)),
                      secondary: Icon(switch (mode) {
                        ThemeMode.system => Icons.brightness_auto_outlined,
                        ThemeMode.light => Icons.light_mode_outlined,
                        ThemeMode.dark => Icons.dark_mode_outlined,
                      }),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("FoundIt"),
          content: const Text(
            "A campus-based Lost & Found application "
            "designed to help students report, discover, "
            "and reclaim lost belongings.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}

class _AdminSection extends StatefulWidget {
  final Widget Function(VoidCallback onTap, int pendingCount) builder;

  const _AdminSection({super.key, required this.builder});

  @override
  State<_AdminSection> createState() => _AdminSectionState();
}

class _AdminSectionState extends State<_AdminSection> {
  // Live, so granting or removing admin access in the Firebase Console
  // shows up without restarting the app.
  late final Stream<bool> _isAdmin = AdminService().watchIsCurrentUserAdmin();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _isAdmin,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return _AdminEntry(builder: widget.builder);
      },
    );
  }
}

/// Only built while the user is an admin, so its pending-count listener
/// starts fresh each time admin access is (re)granted and regular users
/// never open a listener the rules would reject.
class _AdminEntry extends StatefulWidget {
  final Widget Function(VoidCallback onTap, int pendingCount) builder;
  const _AdminEntry({required this.builder});

  @override
  State<_AdminEntry> createState() => _AdminEntryState();
}

class _AdminEntryState extends State<_AdminEntry> {
  late final Stream<int> _pendingCount = AdminService()
      .streamPendingTargetCount();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        const Text(
          "Admin",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<int>(
          stream: _pendingCount,
          builder: (context, countSnapshot) => widget.builder(
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            ),
            countSnapshot.data ?? 0,
          ),
        ),
      ],
    );
  }
}
