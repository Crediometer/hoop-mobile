import 'package:flutter/material.dart';
import 'package:hoop/widgets/progress_bar.dart';
import 'package:hoop/screens/auth/signup/signup_step6_enable_2fa_screen.dart';

class SignupStep5PrimaryAccountScreen extends StatefulWidget {
  const SignupStep5PrimaryAccountScreen({super.key});

  @override
  State<SignupStep5PrimaryAccountScreen> createState() =>
      _SignupStep5PrimaryAccountScreenState();
}

class _SignupStep5PrimaryAccountScreenState
    extends State<SignupStep5PrimaryAccountScreen> {
  final int totalSteps = 6;
  final int currentStep = 5;

  final _formKey = GlobalKey<FormState>();
  final List<String> _banks = <String>[
    'Select your bank',
    'Bank of America',
    'Chase',
    'Wells Fargo',
    'Citi',
  ];

  String _selectedBank = 'Select your bank';
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  void _onAddAccount() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: Submit account info or navigate onwards
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SignupStep6Enable2FAScreen(),
      ),
    );
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

              const Text(
                'Setup Primary Account',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your bank account for transactions',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bank Name', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedBank,
                      items: _banks
                          .map((b) => DropdownMenuItem<String>(
                                value: b,
                                child: Text(b),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedBank = v ?? _selectedBank),
                      decoration: const InputDecoration(
                        hintText: 'Select your bank',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      validator: (v) => (v == null || v == 'Select your bank')
                          ? 'Please select your bank'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    const Text('Account Number', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Enter your account number',
                      ),
                      validator: (v) => (v == null || v.trim().length < 6)
                          ? 'Enter a valid account number'
                          : null,
                      onChanged: (v) {
                        // Example: derive/show account name after validation/lookup
                        // For now, mock populate when length >= 6
                        if (v.trim().length >= 6) {
                          _accountNameController.text = 'John Doe';
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    const Text('Account Name', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _accountNameController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Account name will appear here',
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(Icons.verified_user_outlined, color: Colors.white70),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Secure & Encrypted',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                                SizedBox(height: 6),
                                Text(
                                  'Your banking information is encrypted and secure. We never store your login credentials.',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

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
                        onPressed: _onAddAccount,
                        child: const Text('Add Account  →', style: TextStyle(fontSize: 16)),
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


