// lib/services/onboarding_service.dart
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  final StreamController<bool> _onboardingController = StreamController<bool>.broadcast();
  late SharedPreferences _prefs;
  bool? _cachedValue;
  
  factory OnboardingService() => _instance;
  
  OnboardingService._internal() {
    _init();
  }
  
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _cachedValue = _prefs.getString('needsAccountOnboarding') != 'false';
    _onboardingController.add(_cachedValue!);
  }
  
  Stream<bool> get needsOnboardingStream => _onboardingController.stream;
  
  bool get cachedNeedsOnboarding => _cachedValue ?? true;
  
  Future<void> setOnboardingComplete() async {
    await _prefs.setString('needsAccountOnboarding', 'false');
    _cachedValue = false;
    _onboardingController.add(false);
  }
  
  Future<void> setOnboardingRequired() async {
    await _prefs.setString('needsAccountOnboarding', 'true');
    _cachedValue = true;
    _onboardingController.add(true);
  }
  
  Future<bool> getCurrentStatus() async {
    _prefs = await SharedPreferences.getInstance();
    _cachedValue = _prefs.getString('needsAccountOnboarding') != 'false';
    return _cachedValue!;
  }
  
  // Static helper methods for direct access
  static Stream<bool> get onOnboardingStatusChanged => _instance.needsOnboardingStream;
  
  static Future<void> markOnboardingComplete() async {
    await _instance.setOnboardingComplete();
  }
  
  static Future<void> markOnboardingRequired() async {
    await _instance.setOnboardingRequired();
  }
  
  static Future<bool> checkIfOnboardingNeeded() async {
    return await _instance.getCurrentStatus();
  }
  
  static Future<void> resetOnboarding() async {
    await _instance._prefs.remove('needsAccountOnboarding');
    _instance._cachedValue = true;
    _instance._onboardingController.add(true);
  }
  
  void dispose() {
    _onboardingController.close();
  }
}