import 'package:flutter/material.dart';
import 'package:hoop/screens/auth/signup/signup_step2_otp_screen.dart';
import 'package:hoop/widgets/progress_bar.dart';

class SignupStep1Screen extends StatefulWidget {
  const SignupStep1Screen({super.key});

  @override
  State<SignupStep1Screen> createState() => _SignupStep1ScreenState();
}

class _SignupStep1ScreenState extends State<SignupStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  bool agreeToTerms = false;
  bool isPasswordVisible = false;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void goToNextStep() {
    if (_formKey.currentState!.validate() && agreeToTerms) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignupStep2OtpScreen()),
      );
    } else if (!agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms and Privacy Policy'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              const SignupProgressBar(currentStep: 1, totalSteps: 5),

              const Text(
                "Create Account",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Join the Hoop community",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // First Name
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "First Name",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: firstNameController,
                      decoration: const InputDecoration(hintText: "John"),
                      validator: (value) => value!.isEmpty
                          ? "Please enter your first name"
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Last Name
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Last Name",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: lastNameController,
                      decoration: const InputDecoration(hintText: "Doe"),
                      validator: (value) =>
                          value!.isEmpty ? "Please enter your last name" : null,
                    ),
                    const SizedBox(height: 20),

                    // Email Address
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Email Address",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: "john@example.com",
                      ),
                      validator: (value) => value!.isEmpty
                          ? "Please enter your email"
                          : (!value.contains("@")
                                ? "Enter a valid email"
                                : null),
                    ),
                    const SizedBox(height: 20),

                    // Phone Number
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Phone Number",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: "+234 800 000 0000",
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Enter your phone number" : null,
                    ),
                    const SizedBox(height: 20),

                    // Password
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Password",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: "Create a strong password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) => value!.length < 8
                          ? "Password must be at least 8 characters"
                          : null,
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Must be at least 8 characters with numbers and symbols",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Terms & Privacy
                    Row(
                      children: [
                        Checkbox(
                          value: agreeToTerms,
                          onChanged: (value) {
                            setState(() {
                              agreeToTerms = value ?? false;
                            });
                          },
                          activeColor: Colors.blueAccent,
                        ),
                        Flexible(
                          child: Wrap(
                            children: const [
                              Text("I agree to the "),
                              Text(
                                "Terms of Service",
                                style: TextStyle(color: Colors.blueAccent),
                              ),
                              Text(" and "),
                              Text(
                                "Privacy Policy",
                                style: TextStyle(color: Colors.blueAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Create Account Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: Colors.blueAccent.withOpacity(0.5),
                        ),
                        onPressed: goToNextStep,
                        child: const Text(
                          "Create Account",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
