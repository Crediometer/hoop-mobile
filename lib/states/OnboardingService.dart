import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  final StreamController<bool> _onboardingController = StreamController<bool>.broadcast();
  late Box _box;
  bool? _cachedValue;
  
  static const String _onboardingBox = 'onboarding_box';
  static const String _needsAccountOnboardingKey = 'needsAccountOnboarding';
  static const String _needsUserOnboardingKey = 'needsUserOnboarding';
  
  factory OnboardingService() => _instance;
  
  OnboardingService._internal() {
    _init();
  }
  
  Future<void> _init() async {
    // Open or get the Hive box
    if (!Hive.isBoxOpen(_onboardingBox)) {
      _box = await Hive.openBox(_onboardingBox);
    } else {
      _box = Hive.box(_onboardingBox);
    }
    
    // Initialize cached values from Hive
    _cachedValue = (_box.get(_needsAccountOnboardingKey, defaultValue: true) as bool);
    _onboardingController.add(_cachedValue!);
  }
  
  Future<Box> _ensureBox() async {
    if (!Hive.isBoxOpen(_onboardingBox)) {
      _box = await Hive.openBox(_onboardingBox);
    }
    return _box;
  }
  
  // Stream for HomeScreen
  Stream<bool> get needsOnboardingStream => _onboardingController.stream;
  
  // Cached value getter
  bool get cachedNeedsOnboarding => _cachedValue ?? true;
  
  // Account onboarding methods
  Future<void> setOnboardingComplete() async {
    final box = await _ensureBox();
    await box.put(_needsAccountOnboardingKey, false);
    _cachedValue = false;
    _onboardingController.add(false);
  }
  
  Future<void> setOnboardingRequired() async {
    final box = await _ensureBox();
    await box.put(_needsAccountOnboardingKey, true);
    _cachedValue = true;
    _onboardingController.add(true);
  }
  
  Future<bool> getCurrentStatus() async {
    final box = await _ensureBox();
    _cachedValue = box.get(_needsAccountOnboardingKey, defaultValue: true) as bool;
    return _cachedValue!;
  }
  
  // User onboarding methods
  Future<void> setUserOnboardingComplete() async {
    final box = await _ensureBox();
    await box.put(_needsUserOnboardingKey, false);
  }
  
  Future<void> setUserOnboardingRequired() async {
    final box = await _ensureBox();
    await box.put(_needsUserOnboardingKey, true);
  }
  
  Future<bool> getUserOnboardingStatus() async {
    final box = await _ensureBox();
    return box.get(_needsUserOnboardingKey, defaultValue: true) as bool;
  }
  
  // Static helper methods for AuthProvider
  static bool get needsAccountOnboarding {
    if (!Hive.isBoxOpen(_onboardingBox)) {
      return true; // Default if box not open
    }
    final box = Hive.box(_onboardingBox);
    return box.get(_needsAccountOnboardingKey, defaultValue: true) as bool;
  }
  
  static bool get needsUserOnboarding {
    if (!Hive.isBoxOpen(_onboardingBox)) {
      return true; // Default if box not open
    }
    final box = Hive.box(_onboardingBox);
    return box.get(_needsUserOnboardingKey, defaultValue: true) as bool;
  }
  
  static Future<void> requireAccountOnboarding() async {
    final instance = OnboardingService();
    await instance.setOnboardingRequired();
  }
  
  static Future<void> completeAccountOnboarding() async {
    final instance = OnboardingService();
    await instance.setOnboardingComplete();
  }
  
  static Future<void> requireUserOnboarding() async {
    final instance = OnboardingService();
    await instance.setUserOnboardingRequired();
  }
  
  static Future<void> completeUserOnboarding() async {
    final instance = OnboardingService();
    await instance.setUserOnboardingComplete();
  }
  
  static Future<void> clearAll() async {
    if (!Hive.isBoxOpen(_onboardingBox)) {
      return;
    }
    final box = Hive.box(_onboardingBox);
    await box.clear();
    
    // Notify listeners
    _instance._cachedValue = true;
    _instance._onboardingController.add(true);
  }
  
  static Future<void> init() async {
    // This ensures the box is open for static access
    if (!Hive.isBoxOpen(_onboardingBox)) {
      await Hive.openBox(_onboardingBox);
    }
    // Initialize the instance (it will call _init)
    _instance._ensureBox();
  }
  
  // Static methods for direct access (alternative to instance methods)
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
    if (!Hive.isBoxOpen(_onboardingBox)) {
      await Hive.openBox(_onboardingBox);
    }
    final box = Hive.box(_onboardingBox);
    await box.delete(_needsAccountOnboardingKey);
    await box.delete(_needsUserOnboardingKey);
    _instance._cachedValue = true;
    _instance._onboardingController.add(true);
  }
  
  // Watch for Hive changes (reactive approach)
  static Stream<bool> watchOnboardingStatus() {
    if (!Hive.isBoxOpen(_onboardingBox)) {
      return Stream.value(true);
    }
    return Hive.box(_onboardingBox)
        .watch(key: _needsAccountOnboardingKey)
        .map((event) => event.value as bool? ?? true);
  }
  
  void dispose() {
    _onboardingController.close();
    if (Hive.isBoxOpen(_onboardingBox)) {
      _box.close();
    }
  }
}