import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/screens/auth/signup/signup_step5_primary_account_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrimarySetupRequiredScreen extends StatelessWidget {
  const PrimarySetupRequiredScreen({super.key});

  Future<void> _markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("needsSetup", false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0E1A) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ICON
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1F2E)
                      : const Color(0xFFFDEDE5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFFF97316),
                  size: 44,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                "Account Setup Required",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                "To continue using the app, you need to complete your primary account setup for secure transactions.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),

              const SizedBox(height: 26),

              // SECURE BANKING BOX
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1F2E)
                      : const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.security, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Secure Banking\nYour banking information is encrypted and secure",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // QUICK SETUP BOX
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF182418)
                      : const Color(0xFFE8FFEF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Quick Setup\nTakes less than 2 minutes to complete",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              HoopButton(
                buttonText: "Setup Primary Account →",
                isLoading: false,
                onPressed: () async {
                  final done = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const SetupPrimaryAccountScreen(popOnAdd: true),
                    ),
                  );

                  if (done == true) {
                    await _markDone();
                    Navigator.pop(context); // Back to Community
                  }
                },
              ),
            

              const SizedBox(height: 12),
              Text(
                "This is required to access all app features",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
