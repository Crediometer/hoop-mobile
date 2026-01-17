// device_info_manager.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoManager {
  static final DeviceInfoManager _instance = DeviceInfoManager._internal();
  factory DeviceInfoManager() => _instance;
  DeviceInfoManager._internal();

  static String? _cachedDeviceId;
  static String? _cachedDeviceName;
  static String? _cachedDeviceFingerprint;

  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();

  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      final deviceInfo = await _deviceInfoPlugin.deviceInfo;

      if (deviceInfo is AndroidDeviceInfo) {
        // Use ANDROID_ID - stable across app installs
        _cachedDeviceId = deviceInfo.id;
      } else if (deviceInfo is IosDeviceInfo) {
        // Use identifierForVendor - stable per vendor
        _cachedDeviceId = deviceInfo.identifierForVendor;
      } else if (deviceInfo is WebBrowserInfo) {
        // Web needs persistence
        _cachedDeviceId = await _getPersistentWebId(deviceInfo);
      }

      // Fallback if OS doesn't provide ID
      if (_cachedDeviceId == null || _cachedDeviceId!.isEmpty) {
        _cachedDeviceId = await _getFallbackDeviceId();
      }

      return _cachedDeviceId!;
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      return await _getFallbackDeviceId();
    }
  }

  Future<String> getDeviceName() async {
    if (_cachedDeviceName != null) return _cachedDeviceName!;

    try {
      final deviceInfo = await _deviceInfoPlugin.deviceInfo;
      _cachedDeviceName = _getDeviceName(deviceInfo);
      return _cachedDeviceName!;
    } catch (e) {
      debugPrint('Error getting device name: $e');
      return 'Unknown Device';
    }
  }

  Future<String> getDeviceFingerprint() async {
    if (_cachedDeviceFingerprint != null) return _cachedDeviceFingerprint!;

    try {
      final deviceInfo = await _deviceInfoPlugin.deviceInfo;
      _cachedDeviceFingerprint = await _generateDeviceFingerprint(deviceInfo);
      return _cachedDeviceFingerprint!;
    } catch (e) {
      debugPrint('Error generating device fingerprint: $e');
      // Generate a random fingerprint as fallback
      final random = Random.secure();
      _cachedDeviceFingerprint = sha256.convert(
        utf8.encode('${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(999999)}'),
      ).toString();
      return _cachedDeviceFingerprint!;
    }
  }

  String _getDeviceName(BaseDeviceInfo deviceInfo) {
    if (deviceInfo is AndroidDeviceInfo) {
      return '${deviceInfo.manufacturer} ${deviceInfo.model}';
    } else if (deviceInfo is IosDeviceInfo) {
      return 'iPhone ${deviceInfo.model}';
    } else if (deviceInfo is WebBrowserInfo) {
      return '${deviceInfo.browserName.name} on ${deviceInfo.platform}';
    }
    return 'Unknown Device';
  }

  Future<String> _generateDeviceFingerprint(BaseDeviceInfo deviceInfo) async {
    final info = <String, dynamic>{};

    if (deviceInfo is AndroidDeviceInfo) {
      info['manufacturer'] = deviceInfo.manufacturer;
      info['model'] = deviceInfo.model;
      info['brand'] = deviceInfo.brand;
      info['device'] = deviceInfo.device;
      info['board'] = deviceInfo.board;
      info['hardware'] = deviceInfo.hardware;
      info['fingerprint'] = deviceInfo.fingerprint;
    } else if (deviceInfo is IosDeviceInfo) {
      info['model'] = deviceInfo.model;
      info['name'] = deviceInfo.name;
      info['systemName'] = deviceInfo.systemName;
      info['systemVersion'] = deviceInfo.systemVersion;
    } else if (deviceInfo is WebBrowserInfo) {
      info['browserName'] = deviceInfo.browserName.name;
      info['platform'] = deviceInfo.platform;
      info['userAgent'] = deviceInfo.userAgent?.substring(0, min(200, deviceInfo.userAgent?.length ?? 0));
    }

    // Add app version
    final packageInfo = await PackageInfo.fromPlatform();
    info['appVersion'] = packageInfo.version;
    info['buildNumber'] = packageInfo.buildNumber;

    // Hash the info
    final jsonString = jsonEncode(info);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  Future<String> _getFallbackDeviceId() async {
    // Only use SharedPreferences as LAST RESORT fallback
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString('fallback_device_id');

    if (storedId != null) {
      _cachedDeviceId = storedId;
      return storedId;
    }

    final newId = _uuid.v4();
    await prefs.setString('fallback_device_id', newId);
    _cachedDeviceId = newId;
    return newId;
  }

  Future<String> _getPersistentWebId(WebBrowserInfo deviceInfo) async {
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('web_device_id');

    if (storedId != null) return storedId;

    // Generate a fingerprint-based ID for web
    final fingerprintData = {
      'userAgent': deviceInfo.userAgent,
      'platform': deviceInfo.platform,
      'language': deviceInfo.language,
      'vendor': deviceInfo.vendor,
      'browserName': deviceInfo.browserName.name,
      'appCodeName': deviceInfo.appCodeName,
    };

    final jsonString = jsonEncode(fingerprintData);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    storedId = digest.toString();

    await prefs.setString('web_device_id', storedId);
    return storedId;
  }

  // Clear cache (useful for logout)
  void clearCache() {
    _cachedDeviceId = null;
    _cachedDeviceName = null;
    _cachedDeviceFingerprint = null;
  }

  // Get all device info as a map for API calls
  Future<Map<String, String>> getDeviceInfoForApi() async {
    return {
      'deviceId': await getDeviceId(),
      'deviceName': await getDeviceName(),
      'deviceFingerprint': await getDeviceFingerprint(),
      'platform': Platform.operatingSystem,
    };
  }
}