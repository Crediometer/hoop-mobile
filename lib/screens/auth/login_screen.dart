import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/components/status/OperationStatus.dart';
import 'package:hoop/screens/auth/signup/ignup_step1_screen.dart';
import 'package:hoop/screens/auth/signup/signup_step3_personal_info_screen.dart';
import 'package:hoop/screens/auth/signup/signup_step4_facial_verification_screen.dart';
import 'package:hoop/screens/auth/signup/signup_step5_primary_account_screen.dart';
import 'package:hoop/screens/features/home_screen.dart';
import 'package:hoop/screens/features/primary_setup_required_screen.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:hoop/utils/forms/validators.dart';
import 'package:hoop/utils/helpers/toasters/snackbar.dart';
import 'package:provider/provider.dart';
import 'package:hoop/components/inputs/input.dart';
import 'package:hoop/widgets/progress_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isPasswordVisible = false;
  bool isLoading = false;
  String? errorMessage;

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // ✅ This now accesses the GLOBAL AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final response = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!response.success) {
        setState(() {
          errorMessage = response.error ?? response.message ?? 'Login failed';
          isLoading = false;
        });

        // Show error snackbar
        if (context.mounted) {
          context.showErrorSnackBar(errorMessage!);
        }
        return;
      }

      if (response.success) {
        if (response.data.operationStatus == OperationStatus.OK ||
            response.data.operationStatus ==
                OperationStatus.TEMPORARY_REDIRECT) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (_) => false,
          );
          return;
        }
        if (response.data.operationStatus ==
            OperationStatus.MOVED_PERMANENTLY) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignupStep3PersonalInfoScreen(),
            ),
          );
        }
        if (response.data.operationStatus == OperationStatus.FOUND) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignupStep4FacialVerificationScreen(),
            ),
          );

          return;
        }
      }
      // If successful, navigation is handled by AuthProvider
    } catch (error) {
      print("Login error: $error");
      setState(() {
        errorMessage = 'An unexpected error occurred';
        isLoading = false;
      });

      if (context.mounted) {
        context.showErrorSnackBar('Login error: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Detect system brightness
    final bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    // 🔹 Define colors dynamically
    final backgroundColor = isDarkMode
        ? const Color(0xFF0C0E1A)
        : Colors.grey[100];
    final cardColor = isDarkMode ? const Color(0xFF1C1F2E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? Colors.grey : Colors.grey[700];
    final errorColor = isDarkMode ? Colors.red[400] : Colors.red;

    return Scaffold(
      // ✅ REMOVED ChangeNotifierProvider wrapper
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
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

                // Error message if any
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: errorColor?.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: errorColor!.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: errorColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: errorColor, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (errorMessage != null) const SizedBox(height: 16),

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
                  hintText: 'Email',
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
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
                  hintText: 'Password',
                  obscureText: !isPasswordVisible,
                  validator: (value) =>
                      Validators.password(value, minLength: 6),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
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
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to forgot password screen
                      },
                      child: const Text(
                        "Forgot password?",
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Login Button
                HoopButton(
                  buttonText: "Sign In →",
                  isLoading: isLoading,
                  onPressed: _login,
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
                      onTap: isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SignupStep1Screen(),
                                ),
                              );
                            },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: isLoading ? Colors.grey : Colors.blueAccent,
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
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
