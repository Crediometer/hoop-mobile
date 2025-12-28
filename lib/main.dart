// lib/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:hoop/constants/strings.dart';
import 'package:hoop/services/websocket_service.dart';
import 'package:hoop/states/ws/notification_socket.dart';
import 'package:provider/provider.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:hoop/states/group_state.dart'; // Import GroupCommunityProvider
import 'package:hoop/screens/auth/login_screen.dart';
import 'package:hoop/screens/features/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
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
        ChangeNotifierProvider<NotificationWebSocketHandler>(
          create: (_) => NotificationWebSocketHandler(
            socketService: BaseWebSocketService(
              namespace: '/notifications',
            ),
          ),
          lazy: true,
        ),
        // Add other providers as needed
      ],
      child: MaterialApp(
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
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: {
          '/home': (_) => const HomeScreen(),
          '/login': (_) => const LoginScreen(),
        },
      ),
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If not authenticated, show login screen
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // If authenticated but needs onboarding
        if (authProvider.needsAccountOnboarding) {
          // Return onboarding screen when you create it
          // return const OnboardingScreen();
          return const HomeScreen(); // Temporary fallback
        }

        // Fully authenticated user
        return const HomeScreen();
      },
    );
  }
}
