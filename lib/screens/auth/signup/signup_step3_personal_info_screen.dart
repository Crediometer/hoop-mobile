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

  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _bvnController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String? _selectedGender;
  String? _locationLat;
  String? _locationLng;

  final int totalSteps = 4;
  final int currentStep = 3;
  final List<String> genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _dobController.dispose();
    _occupationController.dispose();
    _bvnController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    DateTime initialDate =
        DateTime.now().subtract(const Duration(days: 365 * 18));
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Colors.blueAccent,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Colors.blueAccent,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  void _getCurrentLocation() {
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SignupStep4FacialVerificationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0C0E1A) : Colors.grey[100];
    final cardColor = isDark ? const Color(0xFF1C1F2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SignupProgressBar(currentStep: currentStep, totalSteps: totalSteps),
              const SizedBox(height: 20),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date of Birth',
                        style: TextStyle(color: textColor.withOpacity(0.8))),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _dobController,
                      hintText: 'yyyy-mm-dd',
                      readOnly: true,
                      onTap: _pickDateOfBirth,
                      suffixIcon:
                          Icon(Icons.calendar_today, color: hintColor),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Please select your DOB' : null,
                      cardColor: cardColor,
                      textColor: textColor,
                      hintColor: hintColor!,
                    ),
                    const SizedBox(height: 18),

                    Text('Gender',
                        style: TextStyle(color: textColor.withOpacity(0.8))),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: cardColor,
                      value: _selectedGender,
                      items: genders
                          .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g, style: TextStyle(color: textColor))))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedGender = val),
                      decoration: _inputDecoration(
                          hintText: 'Select gender',
                          cardColor: cardColor,
                          hintColor: hintColor!),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Please select gender' : null,
                    ),
                    const SizedBox(height: 18),

                    Text('Occupation',
                        style: TextStyle(color: textColor.withOpacity(0.8))),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _occupationController,
                      hintText: 'Enter your occupation',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Please enter your occupation' : null,
                      cardColor: cardColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                    const SizedBox(height: 18),

                    Text('BVN', style: TextStyle(color: textColor.withOpacity(0.8))),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _bvnController,
                      hintText: 'Enter 11-digit BVN',
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter BVN';
                        if (v.length != 11) return 'BVN must be 11 digits';
                        if (!RegExp(r'^\d{11}$').hasMatch(v)) {
                          return 'BVN must contain only digits';
                        }
                        return null;
                      },
                      cardColor: cardColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                    const SizedBox(height: 18),

                    Text('Bio', style: TextStyle(color: textColor.withOpacity(0.8))),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _bioController,
                      hintText: 'Tell us about yourself',
                      maxLines: 3,
                      cardColor: cardColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                    const SizedBox(height: 24),

                    // Location Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Permission Required',
                            style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: _locationLat != null
                                    ? Colors.greenAccent
                                    : Colors.grey,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _locationLat != null
                                      ? 'Location captured: $_locationLat, $_locationLng'
                                      : 'Location not captured',
                                  style: TextStyle(
                                      color: hintColor, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          if (_locationLat == null) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: _getCurrentLocation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Get Location',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Continue Button
                    GestureDetector(
                      onTap: _onSubmit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0a1866),
                              Color(0xFF1347cd),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Continue →",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
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

  // 🔹 Adaptive TextField
  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
    bool readOnly = false,
    void Function()? onTap,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLength,
    required Color cardColor,
    required Color textColor,
    required Color hintColor,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(color: textColor),
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: _inputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon,
        cardColor: cardColor,
        hintColor: hintColor,
      ),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? suffixIcon,
    required Color cardColor,
    required Color hintColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: hintColor),
      filled: true,
      fillColor: cardColor,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: hintColor.withOpacity(0.3)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
