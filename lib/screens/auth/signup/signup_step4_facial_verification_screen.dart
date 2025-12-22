import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hoop/widgets/progress_bar.dart';
import 'package:image_picker/image_picker.dart';

class SignupStep4FacialVerificationScreen extends StatefulWidget {
  const SignupStep4FacialVerificationScreen({super.key});

  @override
  State<SignupStep4FacialVerificationScreen> createState() =>
      _SignupStep4FacialVerificationScreenState();
}

class _SignupStep4FacialVerificationScreenState
    extends State<SignupStep4FacialVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;

  final int totalSteps = 4;
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
      const SnackBar(
        content: Text('Please upload your facial image'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  // ✅ Show success toast instead of moving next
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Signup Successfully 🎉'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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

              // Card Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    // Camera area
                    Stack(
                      children: [
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C1F2E)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _imageBytes == null
                              ? Center(
                                  child: Text(
                                    'Camera Feed Area',
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white70 : Colors.black87,
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
                                  ),
                                ),
                        ),
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _OverlayTip(
                                    text:
                                        'Slowly turn left, then right clearly'),
                                SizedBox(height: 6),
                                _OverlayTip(
                                    text:
                                        'Show a clear, natural smile with teeth'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Click below to start camera',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
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
                          backgroundColor: const Color(0xFF1347CD),
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

                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Verification Tips:',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

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
                          normalText: ' Open wide like saying "Ah"',
                        ),
                        SizedBox(height: 8),
                        _VerificationTip(
                          boldText: 'Smile:',
                          normalText: ' Show a natural smile with teeth',
                        ),
                        SizedBox(height: 8),
                        _VerificationTip(
                          boldText: 'Good lighting:',
                          normalText: ' Face towards a light source',
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

              if (_imageBytes != null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1347CD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      shadowColor: Colors.blueAccent.withOpacity(0.5),
                    ),
                    onPressed: _onSubmit,
                    child: const Text(
                      'Next',
                      style: TextStyle(fontSize: 16, color: Colors.white),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
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

class _OverlayTip extends StatelessWidget {
  final String text;
  const _OverlayTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
