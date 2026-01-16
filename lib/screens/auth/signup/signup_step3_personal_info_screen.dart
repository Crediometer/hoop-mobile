import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/components/inputs/input.dart';
import 'package:hoop/dtos/requests/PersonalInfoData.dart';
import 'package:hoop/screens/auth/signup/signup_step4_facial_verification_screen.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:hoop/utils/forms/validators.dart';
import 'package:hoop/widgets/progress_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  final _scrollController = ScrollController();

  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? _selectedGender;

  LocationData? _locationData;
  bool _loading = false;
  bool _gettingLocation = true;
  String _locationError = '';
  int _locationAttempts = 0;

  final Map<String, String?> _errors = {};
  final Set<String> _touchedFields = {};

  final int totalSteps = 4;
  final int currentStep = 3;
  final List<String> genders = ['male', 'female'];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _dobController.dispose();
    _occupationController.dispose();
    _bioController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to parse dates in multiple formats
  DateTime? _parseDate(String dateString) {
    if (dateString.isEmpty) return null;
    
    // Remove any extra whitespace
    dateString = dateString.trim();
    
    // Try ISO 8601 format first (yyyy-MM-dd)
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      // Try other common formats
      final formats = [
        DateFormat('dd/MM/yyyy'),
        DateFormat('dd-MM-yyyy'),
        DateFormat('MM/dd/yyyy'),
        DateFormat('MM-dd-yyyy'),
        DateFormat('yyyy/MM/dd'),
        DateFormat('dd.MM.yyyy'),
        DateFormat('MM.dd.yyyy'),
      ];
      
      for (var format in formats) {
        try {
          return format.parse(dateString);
        } catch (e) {
          continue;
        }
      }
      return null;
    }
  }

  // Format date for display (dd/MM/yyyy)
  String _formatDateForDisplay(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format date for storage (yyyy-MM-dd)
  String _formatDateForStorage(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Calculate age from date string
  int _calculateAge(String dob) {
    final birthDate = _parseDate(dob);
    if (birthDate == null) return 0;
    
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    final monthDiff = today.month - birthDate.month;

    if (monthDiff < 0 || (monthDiff == 0 && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  // Calculate age from DateTime
  int _calculateAgeFromDateTime(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    final monthDiff = today.month - birthDate.month;

    if (monthDiff < 0 || (monthDiff == 0 && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  bool get _isAdult {
    if (_dobController.text.isEmpty) return false;
    try {
      return _calculateAge(_dobController.text) >= 18;
    } catch (e) {
      return false;
    }
  }

  // Field validation
  String? _validateField(String field, dynamic value) {
    switch (field) {
      case 'dateOfBirth':
        if (value == null || value.toString().isEmpty) {
          return 'Date of birth is required';
        }
        
        final birthDate = _parseDate(value.toString());
        if (birthDate == null) {
          return 'Please enter a valid date (e.g., dd/mm/yyyy or yyyy-mm-dd)';
        }
        
        if (birthDate.isAfter(DateTime.now())) {
          return 'Date of birth cannot be in the future';
        }
        
        final age = _calculateAgeFromDateTime(birthDate);
        if (age < 18) {
          return 'You must be at least 18 years old';
        }
        
        if (age > 120) {
          return 'Please enter a valid date of birth';
        }
        
        return null;

      case 'gender':
        if (value == null || value.toString().isEmpty) {
          return 'Gender is required';
        }
        if (!genders.contains(value.toString().toLowerCase())) {
          return 'Please select a valid gender';
        }
        return null;

      case 'occupation':
        if (value == null || value.toString().trim().isEmpty) {
          return 'Occupation is required';
        }
        final occupation = value.toString().trim();
        if (occupation.length < 2) {
          return 'Occupation must be at least 2 characters';
        }
        if (occupation.length > 100) {
          return 'Occupation must be less than 100 characters';
        }
        if (!RegExp(r'^[A-Za-z\s\-\&\,\.\(\)]+$').hasMatch(occupation)) {
          return 'Occupation contains invalid characters';
        }
        return null;

      case 'bio':
        if (value != null && value.toString().length > 500) {
          return 'Bio must be less than 500 characters';
        }
        return null;

      case 'location':
        if (_locationData == null) {
          return 'Location is required';
        }
        return null;

      default:
        return null;
    }
  }

  // Validate all fields
  bool _validateForm() {
    final newErrors = <String, String?>{};

    newErrors['dateOfBirth'] = _validateField(
      'dateOfBirth',
      _dobController.text,
    );
    newErrors['gender'] = _validateField('gender', _selectedGender);
    newErrors['occupation'] = _validateField(
      'occupation',
      _occupationController.text,
    );
    newErrors['bio'] = _validateField('bio', _bioController.text);
    newErrors['location'] = _validateField('location', _locationData);

    // Remove null errors
    newErrors.removeWhere((key, value) => value == null);

    setState(() {
      _errors.clear();
      _errors.addAll(newErrors);
    });

    return _errors.isEmpty;
  }

  // Handle field change with validation
  void _handleFieldChange(String field, String value) {
    setState(() {
      _touchedFields.add(field);

      // Clear error for this field
      if (_errors.containsKey(field)) {
        _errors.remove(field);
      }
    });
  }

  // Enhanced IP-based geolocation
  Future<LocationData?> _getIPBasedLocation() async {
    const services = [
      {'name': 'ipapi', 'url': 'https://ipapi.co/json/'},
      {'name': 'ip-api', 'url': 'http://ip-api.com/json/'},
    ];

    for (final service in services) {
      try {
        final response = await http.get(Uri.parse(service['url']!));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          double? lat, lng;
          String address = '';

          if (service['name'] == 'ipapi') {
            lat = data['latitude']?.toDouble();
            lng = data['longitude']?.toDouble();
            address =
                '${data['city'] ?? ''}, ${data['region'] ?? ''}, ${data['country_name'] ?? ''}';
          } else {
            lat = data['lat']?.toDouble();
            lng = data['lon']?.toDouble();
            address =
                '${data['city'] ?? ''}, ${data['regionName'] ?? ''}, ${data['country'] ?? ''}';
          }

          address = address.replaceAll(RegExp(r'^, |, $'), '').trim();

          if (lat != null && lng != null) {
            return LocationData(
              latitude: lat,
              longitude: lng,
              address: address.isNotEmpty ? address : null,
              accuracy: 'medium',
              source: 'ip',
            );
          }
        }
      } catch (error) {
        print('IP geolocation service ${service['name']} failed: $error');
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    return null;
  }

  // Get GPS location
  Future<LocationData?> _getGPSLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy < 100 ? 'high' : 'medium',
        source: 'gps',
      );
    } catch (error) {
      print('GPS location error: $error');
      return null;
    }
  }

  // Main location detection
  Future<LocationData> _detectLocation() async {
    setState(() {
      _locationAttempts++;
    });

    // Try GPS first
    final gpsLocation = await _getGPSLocation();
    if (gpsLocation != null) {
      return gpsLocation;
    }

    // Fall back to IP-based location
    final ipLocation = await _getIPBasedLocation();
    if (ipLocation != null) {
      return ipLocation;
    }

    // Final fallback
    return LocationData(
      latitude: 6.5244,
      longitude: 3.3792,
      address: 'Lagos, Nigeria',
      accuracy: 'low',
      source: 'default',
    );
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _gettingLocation = true;
      _locationError = '';
      _errors.remove('location');
    });

    try {
      final location = await _detectLocation();

      setState(() {
        _locationData = location;
        _gettingLocation = false;

        if (location.source == 'ip') {
          _locationError =
              'Using approximate location based on your IP address. GPS was unavailable.';
        } else if (location.source == 'default') {
          _locationError =
              'Using default location. Please enable location services for better accuracy.';
        }
      });
    } catch (error) {
      print('Location detection failed: $error');
      setState(() {
        _locationError =
            'Failed to detect your location. Using default location.';
        _locationData = LocationData(
          latitude: 6.5244,
          longitude: 3.3792,
          address: 'Lagos, Nigeria',
          accuracy: 'low',
          source: 'default',
        );
        _gettingLocation = false;
      });
    }
  }

  Future<void> _retryLocation() async {
    setState(() {
      _locationError = 'Retrying location detection...';
      _gettingLocation = true;
      _errors.remove('location');
    });

    try {
      final location = await _detectLocation();

      setState(() {
        _locationData = location;
        _gettingLocation = false;

        if (location.source == 'gps') {
          _locationError = 'Precise GPS location acquired!';
        } else if (location.source == 'ip') {
          _locationError = 'Using IP-based location. GPS is unavailable.';
        }
      });
    } catch (error) {
      setState(() {
        _locationError =
            'Failed to get location. Please check your permissions.';
        _gettingLocation = false;
      });
    }
  }

  String _getLocationAccuracyText() {
    if (_locationData == null) return '';

    switch (_locationData!.accuracy) {
      case 'high':
        return 'High accuracy (GPS)';
      case 'medium':
        return 'Medium accuracy (IP-based)';
      case 'low':
        return 'Low accuracy (Default)';
      default:
        return 'Unknown accuracy';
    }
  }

  String _getLocationSourceText() {
    if (_locationData == null) return '';

    switch (_locationData!.source) {
      case 'gps':
        return 'GPS';
      case 'ip':
        return 'IP Address';
      case 'default':
        return 'Default';
      default:
        return 'Unknown';
    }
  }

  void _scrollToError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_errors.isNotEmpty) {
        final firstError = _errors.keys.first;
        final contextKey = GlobalKey();

        // You might need to implement a custom solution to scroll to specific fields
        // This is a simplified version
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _onSubmit() async {
    // Mark all fields as touched
    setState(() {
      _touchedFields.addAll([
        'dateOfBirth',
        'gender',
        'occupation',
        'bio',
        'location',
      ]);
    });

    // Validate all fields
    if (!_validateForm()) {
      _scrollToError();
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // Parse and format date for storage
      final birthDate = _parseDate(_dobController.text);
      if (birthDate == null) {
        throw Exception('Invalid date format');
      }
      
      final formattedDate = _formatDateForStorage(birthDate);

      // Call your completePersonalInfo method
      PersonalInfoData data = PersonalInfoData(
        bio: _bioController.text,
        dateOfBirth: formattedDate,
        gender: _selectedGender!,
        latitude: _locationData!.latitude,
        longitude: _locationData!.longitude,
        occupation: _occupationController.text,
      );
      final success = await AuthProvider().completePersonalInfo(data);

      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SignupStep4FacialVerificationScreen(),
          ),
        );
      } else {
        setState(() {
          _errors['general'] =
              'Failed to save personal information. Please try again.';
        });
      }
    } catch (e) {
      print('Error saving personal info: $e');
      setState(() {
        _errors['general'] = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  bool get _canSubmit {
    return _dobController.text.isNotEmpty &&
        _selectedGender != null &&
        _occupationController.text.isNotEmpty &&
        _locationData != null &&
        _isAdult;
  }

  // Helper to format date input as user types
  void _formatDateInput(String value) {
    if (value.isEmpty) return;
    
    // Remove all non-digits
    String digits = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length > 8) {
      digits = digits.substring(0, 8);
    }
    
    // Format as dd/MM/yyyy
    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) {
        formatted += '/';
      }
      formatted += digits[i];
    }
    
    // Only update if different to avoid infinite loop
    if (_dobController.text != formatted) {
      _dobController.text = formatted;
      _dobController.selection = TextSelection.fromPosition(
        TextPosition(offset: formatted.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[700];
    final errorColor = Colors.redAccent;
    final successColor = Colors.greenAccent;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SignupProgressBar(
                currentStep: currentStep,
                totalSteps: totalSteps,
              ),
              const SizedBox(height: 20),

              if (_errors.containsKey('general'))
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: errorColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errors['general']!,
                    style: TextStyle(color: errorColor, fontSize: 14),
                  ),
                ),
              if (_errors.containsKey('general')) const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date of Birth
                    Text(
                      'Date of Birth *',
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    HoopInput(
                      controller: _dobController,
                      hintText: 'dd/mm/yyyy',
                      validator: (value) {
                        final error = _validateField('dateOfBirth', value);
                        return error;
                      },
                      keyboardType: TextInputType.datetime,
                      onChanged: (value) {
                        _formatDateInput(value);
                        _handleFieldChange('dateOfBirth', value);
                      },
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: hintColor,
                      ),
                    ),
                    if (_errors.containsKey('dateOfBirth') &&
                        _touchedFields.contains('dateOfBirth'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _errors['dateOfBirth']!,
                          style: TextStyle(color: errorColor, fontSize: 12),
                        ),
                      ),
                    if (_dobController.text.isNotEmpty &&
                        _isAdult &&
                        !_errors.containsKey('dateOfBirth'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '✓ Age: ${_calculateAge(_dobController.text)} years old',
                          style: TextStyle(color: successColor, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 18),

                    // Gender
                    Text(
                      'Gender *',
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    HoopDropdownInput(
                      value: _selectedGender,
                      validator: (value) {
                        final error = _validateField('gender', value);
                        return error;
                      },
                      items: genders
                          .map(
                            (g) => DropdownMenuItem<String>(
                              value: g,
                              child: Text(
                                g[0].toUpperCase() + g.substring(1),
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                          _handleFieldChange('gender', value ?? '');
                        });
                      },
                      hintText: 'Select gender',
                    ),
                    if (_errors.containsKey('gender') &&
                        _touchedFields.contains('gender'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _errors['gender']!,
                          style: TextStyle(color: errorColor, fontSize: 12),
                        ),
                      ),
                    if (_selectedGender != null &&
                        !_errors.containsKey('gender'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '✓ Gender selected',
                          style: TextStyle(color: successColor, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 18),

                    // Occupation
                    Text(
                      'Occupation *',
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    HoopInput(
                      controller: _occupationController,
                      hintText: 'What do you do?',
                      validator: (value) {
                        final error = _validateField('occupation', value);
                        return error;
                      },
                      keyboardType: TextInputType.text,
                      onChanged: (value) {
                        _handleFieldChange('occupation', value);
                      },
                    ),
                    if (_errors.containsKey('occupation') &&
                        _touchedFields.contains('occupation'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _errors['occupation']!,
                          style: TextStyle(color: errorColor, fontSize: 12),
                        ),
                      ),
                    if (_occupationController.text.isNotEmpty &&
                        !_errors.containsKey('occupation'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '✓ Occupation validated',
                          style: TextStyle(color: successColor, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 18),

                    // Bio
                    Text(
                      'Bio ${_bioController.text.isNotEmpty ? "(${_bioController.text.length}/500)" : ""}',
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    HoopInput(
                      controller: _bioController,
                      hintText: 'Tell us a bit about yourself...',
                      maxLines: 3,
                      validator: (value) {
                        final error = _validateField('bio', value);
                        return error;
                      },
                      onChanged: (value) {
                        _handleFieldChange('bio', value);
                      },
                    ),
                    if (_errors.containsKey('bio') &&
                        _touchedFields.contains('bio'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _errors['bio']!,
                          style: TextStyle(color: errorColor, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Enhanced Location Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _gettingLocation
                            ? Colors.blue[50]
                            : _locationData != null
                                ? (_locationData!.source == 'gps'
                                    ? Colors.green[50]
                                    : Colors.amber[50])
                                : Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _gettingLocation
                              ? Colors.blue[200]!
                              : _locationData != null
                                  ? (_locationData!.source == 'gps'
                                      ? Colors.green[200]!
                                      : Colors.amber[200]!)
                                  : Colors.red[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: _gettingLocation
                                    ? Colors.blue[800]
                                    : _locationData != null
                                        ? (_locationData!.source == 'gps'
                                            ? Colors.green[800]
                                            : Colors.amber[800])
                                        : Colors.red[800],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _gettingLocation
                                    ? '📍 Detecting Your Location *'
                                    : _locationData != null
                                        ? '📍 Location Detected *'
                                        : '📍 Location Required *',
                                style: TextStyle(
                                  color: _gettingLocation
                                      ? Colors.blue[800]
                                      : _locationData != null
                                          ? (_locationData!.source == 'gps'
                                              ? Colors.green[800]
                                              : Colors.amber[800])
                                          : Colors.red[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_locationData != null)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _locationData!.source == 'gps'
                                        ? Colors.green[100]
                                        : _locationData!.source == 'ip'
                                            ? Colors.amber[100]
                                            : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getLocationSourceText(),
                                    style: TextStyle(
                                      color: _locationData!.source == 'gps'
                                          ? Colors.green[800]
                                          : _locationData!.source == 'ip'
                                              ? Colors.amber[800]
                                              : Colors.grey[800],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_gettingLocation)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.blue[700]!,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Detecting your location... (Attempt $_locationAttempts)',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else if (_locationData != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Coordinates
                                Text(
                                  'Coordinates:',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${_locationData!.latitude.toStringAsFixed(6)}, ${_locationData!.longitude.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    color: hintColor,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Accuracy
                                Text(
                                  'Accuracy:',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _getLocationAccuracyText(),
                                  style: TextStyle(
                                    color: hintColor,
                                    fontSize: 13,
                                  ),
                                ),

                                if (_locationData!.address != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Address:',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _locationData!.address!,
                                    style: TextStyle(
                                      color: hintColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],

                                if (_locationData!.source != 'gps') ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _locationData!.source == 'ip'
                                        ? 'Using IP-based location. For better accuracy, enable GPS permissions and retry.'
                                        : 'Using default location. Enable location services for accurate detection.',
                                    style: TextStyle(
                                      color: Colors.amber[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _gettingLocation
                                        ? null
                                        : _retryLocation,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.amber[700]!,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _gettingLocation
                                            ? 'Detecting...'
                                            : 'Retry GPS Location',
                                        style: TextStyle(
                                          color: Colors.amber[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _locationError.isNotEmpty
                                      ? _locationError
                                      : 'Location is required to continue',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: _gettingLocation
                                      ? null
                                      : _retryLocation,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red[600],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _gettingLocation
                                          ? 'Detecting...'
                                          : 'Retry Location Detection',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          if (_errors.containsKey('location') &&
                              _touchedFields.contains('location'))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _errors['location']!,
                                style: TextStyle(
                                  color: errorColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Continue Button
                    HoopButton(
                      onPressed: _canSubmit && !_loading ? _onSubmit : null,
                      isLoading: _loading,
                      buttonText: _loading
                          ? 'Validating and Saving...'
                          : 'Continue to Facial Verification →',
                      disabled: !(_canSubmit && !_loading),
                    ),
                    const SizedBox(height: 24),

                    // Validation Summary
                    if (_touchedFields.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Validation Status:',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: [
                                _buildValidationItem(
                                  'Date of Birth (18+ years)',
                                  _dobController.text.isNotEmpty && _isAdult,
                                ),
                                const SizedBox(height: 4),
                                _buildValidationItem(
                                  'Gender Selected',
                                  _selectedGender != null,
                                ),
                                const SizedBox(height: 4),
                                _buildValidationItem(
                                  'Occupation Valid',
                                  _occupationController.text.isNotEmpty &&
                                      !_errors.containsKey('occupation'),
                                ),
                                const SizedBox(height: 4),
                                _buildValidationItem(
                                  'Location Captured',
                                  _locationData != null,
                                ),
                              ],
                            ),
                          ],
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

  Widget _buildValidationItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.error,
          color: isValid ? Colors.green[600] : Colors.red[600],
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green[600] : Colors.red[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}