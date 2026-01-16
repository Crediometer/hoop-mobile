import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/screens/auth/login_screen.dart';
import 'package:hoop/screens/auth/signup/signup_step5_primary_account_screen.dart';
import 'package:hoop/screens/features/home_screen.dart';
import 'package:hoop/screens/groups/chat_detail_screen.dart';
import 'package:hoop/screens/groups/create_group.dart';
import 'package:hoop/screens/groups/group_detail_public_screen.dart';
import 'package:hoop/screens/groups/group_detail_screen.dart';
import 'package:hoop/screens/groups/group_invite.dart';
import 'package:hoop/screens/notifications/notification_screen.dart';
import 'package:hoop/screens/notifications/notification_setting.dart';
import 'package:hoop/screens/onboarding/onboarding_screen.dart';
import 'package:hoop/screens/onboarding/splash_screen.dart';
import 'package:hoop/screens/settings/primary_account_info.dart';
import 'package:hoop/screens/settings/profile_setting.dart';
import 'package:hoop/screens/settings/security_setting.dart';
import 'package:hoop/services/websocket_service.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:hoop/states/group_state.dart';
import 'package:hoop/states/onesignal_state.dart';
import 'package:hoop/states/webrtc_manager.dart';
import 'package:hoop/states/ws/chat_sockets.dart';
import 'package:hoop/states/ws/notification_socket.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
   // Ensure that the Flutter binding is initialized.
  WidgetsFlutterBinding.ensureInitialized(); 

  // Force portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider<GroupCommunityProvider>(
          create: (_) => GroupCommunityProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider<OneSignalService>(
          create: (_) => OneSignalService.instance,
        ),
        ChangeNotifierProvider<NotificationWebSocketHandler>(
          create: (_) => NotificationWebSocketHandler(
            socketService: BaseWebSocketService(namespace: '/notifications'),
          ),
          lazy: true,
        ),
        // FIXED: Initialize ChatWebSocketHandler properly
        ChangeNotifierProvider<ChatWebSocketHandler>(
          create: (_) {
            final handler = ChatWebSocketHandler();
            // Initialize after creation but before returning
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await handler.initialize();
            });
            return handler;
          },
          lazy: true,
        ),
        ChangeNotifierProvider<WebRTCManager>(
          create: (_) => WebRTCManager(),
          lazy: true,
        ),
      ],
      child: MainApp(),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // init async once
    Future.microtask(() => context.read<AuthProvider>().init());

    final isDark = context.watch<AuthProvider>().isDark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hoop App',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFFF97316),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF97316),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF97316),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: isDark == 'system'
          ? ThemeMode.system
          : isDark == 'light'
          ? ThemeMode.light
          : ThemeMode.dark, //
      // Use onGenerateRoute instead of home/routes
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        return _generateRoute(settings);
      },
    );
  }
}

Route<dynamic> _generateRoute(RouteSettings settings) {
  Map<String, dynamic> getArguments() {
    return (settings.arguments as Map<String, dynamic>?) ?? {};
  }

  print("settings.name??? ${settings.name}");
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
        builder: (_) => const AuthWrapper(),
        settings: settings,
      );

    case '/login':
      return MaterialPageRoute(
        builder: (_) => const LoginScreen(),
        settings: settings,
      );

    case '/settings/primary-account':
      return MaterialPageRoute(builder: (_) => const PrimaryAccountScreen());
    case '/settings/profile':
      return MaterialPageRoute(builder: (_) => const ProfileDetailsScreen());
    case '/settings/security':
      return MaterialPageRoute(builder: (_) => const SecuritySettingsScreen());
    case '/home':
      return MaterialPageRoute(
        builder: (_) => const HomeScreen(),
        settings: settings,
      );

    case '/notifications':
      return MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
        settings: settings,
      );
    case '/settings/notifications':
      return MaterialPageRoute(
        builder: (_) => const NotificationSettingsScreen(),
        settings: settings,
      );

    case '/group/detail':
      final args = getArguments();
      return MaterialPageRoute(
        builder: (_) => GroupDetailScreen(group: args as Map<String, dynamic>),
        settings: settings,
      );

    case '/group/detail/public':
      final args = getArguments();
      return MaterialPageRoute(
        builder: (_) =>
            GroupDetailPublicScreen(group: args as Map<String, dynamic>),
        settings: settings,
      );

    case '/group/invite':
      final args = getArguments();
      return MaterialPageRoute(
        builder: (_) => GroupInviteScreen(groupId: args as String),
        settings: settings,
      );

    case '/group/create':
      return MaterialPageRoute(
        builder: (_) => const GroupCreationFlowScreen(),
        settings: settings,
      );

    case '/chat/detail':
      final args = getArguments();
      return MaterialPageRoute(
        builder: (_) =>
            ChatDetailScreen(group: args as Map<String, dynamic>? ?? {}),
        settings: settings,
      );

    // ========== ACCOUNT ==========
    case '/account/verify-primary':
      return MaterialPageRoute<bool>(
        builder: (_) => const VerifyPrimaryAccountScreen(),
        settings: settings,
      );

    case '/account/setup-primary':
      final args = getArguments();
      return MaterialPageRoute(
        builder: (_) => SetupPrimaryAccountScreen(
          popOnAdd: args['popOnAdd'] as bool? ?? false,
        ),
        settings: settings,
      );

    // ========== FALLBACK ==========
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Page Not Found')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Page not found'),
                const SizedBox(height: 16),
                HoopButton(
                  onPressed: () {
                    Navigator.of(
                      navigatorKey.currentContext!,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  buttonText:'Go Home',
                ),
              ],
            ),
          ),
        ),
        settings: settings,
      );
  }
}
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading state
        if (authProvider.isLoading) {
          return SplashScreen();
        }
        // AFTER loading is complete, check onboarding
        if (authProvider.needsUserOnboarding) {
          return OnboardingScreen();
        }   
        // If not authenticated, show login screen
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // If authenticated but needs onboarding
        if (authProvider.needsAccountOnboarding) {
          return const HomeScreen(); // Or actual onboarding screen
        }

        // Fully authenticated user
        return const HomeScreen();
      },
    );
  }
}