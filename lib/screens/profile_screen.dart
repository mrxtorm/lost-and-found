import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/local/app_database.dart';
import '../data/sync/sync_manager.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/claim_provider.dart';
import '../providers/item_provider.dart';
import '../providers/notification_provider.dart';
import 'login_screen.dart';

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

    final displayName = (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!
        : "Unnamed User";

    final email = user?.email ?? "No email";

    // Real "My Activity" counts, computed from the signed-in user's own
    // posts instead of hardcoded placeholder numbers.
    final myPosts = itemProvider.myPosts;
    final postsCount = myPosts.length;
    final lostCount =
        myPosts.where((item) => item.status.toLowerCase() == 'lost').length;
    final foundCount =
        myPosts.where((item) => item.status.toLowerCase() == 'found').length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      size: 55,
                      color: Colors.blue.shade700,
                    ),
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
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton.icon(
                    onPressed: () {
                      _showComingSoon(context, "Edit Profile");
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text("Edit Profile"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "My Activity",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.article_outlined,
                    value: "$postsCount",
                    label: "Posts",
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.search,
                    value: "$lostCount",
                    label: "Lost",
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle_outline,
                    value: "$foundCount",
                    label: "Found",
                    color: Colors.green,
                  ),
                ),
              ],
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
              onTap: () => _showComingSoon(context, "Personal Information"),
            ),

            _buildMenuCard(
              icon: Icons.lock_outline,
              title: "Change Password",
              subtitle: "Update your account password",
              onTap: () => _showComingSoon(context, "Change Password"),
            ),

            _buildMenuCard(
              icon: Icons.notifications_outlined,
              title: "Notification Settings",
              subtitle: "Manage your notifications",
              onTap: () => _showComingSoon(context, "Notification Settings"),
            ),

            const SizedBox(height: 25),

            const Text(
              "App",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _buildMenuCard(
              icon: Icons.info_outline,
              title: "About Campus Lost & Found",
              subtitle: "Learn more about the application",
              onTap: () => _showAboutDialog(context),
            ),

            _buildMenuCard(
              icon: Icons.help_outline,
              title: "Help & Support",
              subtitle: "Get help with the application",
              onTap: () => _showComingSoon(context, "Help & Support"),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  "Log Out",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                "Campus Lost & Found\nVersion 1.0.0",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
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

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature will be implemented later.")),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Campus Lost & Found"),
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