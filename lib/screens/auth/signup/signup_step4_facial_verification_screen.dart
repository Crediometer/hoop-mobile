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
              const SizedBox(height: 20),

              // Face icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1F2E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.face_retouching_natural_outlined,
                    size: 40,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Center(
                child: Text(
                  'Facial Verification',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Help us verify your identity with a quick selfie',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1F2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: _imageBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt_outlined,
                                color: Colors.grey, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'Tap to capture or select your face',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),

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
