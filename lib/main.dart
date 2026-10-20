import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/local/app_database.dart';
import 'data/local/connectivity_service.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/claim_repository.dart';
import 'data/repositories/item_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/sync/sync_manager.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/claim_provider.dart';
import 'providers/item_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/profile_sync_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- Offline-first local database / sync wiring ---
  //
  // These are plain Dart objects (not widgets), created once here and
  // handed to the providers below and to SyncManager. AppDatabase is the
  // local source of truth the UI reads from; Firestore/Cloudinary remain
  // the cloud source of truth. SyncManager keeps the two in sync.
  final database = AppDatabase();
  final connectivity = ConnectivityService();
  await connectivity.initialize();

  final itemRepository = ItemRepository(database: database);
  final claimRepository = ClaimRepository(database: database);
  final chatRepository = ChatRepository(database: database);
  final notificationRepository = NotificationRepository(database: database);

  final syncManager = SyncManager(
    connectivity: connectivity,
    itemRepository: itemRepository,
    claimRepository: claimRepository,
    chatRepository: chatRepository,
    notificationRepository: notificationRepository,
    profileSyncService: ProfileSyncService(database: database),
  );
  syncManager.start();

  // Applied before runApp so the first frame already uses the saved theme.
  final themeController = ThemeController();
  await themeController.load();

  runApp(CampusLostFoundApp(
    database: database,
    connectivity: connectivity,
    itemRepository: itemRepository,
    claimRepository: claimRepository,
    chatRepository: chatRepository,
    notificationRepository: notificationRepository,
    syncManager: syncManager,
    themeController: themeController,
  ));
}

class CampusLostFoundApp extends StatelessWidget {
  final AppDatabase database;
  final ConnectivityService connectivity;
  final ItemRepository itemRepository;
  final ClaimRepository claimRepository;
  final ChatRepository chatRepository;
  final NotificationRepository notificationRepository;
  final SyncManager syncManager;
  final ThemeController themeController;

  const CampusLostFoundApp({
    super.key,
    required this.database,
    required this.connectivity,
    required this.itemRepository,
    required this.claimRepository,
    required this.chatRepository,
    required this.notificationRepository,
    required this.syncManager,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        Provider<ConnectivityService>.value(value: connectivity),
        Provider<ItemRepository>.value(value: itemRepository),
        Provider<ClaimRepository>.value(value: claimRepository),
        Provider<ChatRepository>.value(value: chatRepository),
        Provider<NotificationRepository>.value(value: notificationRepository),
        Provider<SyncManager>.value(value: syncManager),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider(itemRepository)),
        ChangeNotifierProvider(create: (_) => ClaimProvider(claimRepository)),
        ChangeNotifierProvider(create: (_) => ChatProvider(chatRepository)),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationRepository),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FoundIt',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          // Resolved by ThemeController (not left to MaterialApp) so the
          // Material theme always matches the AppColors palette.
          themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
