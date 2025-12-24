import 'package:flutter/material.dart';
import 'package:hoop/components/inputs/input.dart';
import 'package:hoop/screens/auth/signup/ignup_step1_screen.dart';
import 'package:hoop/screens/features/home_screen.dart';
import 'package:hoop/widgets/progress_bar.dart'; // ✅ Import the progress bar

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    // 🔹 Detect system brightness
    final bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    // 🔹 Define colors dynamically
    final backgroundColor =
        isDarkMode ? const Color(0xFF0C0E1A) : Colors.grey[100];
    final cardColor = isDarkMode ? const Color(0xFF1C1F2E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? Colors.grey : Colors.grey[700];
    final borderColor =
        isDarkMode ? Colors.white24 : Colors.grey.withOpacity(0.4);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Progress Bar at Top (Full)
              const SignupProgressBar(currentStep: 1, totalSteps: 1),
              const SizedBox(height: 12),

              // 🔒 Lock Icon Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to your Hoop account",
                style: TextStyle(color: hintColor, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // 📧 Email / Phone
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email or Phone",
                  style: TextStyle(color: hintColor),
                ),
              ),
              const SizedBox(height: 8),
              HoopInput(
                controller: _emailController,
                hintText: "Enter your email or phone",
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 20),

              // 🔑 Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Password", style: TextStyle(color: hintColor)),
              ),
              const SizedBox(height: 8),
              HoopInput(
                controller: _passwordController,
                hintText: "Enter your password",
                obscureText: !isPasswordVisible,
                isDarkMode: isDarkMode,
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: hintColor,
                  ),
                  onPressed: () =>
                      setState(() => isPasswordVisible = !isPasswordVisible),
                ),
              ),
              const SizedBox(height: 8),

              // ✅ Remember Me + Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 🚀 Sign In Button
              // 🚀 Sign In Button
              GestureDetector(
                onTap: () {
                  // After validation or API login, go to the main app
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0a1866), Color(0xFF1347cd)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Sign In",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        width: 2.5,
                      ),
                      const Icon(
                        Icons.arrow_forward_sharp,
                        color: Colors.white,
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 📝 Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: hintColor),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupStep1Screen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
