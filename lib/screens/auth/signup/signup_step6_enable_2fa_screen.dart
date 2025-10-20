import 'package:flutter/material.dart';
import 'package:hoop/widgets/progress_bar.dart';

class SignupStep6Enable2FAScreen extends StatefulWidget {
  const SignupStep6Enable2FAScreen({super.key});

  @override
  State<SignupStep6Enable2FAScreen> createState() =>
      _SignupStep6Enable2FAScreenState();
}

class _SignupStep6Enable2FAScreenState
    extends State<SignupStep6Enable2FAScreen> {
  final int totalSteps = 6;
  final int currentStep = 6;

  final List<String> _methods = const [
    'SMS Text Message',
    'Authenticator App',
    'Email',
  ];

  String _selectedMethod = 'SMS Text Message';
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _enable2FA() {
    if (_codeController.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the code we sent')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('2FA enabled successfully')),
    );
    // TODO: Navigate to dashboard/onboarding complete
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SignupProgressBar(currentStep: currentStep, totalSteps: totalSteps),
              const SizedBox(height: 20),

              const Center(
                child: Icon(
                  Icons.verified_user_outlined,
                  color: Colors.greenAccent,
                  size: 56,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Enable 2FA',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Add an extra layer of security to your account',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F0FF).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Why enable 2FA?',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 10),
                    _Bullet(text: 'Protect your savings and transactions'),
                    _Bullet(text: 'Prevent unauthorized access'),
                    _Bullet(text: 'Required for high-value transactions'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('Choose 2FA Method', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                items: _methods
                    .map((m) => DropdownMenuItem<String>(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMethod = v ?? _selectedMethod),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Enter Test Code', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  hintText: 'Enter the code we just sent',
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF166534),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _enable2FA,
                  child: const Text('Enable 2FA'),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C1F2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // TODO: Optionally allow skipping for now
                  },
                  child: const Text('Skip for now', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}


