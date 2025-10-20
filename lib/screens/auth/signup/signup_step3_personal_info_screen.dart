import 'package:flutter/material.dart';
import 'package:hoop/screens/auth/signup/signup_step4_facial_verification_screen.dart';
import 'package:hoop/widgets/progress_bar.dart';
import 'package:intl/intl.dart';

class SignupStep3PersonalInfoScreen extends StatefulWidget {
  const SignupStep3PersonalInfoScreen({super.key});

  @override
  State<SignupStep3PersonalInfoScreen> createState() =>
      _SignupStep3PersonalInfoScreenState();
}

class _SignupStep3PersonalInfoScreenState
    extends State<SignupStep3PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bvnController = TextEditingController();

  // selections
  String? _selectedGender;
  String? _selectedState;
  String? _selectedLga;

  // data
  final int totalSteps = 5;
  final int currentStep = 3;

  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> states = ['Lagos', 'Abuja', 'Kano'];

  final Map<String, List<String>> lgasByState = {
    'Lagos': ['ikeja', 'lekki', 'mainland'],
    'Abuja': ['Gwagwalada', 'Kuje', 'Municipal'],
    'Kano': ['Dala', 'Gwale', 'Kano Municipal'],
  };

  @override
  void dispose() {
    _dobController.dispose();
    _addressController.dispose();
    _bvnController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    DateTime initialDate = DateTime.now().subtract(
      const Duration(days: 365 * 18),
    );
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        // keep dark theme for the date picker
        return Theme(data: Theme.of(context).copyWith(), child: child!);
      },
    );

    if (picked != null) {
      _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  void _onStateChanged(String? value) {
    setState(() {
      _selectedState = value;
      _selectedLga = null; // reset LGA when state changes
    });
  }

void _onSubmit() {
  if (!_formKey.currentState!.validate()) return;

  if (_selectedGender == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select your gender')),
    );
    return;
  }

  if (_selectedState == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select your state')),
    );
    return;
  }

  if (_selectedLga == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select your LGA')),
    );
    return;
  }

  // All good — gather data
  final payload = {
    'dob': _dobController.text,
    'gender': _selectedGender,
    'address': _addressController.text,
    'state': _selectedState,
    'lga': _selectedLga,
    'bvn': _bvnController.text,
  };

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Personal info saved')),
  );

  // ✅ Go to Facial Verification (Step 4)
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const SignupStep4FacialVerificationScreen(),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final lgaOptions = (_selectedState != null)
        ? lgasByState[_selectedState!] ?? []
        : [];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SignupProgressBar(
                currentStep: currentStep,
                totalSteps: totalSteps,
              ),
              const SizedBox(height: 12),

              // user svg like icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1F2E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 40,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Help us verify your identity',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Date of Birth
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Date of Birth',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _pickDateOfBirth,
                      decoration: InputDecoration(
                        hintText: 'Select your date of birth',
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.calendar_today,
                            color: Colors.grey,
                          ),
                          onPressed: _pickDateOfBirth,
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please select your DOB'
                          : null,
                    ),
                    const SizedBox(height: 18),

                    // Gender
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Gender',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      items: genders
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedGender = val),
                      decoration: const InputDecoration(
                        hintText: 'Select gender',
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Select gender' : null,
                    ),
                    const SizedBox(height: 18),

                    // Address
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Address',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your address',
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please enter your address'
                          : null,
                    ),
                    const SizedBox(height: 18),

                    // State
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'State',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      items: states
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: _onStateChanged,
                      decoration: const InputDecoration(
                        hintText: 'Select state',
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Select state' : null,
                    ),
                    const SizedBox(height: 18),

                    // LGA
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'LGA',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedLga,
                      items: lgaOptions
                          .map(
                            (l) => DropdownMenuItem<String>(
                              value: l,
                              child: Text(l),
                            ),
                          )
                          .toList(),

                      onChanged: (val) => setState(() => _selectedLga = val),
                      decoration: const InputDecoration(hintText: 'Select LGA'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Select LGA' : null,
                    ),
                    const SizedBox(height: 18),

                    // BVN
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'BVN (Bank Verification Number)',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bvnController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Enter your BVN',
                      ),
                      maxLength: 11,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter BVN';
                        if (v.length != 11) return 'BVN must be 11 digits';
                        if (!RegExp(r'^\d{11}$').hasMatch(v))
                          return 'BVN must be digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    const SizedBox(height: 22),
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
                        onPressed: _onSubmit,
                        child: const Text(
                          'Next',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
