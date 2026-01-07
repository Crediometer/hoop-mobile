// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:hoop/widgets/progress_bar.dart';
// import 'package:image_picker/image_picker.dart';

// class SignupStep4FacialVerificationScreen extends StatefulWidget {
//   const SignupStep4FacialVerificationScreen({super.key});

//   @override
//   State<SignupStep4FacialVerificationScreen> createState() =>
//       _SignupStep4FacialVerificationScreenState();
// }

// class _SignupStep4FacialVerificationScreenState
//     extends State<SignupStep4FacialVerificationScreen> {
//   final ImagePicker _picker = ImagePicker();
//   Uint8List? _imageBytes;

//   final int totalSteps = 4;
//   final int currentStep = 4;

//   Future<void> _pickImage() async {
//     final XFile? pickedFile = await _picker.pickImage(
//       source: ImageSource.camera,
//       maxWidth: 600,
//       imageQuality: 80,
//     );

//     if (pickedFile != null) {
//       final bytes = await pickedFile.readAsBytes();
//       setState(() {
//         _imageBytes = bytes;
//       });
//     }
//   }

// void _onSubmit() {
//   if (_imageBytes == null) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Please upload your facial image'),
//         backgroundColor: Colors.redAccent,
//       ),
//     );
//     return;
//   }

//   // ✅ Show success toast instead of moving next
//   ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(
//       content: Text('Signup Successfully 🎉'),
//       backgroundColor: Colors.green,
//       duration: Duration(seconds: 2),
//     ),
//   );
// }


//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SignupProgressBar(
//                 currentStep: currentStep,
//                 totalSteps: totalSteps,
//               ),
//               const SizedBox(height: 40),

//               // Card Container
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: theme.cardColor,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     if (!isDark)
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     // Camera area
//                     Stack(
//                       children: [
//                         Container(
//                           height: 200,
//                           width: double.infinity,
//                           decoration: BoxDecoration(
//                             color: isDark
//                                 ? const Color(0xFF1C1F2E)
//                                 : Colors.grey[200],
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: _imageBytes == null
//                               ? Center(
//                                   child: Text(
//                                     'Camera Feed Area',
//                                     style: TextStyle(
//                                       color:
//                                           isDark ? Colors.white70 : Colors.black87,
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 )
//                               : ClipRRect(
//                                   borderRadius: BorderRadius.circular(8),
//                                   child: Image.memory(
//                                     _imageBytes!,
//                                     fit: BoxFit.cover,
//                                   ),
//                                 ),
//                         ),
//                         Positioned(
//                           left: 8,
//                           right: 8,
//                           bottom: 8,
//                           child: Container(
//                             padding: const EdgeInsets.all(10),
//                             decoration: BoxDecoration(
//                               color: Colors.black.withOpacity(0.55),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 _OverlayTip(
//                                     text:
//                                         'Slowly turn left, then right clearly'),
//                                 SizedBox(height: 6),
//                                 _OverlayTip(
//                                     text:
//                                         'Show a clear, natural smile with teeth'),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 20),

//                     Text(
//                       'Click below to start camera',
//                       style: TextStyle(
//                         color: isDark ? Colors.grey[400] : Colors.grey[700],
//                         fontSize: 16,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 20),

//                     // Start Camera Button
//                     SizedBox(
//                       width: double.infinity,
//                       height: 48,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF1347CD),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         onPressed: _pickImage,
//                         child: const Text(
//                           'Start Camera',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     Row(
//                       children: [
//                         const Icon(Icons.lightbulb_outline,
//                             color: Colors.amber, size: 20),
//                         const SizedBox(width: 8),
//                         Text(
//                           'Verification Tips:',
//                           style: TextStyle(
//                             color: isDark ? Colors.white : Colors.black87,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),

//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: const [
//                         _VerificationTip(
//                           boldText: 'Head turning:',
//                           normalText: ' Slowly turn left, then right clearly',
//                         ),
//                         SizedBox(height: 8),
//                         _VerificationTip(
//                           boldText: 'Mouth open:',
//                           normalText: ' Open wide like saying "Ah"',
//                         ),
//                         SizedBox(height: 8),
//                         _VerificationTip(
//                           boldText: 'Smile:',
//                           normalText: ' Show a natural smile with teeth',
//                         ),
//                         SizedBox(height: 8),
//                         _VerificationTip(
//                           boldText: 'Good lighting:',
//                           normalText: ' Face towards a light source',
//                         ),
//                         SizedBox(height: 8),
//                         _VerificationTip(
//                           boldText: 'Steady movements:',
//                           normalText: ' Move slowly and clearly',
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 30),

//               if (_imageBytes != null)
//                 SizedBox(
//                   width: double.infinity,
//                   height: 48,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF1347CD),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 8,
//                       shadowColor: Colors.blueAccent.withOpacity(0.5),
//                     ),
//                     onPressed: _onSubmit,
//                     child: const Text(
//                       'Next',
//                       style: TextStyle(fontSize: 16, color: Colors.white),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _VerificationTip extends StatelessWidget {
//   final String boldText;
//   final String normalText;

//   const _VerificationTip({
//     required this.boldText,
//     required this.normalText,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     return RichText(
//       text: TextSpan(
//         style: TextStyle(
//           color: isDark ? Colors.white70 : Colors.black87,
//           fontSize: 13,
//         ),
//         children: [
//           TextSpan(
//             text: boldText,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//           TextSpan(text: normalText),
//         ],
//       ),
//     );
//   }
// }

// class _OverlayTip extends StatelessWidget {
//   final String text;
//   const _OverlayTip({required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
//         const SizedBox(width: 6),
//         Expanded(
//           child: Text(
//             text,
//             style: const TextStyle(color: Colors.white, fontSize: 12),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hoop/widgets/progress_bar.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// ============================================================
/// IMPROVED SCREEN WITH FIXES
/// ============================================================
class SignupStep4FacialVerificationScreen extends StatefulWidget {
  const SignupStep4FacialVerificationScreen({super.key});

  @override
  State<SignupStep4FacialVerificationScreen> createState() =>
      _SignupStep4FacialVerificationScreenState();
}

class _SignupStep4FacialVerificationScreenState
    extends State<SignupStep4FacialVerificationScreen>
    with WidgetsBindingObserver {
  // Original UI state
  Uint8List? _imageBytes;
  final int totalSteps = 4;
  final int currentStep = 4;
  bool _isVerificationComplete = false;
  bool _isCapturing = false;
  
  // Camera & Liveness detection state
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  DateTime _lastProcessTime = DateTime.now();
  
  // Face tracking state
  final List<FaceData> _faceHistory = [];
  double _livenessScore = 0.0;
  String _detectionStatus = 'Initializing Camera';
  String _detectionDetails = 'Please hold phone upright';
  bool _isLive = false;
  double _brightnessLevel = 0.0;
  bool _hasGoodLighting = false;
  bool _hasGoodOrientation = false;
  int _trackedFaceId = -1;
  
  // Configuration
  static const int historyLength = 25;
  static const int minFramesForAnalysis = 15;
  static const double livenessThreshold = 0.75;
  static const Duration frameCooldown = Duration(milliseconds: 200);
  static const double minBrightness = 0.20;
  static const double maxBrightness = 0.85;
  static const double maxTiltAngle = 20.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameraAndDetection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseDetection();
    } else if (state == AppLifecycleState.resumed && _imageBytes == null) {
      // Only resume if we haven't captured yet
      _resumeDetection();
    }
  }

  Future<void> _initializeCameraAndDetection() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No camera available');
      }
      
      // Use front camera
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      // Initialize camera
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _cameraController!.initialize();
      
      // Start image stream only if we're not in image review mode
      if (_imageBytes == null) {
        await _cameraController!.startImageStream(_processCameraImage);
      }
      
      // Initialize face detector
      final options = FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
      );
      _faceDetector = FaceDetector(options: options);
      
      // Initialize sensors
      _accelerometerSubscription = accelerometerEvents.listen((event) {
        setState(() {
          _hasGoodOrientation = event.x.abs() < maxTiltAngle && 
                               event.y.abs() < maxTiltAngle;
        });
      });
      
      setState(() {
        _isCameraInitialized = true;
        _detectionStatus = 'Ready';
        _detectionDetails = 'Position your face in the oval';
      });
      
    } catch (e) {
      print('Camera initialization error: $e');
      setState(() {
        _detectionStatus = 'Camera Error';
        _detectionDetails = 'Please check camera permissions';
      });
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing || 
        !_isCameraInitialized ||
        _cameraController == null ||
        _imageBytes != null || // Stop processing if we have captured image
        DateTime.now().difference(_lastProcessTime) < frameCooldown) {
      return;
    }

    _isProcessing = true;

    try {
      // Check orientation
      if (!_hasGoodOrientation) {
        _updateDetectionStatus(
          'Adjust Device',
          'Hold phone upright for best results',
          false,
        );
        return;
      }

      // Calculate brightness
      _brightnessLevel = _calculateBrightness(image);
      _hasGoodLighting = _brightnessLevel > minBrightness && 
                         _brightnessLevel < maxBrightness;
      
      // Process face detection
      final inputImage = _convertToInputImage(image);
      if (inputImage == null) return;
      
      final faces = await _faceDetector!.processImage(inputImage);
      await _analyzeFaces(faces, _brightnessLevel);
      
    } catch (e) {
      print('Face detection error: $e');
    } finally {
      _isProcessing = false;
      _lastProcessTime = DateTime.now();
    }
  }

  double _calculateBrightness(CameraImage image) {
    final yPlane = image.planes[0];
    final yBytes = yPlane.bytes;
    
    final sampleSize = 5000;
    final step = math.max(1, yBytes.length ~/ sampleSize);
    
    int sum = 0;
    int count = 0;
    
    for (int i = 0; i < yBytes.length; i += step) {
      sum += yBytes[i];
      count++;
    }
    
    return count > 0 ? (sum / count) / 255.0 : 0.0;
  }

  InputImage? _convertToInputImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _analyzeFaces(List<Face> faces, double brightness) async {
    if (faces.isEmpty) {
      _updateDetectionStatus(
        'No Face Detected',
        'Position your face in the oval',
        false,
      );
      _faceHistory.clear();
      _trackedFaceId = -1;
      return;
    }

    // Select primary face
    Face? primaryFace;
    if (_trackedFaceId != -1) {
      for (final face in faces) {
        if (face.trackingId == _trackedFaceId) {
          primaryFace = face;
          break;
        }
      }
    }
    
    primaryFace ??= faces.first;
    _trackedFaceId = primaryFace.trackingId ?? -1;

    // Create face data
    final faceData = FaceData(
      headEulerAngleX: primaryFace.headEulerAngleX ?? 0,
      headEulerAngleY: primaryFace.headEulerAngleY ?? 0,
      headEulerAngleZ: primaryFace.headEulerAngleZ ?? 0,
      boundingBox: primaryFace.boundingBox,
      leftEyeOpenProbability: primaryFace.leftEyeOpenProbability ?? 0.5,
      rightEyeOpenProbability: primaryFace.rightEyeOpenProbability ?? 0.5,
      timestamp: DateTime.now(),
      brightness: brightness,
    );

    // Update history
    _faceHistory.add(faceData);
    if (_faceHistory.length > historyLength) {
      _faceHistory.removeAt(0);
    }

    // Calculate score
    if (_faceHistory.length >= minFramesForAnalysis) {
      final score = _calculateLivenessScore();
      final isLive = score >= livenessThreshold;
      
      _updateDetectionStatus(
        isLive ? 'Verification Complete' : 'Verifying...',
        isLive ? 'Identity confirmed successfully' : 'Keep looking at the camera',
        isLive,
      );
      
      // If live, capture the image automatically
      if (isLive && _imageBytes == null && !_isCapturing) {
        _isCapturing = true;
        _captureVerificationImage();
      }
    } else {
      final progress = _faceHistory.length / minFramesForAnalysis;
      _updateDetectionStatus(
        'Analyzing',
        '${(_faceHistory.length * 100 / minFramesForAnalysis).toInt()}% complete',
        false,
      );
    }
  }

  double _calculateLivenessScore() {
    if (_faceHistory.isEmpty) return 0.0;
    
    double score = 0.0;
    
    // 1. Lighting (20%)
    if (_hasGoodLighting) score += 0.20;
    
    // 2. Orientation (20%)
    if (_hasGoodOrientation) score += 0.20;
    
    // 3. Detection consistency (25%)
    if (_faceHistory.length >= minFramesForAnalysis) {
      score += 0.25;
    }
    
    // 4. Natural movement (20%)
    if (_faceHistory.length > 5) {
      final movements = _faceHistory.map((f) => 
        (f.headEulerAngleX.abs() + f.headEulerAngleY.abs() + f.headEulerAngleZ.abs())
      ).toList();
      
      final avgMovement = movements.reduce((a, b) => a + b) / movements.length;
      if (avgMovement > 2.0 && avgMovement < 15.0) {
        score += 0.20;
      }
    }
    
    // 5. Eye activity (15%)
    if (_faceHistory.length > 3) {
      final eyeStates = _faceHistory.map((f) => f.averageEyeOpenness).toList();
      final variance = _calculateVariance(eyeStates);
      if (variance > 0.05) {
        score += 0.15;
      }
    }
    
    return score.clamp(0.0, 1.0);
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return variance;
  }

  Future<void> _captureVerificationImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      // Stop the camera stream first
      await _cameraController!.stopImageStream();
      
      // Take picture
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      
      // Dispose camera resources
      _cleanupCamera();
      
      setState(() {
        _imageBytes = bytes;
        _isVerificationComplete = true;
        _isCapturing = false;
        _detectionStatus = 'Image Captured';
        _detectionDetails = 'Review your photo below';
      });
      
    } catch (e) {
      print('Error capturing image: $e');
      setState(() {
        _isCapturing = false;
      });
      
      // Restart camera stream if capture failed
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        await _cameraController!.startImageStream(_processCameraImage);
      }
    }
  }

  Future<void> _retakePhoto() async {
    setState(() {
      _imageBytes = null;
      _isVerificationComplete = false;
      _isCapturing = false;
      _faceHistory.clear();
      _livenessScore = 0.0;
      _detectionStatus = 'Initializing Camera';
      _detectionDetails = 'Please hold phone upright';
    });
    
    // Reinitialize camera
    await _initializeCameraAndDetection();
  }

  void _updateDetectionStatus(String status, String details, bool isLive) {
    if (mounted) {
      setState(() {
        _detectionStatus = status;
        _detectionDetails = details;
        _isLive = isLive;
        _livenessScore = _calculateLivenessScore();
        
        // If verification is complete and we have a good score, mark as verified
        if (isLive && _livenessScore >= livenessThreshold && !_isCapturing) {
          _isVerificationComplete = true;
        }
      });
    }
  }

  void _pauseDetection() {
    _accelerometerSubscription?.pause();
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
  }

  void _resumeDetection() {
    if (_isCameraInitialized && _cameraController != null) {
      _cameraController!.startImageStream(_processCameraImage);
      _accelerometerSubscription?.resume();
    }
  }

  void _cleanup() {
    _accelerometerSubscription?.cancel();
    _cleanupCamera();
    _faceDetector?.close();
  }

  void _cleanupCamera() {
    if (_cameraController != null) {
      if (_cameraController!.value.isStreamingImages) {
        _cameraController!.stopImageStream();
      }
      _cameraController!.dispose();
      _cameraController = null;
    }
  }

  void _onSubmit() {
    if (_imageBytes == null || !_isVerificationComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete facial verification first'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Show success toast
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signup Successfully 🎉'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Here you would typically navigate to next screen
    // Navigator.push(context, MaterialPageRoute(builder: (_) => NextScreen()));
  }

  Widget _buildCameraPreview() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_imageBytes != null) {
      // Show captured image with retake option
      return Container(
        height: 300, // Taller for landscape feel
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Stack(
          children: [
            // Captured image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                _imageBytes!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            
            // Overlay with success message
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),
            
            // Success indicator
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Retake button
            Positioned(
              bottom: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: _retakePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('Retake'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1F2E) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initializing camera...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300, // Taller for landscape feel
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isLive ? Colors.green : Colors.blue,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Camera preview
            SizedBox(
              height: double.infinity,
              width: double.infinity,
              child: CameraPreview(_cameraController!),
            ),
            
            // Overlay with shimmer effect when live
            if (_isLive)
              Positioned.fill(
                child: HolographicShimmer(
                  isActive: true,
                  speed: 0.7,
                ),
              ),
            
            // Face detection overlay
            Positioned.fill(
              child: CustomPaint(
                painter: FaceDetectionOverlayPainter(
                  faceHistory: _faceHistory,
                  isLive: _isLive,
                  hasGoodOrientation: _hasGoodOrientation,
                ),
              ),
            ),
            
            // Status overlay
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isLive ? Colors.green : Colors.blue,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isLive ? Colors.green : Colors.amber,
                            boxShadow: [
                              BoxShadow(
                                color: _isLive ? Colors.green : Colors.amber,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _detectionStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(_livenessScore * 100).toInt()}%',
                          style: TextStyle(
                            color: _livenessScore > 0.7
                                ? Colors.green
                                : _livenessScore > 0.4
                                    ? Colors.amber
                                    : Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _detectionDetails,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    
                    // Progress bar
                    if (_faceHistory.isNotEmpty)
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _faceHistory.length / minFramesForAnalysis,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isLive ? Colors.green : Colors.blue,
                            ),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Analyzing frames...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '${_faceHistory.length}/$minFramesForAnalysis',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            // Manual capture button
            if (!_isCapturing && !_isLive)
              Positioned(
                top: 16,
                right: 16,
                child: ElevatedButton(
                  onPressed: _captureVerificationImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.camera_alt, size: 16),
                      SizedBox(width: 6),
                      Text('Capture'),
                    ],
                  ),
                ),
              ),
            
            // Capturing indicator
            if (_isCapturing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Capturing...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar at top
              SignupProgressBar(
                currentStep: currentStep,
                totalSteps: totalSteps,
              ),
              const SizedBox(height: 32),

              // Title
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Facial Verification',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),

              // Main Card Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                    // Camera/Image area (now wider/taller)
                    _buildCameraPreview(),
                    const SizedBox(height: 24),

                    // Verification tips
                    _buildVerificationTips(isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationTips(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_outline,
                color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text(
              'Verification Tips:',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tips grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildTipCard(
              icon: Icons.rotate_right,
              title: 'Head Turning',
              description: 'Slowly turn left, then right clearly',
              isActive: _faceHistory.length > 5,
            ),
            _buildTipCard(
              icon: Icons.face_retouching_natural,
              title: 'Natural Smile',
              description: 'Show a natural smile with teeth',
              isActive: _faceHistory.isNotEmpty,
            ),
            _buildTipCard(
              icon: Icons.light_mode,
              title: 'Good Lighting',
              description: 'Face towards light source',
              isActive: _hasGoodLighting,
            ),
            _buildTipCard(
              icon: Icons.straighten,
              title: 'Hold Upright',
              description: 'Keep phone steady and upright',
              isActive: _hasGoodOrientation,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isActive,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.blue.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.blue : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_isVerificationComplete)
          SizedBox(
            width: double.infinity,
            height: 52,
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
                'Complete Signup',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        
        if (!_isVerificationComplete && _imageBytes == null)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: Colors.grey),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please complete facial verification first'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: Text(
                'Skip for Now',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey[700],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class HolographicShimmer extends StatefulWidget {
  final bool isActive;
  final double speed;
  final List<Color> colors;

  const HolographicShimmer({
    Key? key,
    this.isActive = true,
    this.speed = 1.0,
    this.colors = const [
      Color(0xFF0066FF),
      Color(0xFF00D4FF),
      Color(0xFFFFFFFF),
      Color(0xFF00D4FF),
      Color(0xFF0066FF),
    ],
  }) : super(key: key);

  @override
  _HolographicShimmerState createState() => _HolographicShimmerState();
}

class _HolographicShimmerState extends State<HolographicShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _gradientAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(milliseconds: (3000 / widget.speed).round()),
      vsync: this,
    )..repeat();
    
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(HolographicShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _HolographicPainter(
            gradientProgress: _gradientAnimation.value,
            waveProgress: _waveAnimation.value,
            colors: widget.colors,
            isActive: widget.isActive,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _HolographicPainter extends CustomPainter {
  final double gradientProgress;
  final double waveProgress;
  final List<Color> colors;
  final bool isActive;

  _HolographicPainter({
    required this.gradientProgress,
    required this.waveProgress,
    required this.colors,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxDimension = math.max(size.width, size.height);
    
    final gradient = ui.Gradient.sweep(
      center,
      colors,
      List.generate(colors.length, (i) => i / (colors.length - 1)),
      TileMode.mirror,
      math.pi * 2 * gradientProgress,
      math.pi * 2,
    );

    // Draw animated rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (gradientProgress + i * 0.2) % 1.0;
      final radius = maxDimension * 0.3 * (0.5 + ringProgress * 0.5);
      final ringPaint = Paint()
        ..shader = gradient
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          5.0 + ringProgress * 10.0,
        );

      canvas.drawCircle(center, radius, ringPaint);
    }

    // Draw holographic particles
    final particlePaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final angle = waveProgress + i * 0.1;
      final distance = maxDimension * 0.4 * (0.5 + math.sin(angle) * 0.5);
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;
      final particleSize = 1.0 + math.sin(waveProgress + i) * 2.0;
      
      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(_HolographicPainter oldDelegate) {
    return oldDelegate.gradientProgress != gradientProgress ||
        oldDelegate.waveProgress != waveProgress ||
        oldDelegate.colors != colors ||
        oldDelegate.isActive != isActive;
  }
}

/// ============================================================
/// FACE DETECTION OVERLAY PAINTER
/// ============================================================
class FaceDetectionOverlayPainter extends CustomPainter {
  final List<FaceData> faceHistory;
  final bool isLive;
  final bool hasGoodOrientation;

  FaceDetectionOverlayPainter({
    required this.faceHistory,
    required this.isLive,
    required this.hasGoodOrientation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw oval boundary
    final center = Offset(size.width / 2, size.height / 2);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.8,
      height: size.height * 0.6,
    );

    final borderPaint = Paint()
      ..color = isLive ? Colors.green : Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(ovalRect, borderPaint);

    // Draw crosshair
    final crosshairPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx - 15, center.dy),
      Offset(center.dx - 5, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 5, center.dy),
      Offset(center.dx + 15, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 15),
      Offset(center.dx, center.dy - 5),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + 5),
      Offset(center.dx, center.dy + 15),
      crosshairPaint,
    );

    // Draw face position indicator if available
    if (faceHistory.isNotEmpty) {
      final recentFace = faceHistory.last;
      final faceCenter = center; // Simplified for demo
      
      // Draw face outline
      final facePaint = Paint()
        ..color = isLive ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawOval(
        Rect.fromCircle(
          center: faceCenter,
          radius: 30,
        ),
        facePaint,
      );
    }
  }

  @override
  bool shouldRepaint(FaceDetectionOverlayPainter oldDelegate) {
    return oldDelegate.faceHistory.length != faceHistory.length ||
        oldDelegate.isLive != isLive ||
        oldDelegate.hasGoodOrientation != hasGoodOrientation;
  }
}

/// ============================================================
/// DATA MODELS & HELPER CLASSES
/// ============================================================
class FaceData {
  final double headEulerAngleX;
  final double headEulerAngleY;
  final double headEulerAngleZ;
  final Rect boundingBox;
  final double leftEyeOpenProbability;
  final double rightEyeOpenProbability;
  final DateTime timestamp;
  final double brightness;

  FaceData({
    required this.headEulerAngleX,
    required this.headEulerAngleY,
    required this.headEulerAngleZ,
    required this.boundingBox,
    required this.leftEyeOpenProbability,
    required this.rightEyeOpenProbability,
    required this.timestamp,
    required this.brightness,
  });

  double get averageEyeOpenness => 
      (leftEyeOpenProbability + rightEyeOpenProbability) / 2.0;
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