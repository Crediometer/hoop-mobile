import 'package:flutter/material.dart';
import 'package:hoop/constants/themes.dart';

// DTO for community preferences
class CommunityPreferences {
  final bool goGlobal;
  final int distanceRadius;
  final String preferredGroupSize;
  final int contributionMin;
  final int contributionMax;
  final int totalPotMin;
  final int totalPotMax;
  final bool groupRecommendations;
  final bool nearbyAlerts;
  final bool communityNotifications;
  final bool autoJoinGroups;

  CommunityPreferences({
    this.goGlobal = true,
    this.distanceRadius = 25,
    this.preferredGroupSize = 'MEDIUM',
    this.contributionMin = 5000,
    this.contributionMax = 50000,
    this.totalPotMin = 50000,
    this.totalPotMax = 500000,
    this.groupRecommendations = true,
    this.nearbyAlerts = true,
    this.communityNotifications = true,
    this.autoJoinGroups = false,
  });

  Map<String, dynamic> toJson() => {
    'goGlobal': goGlobal,
    'distanceRadius': distanceRadius,
    'preferredGroupSize': preferredGroupSize,
    'contributionMin': contributionMin,
    'contributionMax': contributionMax,
    'totalPotMin': totalPotMin,
    'totalPotMax': totalPotMax,
    'groupRecommendations': groupRecommendations,
    'nearbyAlerts': nearbyAlerts,
    'communityNotifications': communityNotifications,
    'autoJoinGroups': autoJoinGroups,
  };

  factory CommunityPreferences.fromJson(Map<String, dynamic> json) {
    return CommunityPreferences(
      goGlobal: json['goGlobal'] ?? true,
      distanceRadius: json['distanceRadius'] ?? 25,
      preferredGroupSize: json['preferredGroupSize'] ?? 'MEDIUM',
      contributionMin: json['contributionMin'] ?? 5000,
      contributionMax: json['contributionMax'] ?? 50000,
      totalPotMin: json['totalPotMin'] ?? 50000,
      totalPotMax: json['totalPotMax'] ?? 500000,
      groupRecommendations: json['groupRecommendations'] ?? true,
      nearbyAlerts: json['nearbyAlerts'] ?? true,
      communityNotifications: json['communityNotifications'] ?? true,
      autoJoinGroups: json['autoJoinGroups'] ?? false,
    );
  }

  CommunityPreferences copyWith({
    bool? goGlobal,
    int? distanceRadius,
    String? preferredGroupSize,
    int? contributionMin,
    int? contributionMax,
    int? totalPotMin,
    int? totalPotMax,
    bool? groupRecommendations,
    bool? nearbyAlerts,
    bool? communityNotifications,
    bool? autoJoinGroups,
  }) {
    return CommunityPreferences(
      goGlobal: goGlobal ?? this.goGlobal,
      distanceRadius: distanceRadius ?? this.distanceRadius,
      preferredGroupSize: preferredGroupSize ?? this.preferredGroupSize,
      contributionMin: contributionMin ?? this.contributionMin,
      contributionMax: contributionMax ?? this.contributionMax,
      totalPotMin: totalPotMin ?? this.totalPotMin,
      totalPotMax: totalPotMax ?? this.totalPotMax,
      groupRecommendations: groupRecommendations ?? this.groupRecommendations,
      nearbyAlerts: nearbyAlerts ?? this.nearbyAlerts,
      communityNotifications: communityNotifications ?? this.communityNotifications,
      autoJoinGroups: autoJoinGroups ?? this.autoJoinGroups,
    );
  }
}

// Custom Switch Widget matching web style
class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool disabled;

  const CustomSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.disabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value 
              ? (disabled ? Colors.grey : HoopTheme.primaryBlue)
              : (disabled ? Colors.grey.shade300 : Colors.grey.shade300),
        ),
        child: Stack(
          children: [
            Positioned(
              left: value ? 22 : 2,
              top: 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Slider Widget matching web style
class CustomSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double step;

  const CustomSlider({
    Key? key,
    required this.value,
    required this.onChanged,
    this.min = 5,
    this.max = 100,
    this.step = 5,
  }) : super(key: key);

  @override
  State<CustomSlider> createState() => _CustomSliderState();
}

class _CustomSliderState extends State<CustomSlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: 12,
              disabledThumbRadius: 12,
            ),
            overlayShape: RoundSliderOverlayShape(
              overlayRadius: 16,
            ),
            activeTrackColor: HoopTheme.primaryBlue,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: Colors.white,
            overlayColor: HoopTheme.primaryBlue.withOpacity(0.2),
          ),
          child: Slider(
            value: _currentValue,
            min: widget.min,
            max: widget.max,
            divisions: ((widget.max - widget.min) / widget.step).round(),
            onChanged: (value) {
              setState(() {
                _currentValue = value;
              });
            },
            onChangeEnd: (value) {
              widget.onChanged(value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.min.toInt()} km',
              style: TextStyle(
                fontSize: 12,
                color: HoopTheme.getTextSecondary(
                  Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ),
            Text(
              '${widget.max.toInt()} km',
              style: TextStyle(
                fontSize: 12,
                color: HoopTheme.getTextSecondary(
                  Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Main Community Settings Screen
class CommunitySettingsScreen extends StatefulWidget {
  const CommunitySettingsScreen({Key? key}) : super(key: key);

  @override
  State<CommunitySettingsScreen> createState() => _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends State<CommunitySettingsScreen> {
  late CommunityPreferences _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _settings = CommunityPreferences();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace with actual API call
    // final preferences = await yourApiService.loadCommunityPreferences();
    // setState(() {
    //   _settings = preferences;
    //   _isLoading = false;
    // });

    // For now, use defaults
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    // TODO: Replace with actual API call
    // try {
    //   await yourApiService.updateCommunityPreferences(_settings);
    //   // Show success message
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Community preferences saved successfully'),
    //       backgroundColor: HoopTheme.successGreen,
    //     ),
    //   );
    // } catch (error) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Failed to save community preferences'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isSaving = false;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Community preferences saved successfully'),
        backgroundColor: HoopTheme.successGreen,
      ),
    );
  }

  Future<void> _resetPreferences() async {
    // TODO: Replace with actual API call
    // try {
    //   await yourApiService.resetCommunityPreferences();
    //   await _loadPreferences();
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Preferences reset to defaults'),
    //       backgroundColor: HoopTheme.successGreen,
    //     ),
    //   );
    // } catch (error) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Failed to reset preferences'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }

    // Simulate reset
    setState(() {
      _settings = CommunityPreferences();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preferences reset to defaults'),
        backgroundColor: HoopTheme.successGreen,
      ),
    );
  }

  String _formatCurrency(int amount) {
    // Format as NGN currency (you might want to adjust based on locale)
    return '₦${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: HoopTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your preferences...',
            style: TextStyle(
              color: HoopTheme.getTextSecondary(
                Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
  
      padding: const EdgeInsets.fromLTRB( 16,34, 16, 16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: HoopTheme.getTextPrimary(
                Theme.of(context).brightness == Brightness.dark,
              ),
            ),
            style: IconButton.styleFrom(
              backgroundColor: HoopTheme.getCategoryBackgroundColor(
                'back_button',
                Theme.of(context).brightness == Brightness.dark,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community Settings',
                style: TextStyle(
                  color: HoopTheme.primaryBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Customize your community experience',
                style: TextStyle(
                  color: HoopTheme.getTextSecondary(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalDiscoverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Global Discovery',
          style: TextStyle(
            color: HoopTheme.primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
           
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: HoopTheme.getBorderColor(
                Theme.of(context).brightness == Brightness.dark,
              ).withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Go Global toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: HoopTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.public,
                          color: HoopTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Go Global',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: HoopTheme.getTextPrimary(
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                          ),
                          Text(
                            'Discover groups worldwide',
                            style: TextStyle(
                              fontSize: 12,
                              color: HoopTheme.getTextSecondary(
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  CustomSwitch(
                    value: _settings.goGlobal,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(goGlobal: value);
                      });
                    },
                  ),
                ],
              ),
              
              // Discovery radius (shown only when goGlobal is false)
              if (!_settings.goGlobal) ...[
                const SizedBox(height: 16),
                Divider(
                  color: HoopTheme.getBorderColor(
                    Theme.of(context).brightness == Brightness.dark,
                  ).withOpacity(0.1),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discovery Radius',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: HoopTheme.getTextPrimary(
                              Theme.of(context).brightness == Brightness.dark,
                            ),
                          ),
                        ),
                        Text(
                          '${_settings.distanceRadius} km',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: HoopTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomSlider(
                      value: _settings.distanceRadius.toDouble(),
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(
                            distanceRadius: value.round(),
                          );
                        });
                      },
                      min: 5,
                      max: 100,
                      step: 5,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupPreferencesSection() {
    final groupSizes = {
      'SMALL': 'Small (5-10 members)',
      'MEDIUM': 'Medium (11-25 members)',
      'LARGE': 'Large (26-50 members)',
      'XLARGE': 'X-Large (51-100 members)',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group Preferences',
          style: TextStyle(
            color: HoopTheme.primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
           
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: HoopTheme.getBorderColor(
                Theme.of(context).brightness == Brightness.dark,
              ).withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Group Size
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferred Group Size',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: HoopTheme.getTextPrimary(
                        Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: HoopTheme.getBorderColor(
                          Theme.of(context).brightness == Brightness.dark,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _settings.preferredGroupSize,
                        isExpanded: true,
                        items: groupSizes.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 14,
                                color: HoopTheme.getTextPrimary(
                                  Theme.of(context).brightness == Brightness.dark,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _settings = _settings.copyWith(
                                preferredGroupSize: value,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Contribution Range
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contribution Range',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: HoopTheme.getTextPrimary(
                            Theme.of(context).brightness == Brightness.dark,
                          ),
                        ),
                      ),
                      Text(
                        '${_formatCurrency(_settings.contributionMin)} - ${_formatCurrency(_settings.contributionMax)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: HoopTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Minimum',
                              style: TextStyle(
                                fontSize: 12,
                                color: HoopTheme.getTextSecondary(
                                  Theme.of(context).brightness == Brightness.dark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: HoopTheme.getBorderColor(
                                    Theme.of(context).brightness == Brightness.dark,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: TextField(
                                controller: TextEditingController(
                                  text: _settings.contributionMin.toString(),
                                ),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration.collapsed(
                                  hintText: '',
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: HoopTheme.getTextPrimary(
                                    Theme.of(context).brightness == Brightness.dark,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      _settings = _settings.copyWith(
                                        contributionMin: int.tryParse(value) ?? 5000,
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Maximum',
                              style: TextStyle(
                                fontSize: 12,
                                color: HoopTheme.getTextSecondary(
                                  Theme.of(context).brightness == Brightness.dark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: HoopTheme.getBorderColor(
                                    Theme.of(context).brightness == Brightness.dark,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: TextField(
                                controller: TextEditingController(
                                  text: _settings.contributionMax.toString(),
                                ),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration.collapsed(
                                  hintText: '',
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: HoopTheme.getTextPrimary(
                                    Theme.of(context).brightness == Brightness.dark,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      _settings = _settings.copyWith(
                                        contributionMax: int.tryParse(value) ?? 50000,
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Total Pot Range
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pot Range',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: HoopTheme.getTextPrimary(
                            Theme.of(context).brightness == Brightness.dark,
                          ),
                        ),
                      ),
                      Text(
                        '${_formatCurrency(_settings.totalPotMin)} - ${_formatCurrency(_settings.totalPotMax)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: HoopTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Minimum',
                              style: TextStyle(
                                fontSize: 12,
                                color: HoopTheme.getTextSecondary(
                                  Theme.of(context).brightness == Brightness.dark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: HoopTheme.getBorderColor(
                                    Theme.of(context).brightness == Brightness.dark,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: TextField(
                                controller: TextEditingController(
                                  text: _settings.totalPotMin.toString(),
                                ),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration.collapsed(
                                  hintText: '',
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: HoopTheme.getTextPrimary(
                                    Theme.of(context).brightness == Brightness.dark,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      _settings = _settings.copyWith(
                                        totalPotMin: int.tryParse(value) ?? 50000,
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Maximum',
                              style: TextStyle(
                                fontSize: 12,
                                color: HoopTheme.getTextSecondary(
                                  Theme.of(context).brightness == Brightness.dark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: HoopTheme.getBorderColor(
                                    Theme.of(context).brightness == Brightness.dark,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: TextField(
                                controller: TextEditingController(
                                  text: _settings.totalPotMax.toString(),
                                ),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration.collapsed(
                                  hintText: '',
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: HoopTheme.getTextPrimary(
                                    Theme.of(context).brightness == Brightness.dark,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      _settings = _settings.copyWith(
                                        totalPotMax: int.tryParse(value) ?? 500000,
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications',
          style: TextStyle(
            color: HoopTheme.primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
           
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: HoopTheme.getBorderColor(
                Theme.of(context).brightness == Brightness.dark,
              ).withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Group Recommendations
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: HoopTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.people,
                          color: HoopTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Group Recommendations',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: HoopTheme.getTextPrimary(
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                          ),
                          Text(
                            'New group suggestions',
                            style: TextStyle(
                              fontSize: 12,
                              color: HoopTheme.getTextSecondary(
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  CustomSwitch(
                    value: _settings.groupRecommendations,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                          groupRecommendations: value,
                        );
                      });
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Nearby Alerts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: HoopTheme.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications,
                          color: HoopTheme.successGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nearby Alerts',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: HoopTheme.getTextPrimary(
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                          ),
                          Text(
                            'New groups in your area',
                            style: TextStyle(
                              fontSize: 12,
                              color: HoopTheme.getTextSecondary(
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  CustomSwitch(
                    value: _settings.nearbyAlerts,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                          nearbyAlerts: value,
                        );
                      });
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Community Updates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: HoopTheme.vibrantOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_active,
                          color: HoopTheme.vibrantOrange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community Updates',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: HoopTheme.getTextPrimary(
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                          ),
                          Text(
                            'Feature updates and news',
                            style: TextStyle(
                              fontSize: 12,
                              color: HoopTheme.getTextSecondary(
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  CustomSwitch(
                    value: _settings.communityNotifications,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                          communityNotifications: value,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutoJoinSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Auto-Join Settings',
          style: TextStyle(
            color: HoopTheme.primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: HoopTheme.getMutedColor(
              Theme.of(context).brightness == Brightness.dark,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: HoopTheme.getBorderColor(
                Theme.of(context).brightness == Brightness.dark,
              ).withOpacity(0.2),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.my_location, // Alternative to target icon
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Auto-Join',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: HoopTheme.getTextPrimary(
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                          ),
                          Text(
                            'Coming soon',
                            style: TextStyle(
                              fontSize: 12,
                              color: HoopTheme.getTextSecondary(
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  CustomSwitch(
                    value: _settings.autoJoinGroups,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                          autoJoinGroups: value,
                        );
                      });
                    },
                    disabled: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.yellow.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Auto-join feature will automatically match you with groups that fit your preferences. Launching soon!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _savePreferences,
            style: ElevatedButton.styleFrom(
              backgroundColor: HoopTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Save Community Settings'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isSaving ? null : _resetPreferences,
            style: OutlinedButton.styleFrom(
              foregroundColor: HoopTheme.getTextPrimary(
                Theme.of(context).brightness == Brightness.dark,
              ),
              side: BorderSide(
                color: HoopTheme.getBorderColor(
                  Theme.of(context).brightness == Brightness.dark,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Reset to Defaults'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildLoadingState(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildGlobalDiscoverySection(),
                  const SizedBox(height: 24),
                  _buildGroupPreferencesSection(),
                  const SizedBox(height: 24),
                  _buildNotificationsSection(),
                  const SizedBox(height: 24),
                  _buildAutoJoinSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}