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
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _bvnController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // selections
  String? _selectedGender;

  // data
  final int totalSteps = 6;
  final int currentStep = 3;

  final List<String> genders = ['Male', 'Female', 'Other'];
  
  // Location data
  String? _locationLat;
  String? _locationLng;

  @override
  void dispose() {
    _dobController.dispose();
    _occupationController.dispose();
    _bvnController.dispose();
    _bioController.dispose();
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

  void _getCurrentLocation() {
    // Mock location for demo - in real app, use geolocator package
    setState(() {
      _locationLat = "31.5353";
      _locationLng = "74.2893";
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

  // All good — gather data (for future API call)
  // final payload = {
  //   'dob': _dobController.text,
  //   'gender': _selectedGender,
  //   'occupation': _occupationController.text,
  //   'bvn': _bvnController.text,
  //   'bio': _bioController.text,
  //   'location': _locationLat != null ? '$_locationLat, $_locationLng' : null,
  // };

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
                        hintText: 'mm/dd/yyyy',
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

                    // Occupation
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Occupation',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _occupationController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your occupation',
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please enter your occupation'
                          : null,
                    ),
                    const SizedBox(height: 18),

                    // BVN
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'BVN',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bvnController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Enter 11-digit BVN',
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
                    const SizedBox(height: 18),

                    // Bio
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Bio',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Tell us about yourself',
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Location Permission Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location Permission Required',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: _locationLat != null ? Colors.green : Colors.grey,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _locationLat != null 
                                    ? 'Location captured: $_locationLat, $_locationLng'
                                    : 'Location not captured',
                                style: TextStyle(
                                  color: _locationLat != null ? Colors.grey[600] : Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (_locationLat == null) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _getCurrentLocation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Get Location',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Continue Button
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
                          'Continue',
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
