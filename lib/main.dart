import 'package:flutter/material.dart';
import 'package:hoop/screens/auth/login_screen.dart';
import 'package:hoop/screens/features/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hoop App',

      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),

      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F111A),
      ),

      themeMode: ThemeMode.system,
      home: const LoginScreen(),
      routes: {
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
