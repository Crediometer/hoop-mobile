// lib/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoop/states/auth_state.dart';
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
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Hoop App',
        
        navigatorKey: navigatorKey,
        
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
        ),
        
        darkTheme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0F111A),
        ),
        
        themeMode: ThemeMode.system,
        home: const AuthWrapper(), // Use AuthWrapper instead of LoginScreen
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
            body: Center(
              child: CircularProgressIndicator(),
            ),
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