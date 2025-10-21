import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hoop/widgets/progress_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hoop/screens/auth/signup/signup_step5_primary_account_screen.dart';

class SignupStep4FacialVerificationScreen extends StatefulWidget {
  const SignupStep4FacialVerificationScreen({super.key});

  @override
  State<SignupStep4FacialVerificationScreen> createState() =>
      _SignupStep4FacialVerificationScreenState();
}

class _SignupStep4FacialVerificationScreenState
    extends State<SignupStep4FacialVerificationScreen> {
  final ImagePicker _picker = ImagePicker();

  // Stores selected image bytes for both web and mobile
  Uint8List? _imageBytes;

  final int totalSteps = 6;
  final int currentStep = 4;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 600,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  void _onSubmit() {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your facial image')),
      );
      return;
    }

    // ✅ Navigate to next screen (Step 5)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SignupStep5PrimaryAccountScreen(),
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
              const SizedBox(height: 40),

              // White Card Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Red line placeholder (camera feed area)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _imageBytes == null
                          ? const Center(
                              child: Text(
                                'Camera Feed Area',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Instruction text
                    const Text(
                      'Click below to start camera',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Start Camera Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _pickImage,
                        child: const Text(
                          'Start Camera',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verification Tips Section
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Verification Tips:',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tips List
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _VerificationTip(
                          boldText: 'Head turning:',
                          normalText: ' Slowly turn left, then right clearly',
                        ),
                        SizedBox(height: 8),
                        _VerificationTip(
                          boldText: 'Mouth open:',
                          normalText: ' Open wide like saying "Ah" at dentist',
                        ),
                        SizedBox(height: 8),
                        _VerificationTip(
                          boldText: 'Smile:',
                          normalText: ' Show a clear, natural smile with teeth',
                        ),
                        SizedBox(height: 8),
                        _VerificationTip(
                          boldText: 'Good lighting:',
                          normalText: ' Face towards light source',
                        ),
                        SizedBox(height: 8),
                        _VerificationTip(
                          boldText: 'Steady movements:',
                          normalText: ' Move slowly and clearly',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Next Button (only show if image is captured)
              if (_imageBytes != null)
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
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationTip extends StatelessWidget {
  final String boldText;
  final String normalText;

  const _VerificationTip({
    required this.boldText,
    required this.normalText,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
        ),
        children: [
          TextSpan(
            text: boldText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: normalText),
        ],
      ),
    );
  }
}
