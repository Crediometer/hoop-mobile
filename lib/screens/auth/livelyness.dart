
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hoop/screens/auth/signup/signup_step4_facial_verification_screen.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// ============================================================
/// CONSTANTS & CONFIGURATION
/// ============================================================
class LivenessConfig {
  // Core thresholds
  static const int historyLength = 25;
  static const int minFramesForAnalysis = 15;
  static const double livenessThreshold = 0.75;
  static const Duration frameCooldown = Duration(milliseconds: 200);
  
  // Lighting thresholds
  static const double minBrightness = 0.20;
  static const double maxBrightness = 0.85;
  static const double optimalMinBrightness = 0.30;
  static const double optimalMaxBrightness = 0.70;
  
  // Orientation thresholds (in degrees)
  static const double maxTiltAngle = 20.0;
  static const double minFaceSizePercentage = 0.15;
  
  // Score weights
  static const double lightingWeight = 0.20;
  static const double orientationWeight = 0.20;
  static const double detectionWeight = 0.25;
  static const double movementWeight = 0.20;
  static const double eyeWeight = 0.15;
  
  // Timeouts
  static const Duration verificationTimeout = Duration(seconds: 25);
  
  // Visual constants
  static const Color primaryColor = Color(0xFF0066FF);
  static const Color accentColor = Color(0xFF00D4FF);
  static const Color successColor = Color(0xFF00C853);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFF0A0A0F);
}

/// ============================================================
/// 3D SHIMMER EFFECT
/// ============================================================
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
    
    // Create holographic gradient
    final gradient = ui.Gradient.sweep(
      center,
      colors,
      List.generate(colors.length, (i) => i / (colors.length - 1)),
      TileMode.mirror,
      math.pi * 2 * gradientProgress,
      math.pi * 2,
    );

    // Create wave effect
    final wavePath = Path();
    for (double i = 0; i < size.width; i += 2) {
      final waveHeight = math.sin(waveProgress + i * 0.02) * 15;
      if (i == 0) {
        wavePath.moveTo(i, size.height / 2 + waveHeight);
      } else {
        wavePath.lineTo(i, size.height / 2 + waveHeight);
      }
    }

    // Main holographic paint
    final holographicPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

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

    // Draw wave
    final wavePaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    canvas.drawPath(wavePath, wavePaint);

    // Draw holographic particles
    final particlePaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
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
/// INSTRUCTION PANEL
/// ============================================================
class InstructionPanel extends StatefulWidget {
  final String status;
  final String details;
  final bool isVertical;
  final bool hasGoodLighting;
  final double progress;

  const InstructionPanel({
    Key? key,
    required this.status,
    required this.details,
    required this.isVertical,
    required this.hasGoodLighting,
    required this.progress,
  }) : super(key: key);

  @override
  _InstructionPanelState createState() => _InstructionPanelState();
}

class _InstructionPanelState extends State<InstructionPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(InstructionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Row
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor().withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.status,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Details
            Text(
              widget.details,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Progress Bar
            LinearProgressIndicator(
              value: widget.progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
              minHeight: 2,
            ),
            
            const SizedBox(height: 16),
            
            // Tips Grid
            _buildTipsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsGrid() {
    return Row(
      children: [
        // Orientation Tip
        _buildTipItem(
          icon: Icons.stay_current_portrait,
          text: 'Hold Phone Upright',
          isActive: widget.isVertical,
        ),
        
        const SizedBox(width: 12),
        
        // Lighting Tip
        _buildTipItem(
          icon: Icons.lightbulb,
          text: 'Good Lighting',
          isActive: widget.hasGoodLighting,
        ),
        
        const SizedBox(width: 12),
        
        // Face Tip
        _buildTipItem(
          icon: Icons.face,
          text: 'Center Face',
          isActive: widget.progress > 0.3,
        ),
      ],
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String text,
    required bool isActive,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isActive
              ? _getStatusColor().withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? _getStatusColor().withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? _getStatusColor() : Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (widget.progress > 0.7) return LivenessConfig.successColor;
    if (widget.progress > 0.3) return LivenessConfig.primaryColor;
    return LivenessConfig.warningColor;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// ============================================================
/// MAIN APPLICATION
/// ============================================================
/// 

class LivenessDetectionApp extends StatelessWidget {
  const LivenessDetectionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Identity Verification',
      theme: ThemeData(
        primaryColor: LivenessConfig.primaryColor,
        scaffoldBackgroundColor: LivenessConfig.backgroundColor,
        colorScheme: const ColorScheme.dark(
          primary: LivenessConfig.primaryColor,
          secondary: LivenessConfig.accentColor,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: FutureBuilder<List<CameraDescription>>(
        future: availableCameras(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final frontCamera = snapshot.data!.firstWhere(
                (cam) => cam.lensDirection == CameraLensDirection.front,
                orElse: () => snapshot.data!.first,
              );
              return LivenessDetectionScreen(camera: frontCamera);
            }
            return const CameraErrorScreen();
          }
          return const SplashScreen();
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LivenessConfig.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated holographic logo
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        LivenessConfig.primaryColor.withOpacity(0.3),
                        LivenessConfig.backgroundColor,
                      ],
                    ),
                  ),
                ),
                HolographicShimmer(
                  isActive: true,
                  speed: 0.8,
                ),
                const Icon(
                  Icons.verified_user,
                  size: 60,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Identity Verification',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Secure biometric authentication',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraErrorScreen extends StatelessWidget {
  const CameraErrorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LivenessConfig.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam_off,
                size: 80,
                color: Colors.white54,
              ),
              const SizedBox(height: 24),
              const Text(
                'Camera Unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please enable camera access to continue with verification.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: LivenessConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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

/// ============================================================
/// DATA MODELS
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

class DeviceOrientationData {
  final double x;
  final double y;
  final double z;

  DeviceOrientationData({
    required this.x,
    required this.y,
    required this.z,
  });

  bool get isVertical => x.abs() < LivenessConfig.maxTiltAngle && 
                        y.abs() < LivenessConfig.maxTiltAngle;
}

/// ============================================================
/// MAIN DETECTION SCREEN
/// ============================================================
class LivenessDetectionScreen extends StatefulWidget {
  final CameraDescription camera;
  
  const LivenessDetectionScreen({Key? key, required this.camera}) : super(key: key);

  @override
  State<LivenessDetectionScreen> createState() => _LivenessDetectionScreenState();
}

class _LivenessDetectionScreenState extends State<LivenessDetectionScreen> 
    with WidgetsBindingObserver {
  // Camera & Detection
  late CameraController _cameraController;
  late FaceDetector _faceDetector;
  
  // Orientation sensors
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DeviceOrientationData? _currentOrientation;
  
  // State management
  bool _isInitialized = false;
  bool _isProcessing = false;
  DateTime _lastProcessTime = DateTime.now();
  
  // Liveness data
  final List<FaceData> _faceHistory = [];
  double _livenessScore = 0.0;
  String _status = 'Initializing';
  String _details = 'Loading camera...';
  bool _isLive = false;
  double _brightnessLevel = 0.0;
  bool _hasGoodLighting = false;
  bool _hasGoodOrientation = false;
  
  // Session management
  int _trackedFaceId = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSystems();
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
    } else if (state == AppLifecycleState.resumed) {
      _resumeDetection();
    }
  }

  Future<void> _initializeSystems() async {
    try {
      await _initializeCamera();
      _initializeFaceDetector();
      _initializeSensors();
      
      setState(() {
        _isInitialized = true;
        _status = 'Ready';
        _details = 'Position your face in the oval';
      });
    } catch (e) {
      _handleInitializationError(e);
    }
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController.initialize();
    await _cameraController.startImageStream(_processCameraImage);
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.15,
    );
    _faceDetector = FaceDetector(options: options);
  }

  void _initializeSensors() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      setState(() {
        _currentOrientation = DeviceOrientationData(
          x: event.x,
          y: event.y,
          z: event.z,
        );
        _hasGoodOrientation = _currentOrientation!.isVertical;
      });
    });
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing || 
        !_isInitialized ||
        DateTime.now().difference(_lastProcessTime) < LivenessConfig.frameCooldown) {
      return;
    }

    _isProcessing = true;

    try {
      // Check orientation
      if (_currentOrientation != null && !_currentOrientation!.isVertical) {
        _updateStatus(
          'Adjust Device',
          'Hold phone upright for best results',
          false,
        );
        return;
      }

      // Process frame
      _brightnessLevel = _calculateBrightness(image);
      _hasGoodLighting = _brightnessLevel > LivenessConfig.minBrightness && 
                         _brightnessLevel < LivenessConfig.maxBrightness;
      
      final inputImage = _convertToInputImage(image);
      if (inputImage == null) return;
      
      final faces = await _faceDetector.processImage(inputImage);
      await _analyzeFaces(faces, _brightnessLevel);
      
    } catch (e) {
      if (kDebugMode) print('Processing error: $e');
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
      _updateStatus(
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
    if (_faceHistory.length > LivenessConfig.historyLength) {
      _faceHistory.removeAt(0);
    }

    // Calculate score
    if (_faceHistory.length >= LivenessConfig.minFramesForAnalysis) {
      final score = _calculateSimpleScore();
      final isLive = score >= LivenessConfig.livenessThreshold;
      
      setState(() {
        _livenessScore = score;
        _isLive = isLive;
        _status = isLive ? 'Verification Complete' : 'Verifying...';
        _details = isLive 
            ? 'Identity confirmed successfully'
            : 'Keep looking at the camera';
      });
    } else {
      final progress = _faceHistory.length / LivenessConfig.minFramesForAnalysis;
      _updateStatus(
        'Analyzing',
        '${(_faceHistory.length * 100 / LivenessConfig.minFramesForAnalysis).toInt()}% complete',
        false,
      );
    }
  }

  double _calculateSimpleScore() {
    if (_faceHistory.isEmpty) return 0.0;
    
    double score = 0.0;
    
    // 1. Lighting (20%)
    if (_hasGoodLighting) score += LivenessConfig.lightingWeight;
    
    // 2. Orientation (20%)
    if (_hasGoodOrientation) score += LivenessConfig.orientationWeight;
    
    // 3. Detection consistency (25%)
    if (_faceHistory.length >= LivenessConfig.minFramesForAnalysis) {
      score += LivenessConfig.detectionWeight;
    }
    
    // 4. Natural movement (20%)
    if (_faceHistory.length > 5) {
      final movements = _faceHistory.map((f) => 
        (f.headEulerAngleX.abs() + f.headEulerAngleY.abs() + f.headEulerAngleZ.abs())
      ).toList();
      
      final avgMovement = movements.reduce((a, b) => a + b) / movements.length;
      if (avgMovement > 2.0 && avgMovement < 15.0) {
        score += LivenessConfig.movementWeight;
      }
    }
    
    // 5. Eye activity (15%)
    if (_faceHistory.length > 3) {
      final eyeStates = _faceHistory.map((f) => f.averageEyeOpenness).toList();
      final variance = _calculateVariance(eyeStates);
      if (variance > 0.05) {
        score += LivenessConfig.eyeWeight;
      }
    }
    
    return score;
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return variance;
  }

  void _updateStatus(String status, String details, bool isLive) {
    if (mounted) {
      setState(() {
        _status = status;
        _details = details;
        _isLive = isLive;
      });
    }
  }

  void _handleInitializationError(dynamic error) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Initialization Failed'),
          content: Text('Error: $error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _pauseDetection() {
    _accelerometerSubscription?.pause();
    if (_cameraController.value.isStreamingImages) {
      _cameraController.stopImageStream();
    }
  }

  void _resumeDetection() {
    if (_isInitialized) {
      _cameraController.startImageStream(_processCameraImage);
      _accelerometerSubscription?.resume();
    }
  }

  void _cleanup() {
    _accelerometerSubscription?.cancel();
    _cameraController.dispose();
    _faceDetector.close();
  }

  void _onContinuePressed() {
    // Show verification result
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildResultSheet(),
    );
  }

  Widget _buildResultSheet() {
    return Container(
      decoration: BoxDecoration(
        color: LivenessConfig.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Result Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isLive
                    ? [LivenessConfig.successColor, Colors.greenAccent]
                    : [LivenessConfig.warningColor, Colors.orangeAccent],
              ),
              boxShadow: [
                BoxShadow(
                  color: _isLive
                      ? LivenessConfig.successColor.withOpacity(0.3)
                      : LivenessConfig.warningColor.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              _isLive ? Icons.check_circle : Icons.info,
              size: 40,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Result Text
          Text(
            _isLive ? 'Verification Successful' : 'Continue Verification',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _isLive
                  ? 'Your identity has been verified with confidence.'
                  : 'Position your face better and continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Confidence Score
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Text(
                  'CONFIDENCE LEVEL',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${(_livenessScore * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _getConfidenceColor(),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _livenessScore,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(_getConfidenceColor()),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Continue Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (_isLive) {
                  // Navigate to next screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Proceeding to next step...'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLive 
                    ? LivenessConfig.successColor 
                    : LivenessConfig.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: Text(
                _isLive ? 'CONTINUE' : 'TRY AGAIN',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Color _getConfidenceColor() {
    if (_livenessScore > 0.7) return LivenessConfig.successColor;
    if (_livenessScore > 0.4) return LivenessConfig.primaryColor;
    return LivenessConfig.warningColor;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: LivenessConfig.primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                'Initializing Camera...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: CameraPreview(_cameraController),
          ),
          
          // Clean Overlay (just oval, no banner)
          Positioned.fill(
            child: CustomPaint(
              painter: _CleanOverlayPainter(
                faceHistory: _faceHistory,
                isLive: _isLive,
                hasGoodOrientation: _hasGoodOrientation,
              ),
            ),
          ),
          
          // 3D Shimmer Effect (when live)
          if (_isLive)
            Positioned.fill(
              child: HolographicShimmer(
                isActive: true,
                speed: 0.7,
              ),
            ),
          
          // Instruction Panel (top)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: InstructionPanel(
              status: _status,
              details: _details,
              isVertical: _hasGoodOrientation,
              hasGoodLighting: _hasGoodLighting,
              progress: _faceHistory.length / LivenessConfig.minFramesForAnalysis,
            ),
          ),
          
          // Continue Button (bottom)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildContinueButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    final progress = _faceHistory.length / LivenessConfig.minFramesForAnalysis;
    final isReady = progress >= 1.0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      transform: Matrix4.diagonal3Values(
        isReady ? 1.02 : 1.0,
        isReady ? 1.02 : 1.0,
        1.0,
      ),
      child: ElevatedButton(
        onPressed: isReady ? _onContinuePressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isReady
              ? (_isLive ? LivenessConfig.successColor : LivenessConfig.primaryColor)
              : Colors.grey.shade800,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isReady ? 8 : 2,
          shadowColor: isReady
              ? (_isLive 
                  ? LivenessConfig.successColor.withOpacity(0.5)
                  : LivenessConfig.primaryColor.withOpacity(0.5))
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isReady && _isLive)
              const Icon(Icons.check_circle, color: Colors.white, size: 22),
            if (isReady && !_isLive)
              const Icon(Icons.arrow_forward, color: Colors.white, size: 22),
            if (!isReady)
              const Icon(Icons.access_time, color: Colors.white54, size: 22),
            
            const SizedBox(width: 12),
            
            Text(
              isReady
                  ? (_isLive ? 'CONTINUE' : 'REVIEW RESULT')
                  : '${(progress * 100).toInt()}% COMPLETE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isReady ? Colors.white : Colors.white54,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _CleanOverlayPainter extends CustomPainter {
  final List<FaceData> faceHistory;
  final bool isLive;
  final bool hasGoodOrientation;

  _CleanOverlayPainter({
    required this.faceHistory,
    required this.isLive,
    required this.hasGoodOrientation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle dark overlay
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // Clear oval area for face
    final center = Offset(size.width / 2, size.height / 2);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.75,
      height: size.height * 0.45,
    );

    final clearPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    final clearPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;

    canvas.drawPath(clearPath, clearPaint);

    // Draw oval border with subtle gradient
    final borderGradient = ui.Gradient.sweep(
      center,
      [
        (isLive ? LivenessConfig.successColor : LivenessConfig.primaryColor)
            .withOpacity(0.3),
        isLive ? LivenessConfig.successColor : LivenessConfig.primaryColor,
        (isLive ? LivenessConfig.successColor : LivenessConfig.primaryColor)
            .withOpacity(0.3),
      ],
      [0.0, 0.5, 1.0],
    );

    final borderPaint = Paint()
      ..shader = borderGradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(ovalRect, borderPaint);

    // Draw subtle crosshair for centering
    final crosshairPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Horizontal line
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
    
    // Vertical line
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
      final faceCenter = Offset(
        recentFace.headEulerAngleX * size.width,
        recentFace.headEulerAngleY * size.height,
      );

      final distance = (faceCenter - center).distance;
      final maxDistance = math.min(ovalRect.width, ovalRect.height) / 2;
      
      if (distance > maxDistance * 0.7) {
        // Draw arrow towards center
        final direction = (center - faceCenter).normalized;
        final arrowStart = faceCenter + direction * 20;
        final arrowEnd = faceCenter + direction * 40;
        
        final arrowPaint = Paint()
          ..color = LivenessConfig.warningColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(arrowStart, arrowEnd, arrowPaint);
        
        // Draw arrow head
        final arrowHeadPath = Path();
        final arrowHeadSize = 8.0;
        final perpendicular = Offset(-direction.dy, direction.dx);
        
        arrowHeadPath.moveTo(arrowEnd.dx, arrowEnd.dy);
        arrowHeadPath.lineTo(
          arrowEnd.dx - direction.dx * arrowHeadSize + perpendicular.dx * arrowHeadSize / 2,
          arrowEnd.dy - direction.dy * arrowHeadSize + perpendicular.dy * arrowHeadSize / 2,
        );
        arrowHeadPath.lineTo(
          arrowEnd.dx - direction.dx * arrowHeadSize - perpendicular.dx * arrowHeadSize / 2,
          arrowEnd.dy - direction.dy * arrowHeadSize - perpendicular.dy * arrowHeadSize / 2,
        );
        arrowHeadPath.close();
        
        final arrowHeadPaint = Paint()
          ..color = LivenessConfig.warningColor
          ..style = PaintingStyle.fill;
        
        canvas.drawPath(arrowHeadPath, arrowHeadPaint);
      }
    }

    // Draw orientation indicator (subtle)
    if (!hasGoodOrientation) {
      final indicatorPaint = Paint()
        ..color = LivenessConfig.warningColor.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width - 30, 30),
        10,
        indicatorPaint,
      );

      final iconPaint = Paint()
        ..color = LivenessConfig.warningColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      // Draw tilted rectangle icon
      canvas.save();
      canvas.translate(size.width - 30, 30);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 8, height: 12), iconPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CleanOverlayPainter oldDelegate) {
    return oldDelegate.faceHistory.length != faceHistory.length ||
        oldDelegate.isLive != isLive ||
        oldDelegate.hasGoodOrientation != hasGoodOrientation;
  }
}

/// ============================================================
/// HELPER EXTENSIONS
/// ============================================================
extension OffsetExtensions on Offset {
  Offset get normalized => distance > 0 ? this / distance : this;
}