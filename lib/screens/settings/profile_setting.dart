// screens/profile/profile_details_screen.dart
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/back_button.dart';
import 'package:hoop/dtos/responses/User.dart';
import 'package:hoop/utils/helpers/formatters/hoop_formatter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/states/auth_state.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  late User _profile;
  late User _editedProfile;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSaving = false;

  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _occupationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // If user is already loaded, use it
      if (authProvider.user != null) {
        _profile = authProvider.user!;
        _editedProfile = User.fromJson(authProvider.user!.toJson());
        _updateControllers();
      } else {
        // Fetch profile if not loaded
        await authProvider.getProfile();
        if (authProvider.user != null) {
          _profile = authProvider.user!;
          _editedProfile = User.fromJson(authProvider.user!.toJson());
          _updateControllers();
        }
      }
    } catch (e) {
      log('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateControllers() {
    _occupationController.text = _profile.personalInfo?.occupation ?? '';
    _bioController.text = _profile.personalInfo?.bio ?? '';
  }

  Future<void> _handleSave() async {
    try {
      setState(() => _isSaving = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Prepare update data
      final updateData = {
        'occupation': _occupationController.text.trim(),
        'bio': _bioController.text.trim(),
      };

      // Remove empty fields
      updateData.removeWhere((key, value) => value.isEmpty);

      final response = await authProvider.updateProfile(updateData);

      if (response.success) {
        // Refresh profile
        await authProvider.getProfile();

        // Update local state
        setState(() {
          _isEditing = false;
          _profile = authProvider.user!;
          _editedProfile = User.fromJson(authProvider.user!.toJson());
          _updateControllers();
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: HoopTheme.successGreen,
          ),
        );
      } else {
        throw Exception(response.message ?? 'Failed to update profile');
      }
    } catch (e) {
      log('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _handleCancel() {
    setState(() {
      _isEditing = false;
      _editedProfile = User.fromJson(_profile.toJson());
      _updateControllers();
    });
  }

  Future<void> _handleImageUpload() async {
    // TODO: Implement image upload
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image upload not implemented yet')),
    );
  }

  String get _initials {
    final firstName = _profile.firstName ?? '';
    final lastName = _profile.lastName ?? '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName[0].toUpperCase();
    }
    return '👤';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not provided';

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return 'N/A';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = HoopTheme.getTextPrimary(isDark);
    final textSecondary = HoopTheme.getTextSecondary(isDark);
    final backgroundColor = isDark ? HoopTheme.darkBackground : Colors.grey[50];

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: HoopTheme.primaryRed),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  HoopBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Details',
                          style: TextStyle(
                            color: HoopTheme.primaryBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage your personal information',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (_isEditing)
                    Row(
                      children: [
                        IconButton(
                          onPressed: _handleCancel,
                          icon: Icon(Icons.close, color: Colors.red, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isSaving ? null : _handleSave,
                          icon: _isSaving
                              ? SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          style: IconButton.styleFrom(
                            backgroundColor: HoopTheme.primaryBlue,
                          ),
                        ),
                      ],
                    )
                  else
                    IconButton(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: Icon(
                        Icons.edit,
                        color: HoopTheme.primaryBlue,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: HoopTheme.primaryBlue.withOpacity(0.1),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Basic Information
                    _buildBasicInformation(isDark, textPrimary, textSecondary),

                    const SizedBox(height: 24),

                    // Occupation
                    _buildOccupation(isDark, textPrimary, textSecondary),

                    const SizedBox(height: 24),

                    // Bio/About Me
                    _buildBio(isDark, textPrimary, textSecondary),

                    const SizedBox(height: 24),

                    // Account Statistics
                    _buildAccountStatistics(isDark, textPrimary, textSecondary),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInformation(
    bool isDark,
    Color textPrimary,
    Color? textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: TextStyle(
            color: HoopTheme.primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 0.5),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Names
              Text(
                'First Name',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _profile.firstName ?? '—',
                  style: TextStyle(color: textPrimary, fontSize: 14),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Last Name',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _profile.lastName ?? '—',
                  style: TextStyle(color: textPrimary, fontSize: 14),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Email Address',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, size: 16, color: textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _profile.email ?? '—',
                        style: TextStyle(color: textPrimary, fontSize: 14),
                      ),
                    ),
                    if (_profile.email != null && _profile.email!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: HoopTheme.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Verified',
                          style: TextStyle(
                            color: HoopTheme.successGreen,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Phone Number',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _profile.phoneNumber ?? '—',
                        style: TextStyle(color: textPrimary, fontSize: 14),
                      ),
                    ),
                    if (_profile.phoneNumber != null &&
                        _profile.phoneNumber!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: HoopTheme.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Verified',
                          style: TextStyle(
                            color: HoopTheme.successGreen,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Date of Birth',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        HoopFormatters.formatDate(
                          _profile.personalInfo?.dateOfBirth ?? DateTime.now(),
                        ),
                        style: TextStyle(color: textPrimary, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Gender',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _profile.personalInfo?.gender?.isNotEmpty == true
                      ? '${_profile.personalInfo!.gender![0].toUpperCase()}${_profile.personalInfo!.gender!.substring(1).toLowerCase()}'
                      : '—',
                  style: TextStyle(color: textPrimary, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOccupation(
    bool isDark,
    Color textPrimary,
    Color? textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Occupation',
          style: TextStyle(
            color: HoopTheme.primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 0.5),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(16),
          child: _isEditing
              ? TextField(
                  controller: _occupationController,
                  decoration: InputDecoration(
                    hintText: 'Enter your occupation',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.work_outline, size: 16, color: textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _profile.personalInfo?.occupation?.isNotEmpty == true
                              ? _profile.personalInfo!.occupation!
                              : 'No occupation added',
                          style: TextStyle(color: textPrimary, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBio(bool isDark, Color textPrimary, Color? textSecondary) {
    final bioLength = _bioController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'About Me',
          style: TextStyle(
            color: HoopTheme.primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 0.5),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _isEditing
                  ? TextField(
                      controller: _bioController,
                      maxLines: 4,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: 'Tell others about yourself...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _profile.personalInfo?.bio?.isNotEmpty == true
                            ? _profile.personalInfo!.bio!
                            : 'No bio added yet.',
                        style: TextStyle(color: textPrimary, fontSize: 14),
                      ),
                    ),
              const SizedBox(height: 8),
              Text(
                _isEditing
                    ? '$bioLength/200 characters'
                    : 'This will be visible to other group members.',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountStatistics(
    bool isDark,
    Color textPrimary,
    Color? textSecondary,
  ) {
    final memberSince = _profile.createdAt != null
        ? HoopFormatters.formatDayMonth(_profile.createdAt!)
        : DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Statistics',
          style: TextStyle(
            color: HoopTheme.primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 0.5),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      HoopFormatters.formatTime(DateTime.now()),
                      style: TextStyle(
                        color: HoopTheme.primaryBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member Since',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '98%',
                      style: TextStyle(
                        color: HoopTheme.successGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reliability Score',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
