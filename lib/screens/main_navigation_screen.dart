import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sync/sync_manager.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/claim_provider.dart';
import '../providers/item_provider.dart';
import '../providers/notification_provider.dart';
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'My Posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
