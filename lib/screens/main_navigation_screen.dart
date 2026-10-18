import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/local/connectivity_service.dart';
import '../data/sync/sync_manager.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/claim_provider.dart';
import '../providers/item_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'my_posts_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    MessagesScreen(),
    MyPostsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Bind the signed-in user's uid to the providers that scope their
    // data per-user, now that we know a user is actually signed in. This
    // also kicks off each repository's live Firestore listener and an
    // immediate push of anything that was queued locally while offline.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthProvider>().user?.uid;
      context.read<ItemProvider>().setCurrentUserId(uid);
      context.read<ChatProvider>().setCurrentUserId(uid);
      context.read<ClaimProvider>().setCurrentUserId(uid);
      context.read<NotificationProvider>().setCurrentUserId(uid);
      context.read<SyncManager>().setCurrentUserId(uid);
    });
  }


  /// Wraps [icon] in a red badge showing [count]; hidden when it is zero.
  Widget _badged(int count, Widget icon) {
    return Badge(
      isLabelVisible: count > 0,
      backgroundColor: AppColors.error,
      textColor: Colors.white,
      label: Text(count > 99 ? '99+' : '$count'),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Selecting just the counts rebuilds only when a badge value changes.
    final unreadMessages =
        context.select<ChatProvider, int>((p) => p.totalUnreadCount);
    final unreadNotifications =
        context.select<NotificationProvider, int>((p) => p.unreadCount);

    return Scaffold(
      body: Column(
        children: [
          // Tells the user why things may not update right away.
          Builder(builder: (context) {
            final connectivity = context.read<ConnectivityService>();
            return StreamBuilder<bool>(
              stream: connectivity.onConnectivityChanged,
              initialData: connectivity.isOnlineNow,
              builder: (context, snapshot) {
                final online = snapshot.data ?? true;
                return AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: online
                      ? const SizedBox(width: double.infinity)
                      : SafeArea(
                          bottom: false,
                          child: const OfflineBanner(),
                        ),
                );
              },
            );
          }),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index != selectedIndex) HapticFeedback.selectionClick();
          setState(() => selectedIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: _badged(unreadMessages, const Icon(Icons.chat_bubble_outline)),
            selectedIcon: _badged(unreadMessages, const Icon(Icons.chat_bubble)),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'My Posts',
          ),
          NavigationDestination(
            icon: _badged(
              unreadNotifications,
              const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: _badged(
              unreadNotifications,
              const Icon(Icons.notifications),
            ),
            label: 'Notifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
