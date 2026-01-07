import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/back_button.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/dtos/responses/group/index.dart';
import 'package:hoop/states/group_state.dart';
import 'package:hoop/utils/helpers/formatters/hoop_formatter.dart';
import 'package:provider/provider.dart';

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
            overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
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
            onChangeEnd: widget.onChanged,
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

class CommunitySettingsScreen extends StatefulWidget {
  const CommunitySettingsScreen({Key? key}) : super(key: key);

  @override
  State<CommunitySettingsScreen> createState() =>
      _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends State<CommunitySettingsScreen> {
  bool _isSaving = false;
  bool _initialLoadComplete = false;
  
  // Text editing controllers to prevent focus loss
  final TextEditingController _contributionMinController = TextEditingController();
  final TextEditingController _contributionMaxController = TextEditingController();
  final TextEditingController _totalPotMinController = TextEditingController();
  final TextEditingController _totalPotMaxController = TextEditingController();
  
  // Slider state
  double _distanceRadiusValue = 25.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreferences();
    });
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _contributionMinController.dispose();
    _contributionMaxController.dispose();
    _totalPotMinController.dispose();
    _totalPotMaxController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final provider = Provider.of<GroupCommunityProvider>(context, listen: false);

    if (provider.communityPreferences == null &&
        !provider.isLoadingPreferences) {
      await provider.loadCommunityPreferences();
    }

    if (mounted) {
      final preferences = provider.communityPreferences;
      if (preferences != null) {
        // Initialize controllers with current values
        _contributionMinController.text = (preferences.contributionMin ?? 5000).toString();
        _contributionMaxController.text = (preferences.contributionMax ?? 50000).toString();
        _totalPotMinController.text = (preferences.totalPotMin ?? 50000).toString();
        _totalPotMaxController.text = (preferences.totalPotMax ?? 500000).toString();
        _distanceRadiusValue = (preferences.distanceRadius ?? 25).toDouble();
      }
      
      setState(() {
        _initialLoadComplete = true;
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<GroupCommunityProvider>(context, listen: false);
    final preferences = provider.communityPreferences;

    if (preferences == null) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    try {
      // Parse text field values
      final contributionMin = int.tryParse(_contributionMinController.text) ?? 5000;
      final contributionMax = int.tryParse(_contributionMaxController.text) ?? 50000;
      final totalPotMin = int.tryParse(_totalPotMinController.text) ?? 50000;
      final totalPotMax = int.tryParse(_totalPotMaxController.text) ?? 500000;

      await provider.updateCommunityPreferences({
        'goGlobal': preferences.goGlobal,
        'distanceRadius': _distanceRadiusValue.round(),
        'preferredGroupSize': preferences.preferredGroupSize,
        'contributionMin': contributionMin,
        'contributionMax': contributionMax,
        'totalPotMin': totalPotMin,
        'totalPotMax': totalPotMax,
        'groupRecommendations': preferences.groupRecommendations,
        'nearbyAlerts': preferences.nearbyAlerts,
        'communityNotifications': preferences.communityNotifications,
        'autoJoinGroups': preferences.autoJoinGroups,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Community preferences saved successfully'),
          backgroundColor: HoopTheme.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save preferences: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _resetPreferences() async {
    final provider = Provider.of<GroupCommunityProvider>(context, listen: false);

    try {
      await provider.resetCommunityPreferences();
      
      // Reset controllers to default values
      _contributionMinController.text = '5000';
      _contributionMaxController.text = '50000';
      _totalPotMinController.text = '50000';
      _totalPotMaxController.text = '500000';
      _distanceRadiusValue = 25.0;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences reset to defaults'),
          backgroundColor: HoopTheme.successGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset preferences: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          const HoopBackButton(),
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

  Widget _buildGlobalDiscoverySection(CommunityPreferences preferences) {
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
                  Consumer<GroupCommunityProvider>(
                    builder: (context, provider, child) {
                      return CustomSwitch(
                        value: preferences.goGlobal ?? true,
                        onChanged: (value) {
                          provider.updateCommunityPreferences({
                            ...preferences.toJson(),
                            'goGlobal': value,
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
              if (!(preferences.goGlobal ?? true)) ...[
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
                          '${_distanceRadiusValue.round()} km',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: HoopTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Consumer<GroupCommunityProvider>(
                      builder: (context, provider, child) {
                        return CustomSlider(
                          value: _distanceRadiusValue,
                          onChanged: (value) {
                            setState(() {
                              _distanceRadiusValue = value;
                            });
                            provider.updateCommunityPreferences({
                              ...preferences.toJson(),
                              'distanceRadius': value.round(),
                            });
                          },
                          min: 5,
                          max: 100,
                          step: 5,
                        );
                      },
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

  Widget _buildGroupPreferencesSection(CommunityPreferences preferences) {
    final groupSizes = {
      'SMALL': 'Small (5-10 members)',
      'MEDIUM': 'Medium (11-25 members)',
      'LARGE': 'Large (26-50 members)',
      'XLARGE': 'X-Large (51-100 members)',
    };

    String formatCurrency(dynamic amount) {
      final value = amount is num ? amount.toInt() : 0;
      return '₦${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }

    return Consumer<GroupCommunityProvider>(
      builder: (context, provider, child) {
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
                            value:
                                preferences.preferredGroupSize?.toString() ??
                                    'MEDIUM',
                            isExpanded: true,
                            items: groupSizes.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: HoopTheme.getTextPrimary(
                                      Theme.of(context).brightness ==
                                          Brightness.dark,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                provider.updateCommunityPreferences({
                                  ...preferences.toJson(),
                                  'preferredGroupSize': value,
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildRangeInputSection(
                    context: context,
                    title: 'Contribution Range',
                    minController: _contributionMinController,
                    maxController: _contributionMaxController,
                    currentMin: preferences.contributionMin?.toInt() ?? 5000,
                    currentMax: preferences.contributionMax?.toInt() ?? 50000,
                    formatValue: formatCurrency,
                    onChanged: (min, max) {
                      provider.updateCommunityPreferences({
                        ...preferences.toJson(),
                        'contributionMin': min,
                        'contributionMax': max,
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildRangeInputSection(
                    context: context,
                    title: 'Total Pot Range',
                    minController: _totalPotMinController,
                    maxController: _totalPotMaxController,
                    currentMin: preferences.totalPotMin?.toInt() ?? 50000,
                    currentMax: preferences.totalPotMax?.toInt() ?? 500000,
                    formatValue: formatCurrency,
                    onChanged: (min, max) {
                      provider.updateCommunityPreferences({
                        ...preferences.toJson(),
                        'totalPotMin': min,
                        'totalPotMax': max,
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRangeInputSection({
    required BuildContext context,
    required String title,
    required TextEditingController minController,
    required TextEditingController maxController,
    required int currentMin,
    required int currentMax,
    required String Function(dynamic) formatValue,
    required Function(int, int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: HoopTheme.getTextPrimary(
                  Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ),
            Text(
              '${HoopFormatters.formatCurrency(currentMin.toDouble())} - ${HoopFormatters.formatCurrency(currentMax.toDouble())}',
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
              child: _buildRangeInputField(
                context: context,
                label: 'Minimum',
                controller: minController,
                onChanged: (value) {
                  final intValue = int.tryParse(value) ?? currentMin;
                  final maxValue = int.tryParse(maxController.text) ?? currentMax;
                  onChanged(intValue, maxValue);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRangeInputField(
                context: context,
                label: 'Maximum',
                controller: maxController,
                onChanged: (value) {
                  final intValue = int.tryParse(value) ?? currentMax;
                  final minValue = int.tryParse(minController.text) ?? currentMin;
                  onChanged(minValue, intValue);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRangeInputField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
            controller: controller,
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
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(CommunityPreferences preferences) {
    return Consumer<GroupCommunityProvider>(
      builder: (context, provider, child) {
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
                  _buildNotificationRow(
                    context: context,
                    title: 'Group Recommendations',
                    subtitle: 'New group suggestions',
                    icon: Icons.people,
                    iconColor: HoopTheme.primaryBlue,
                    value: preferences.groupRecommendations ?? true,
                    onChanged: (value) {
                      provider.updateCommunityPreferences({
                        ...preferences.toJson(),
                        'groupRecommendations': value,
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationRow(
                    context: context,
                    title: 'Nearby Alerts',
                    subtitle: 'New groups in your area',
                    icon: Icons.notifications,
                    iconColor: HoopTheme.successGreen,
                    value: preferences.nearbyAlerts ?? true,
                    onChanged: (value) {
                      provider.updateCommunityPreferences({
                        ...preferences.toJson(),
                        'nearbyAlerts': value,
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationRow(
                    context: context,
                    title: 'Community Updates',
                    subtitle: 'Feature updates and news',
                    icon: Icons.notifications_active,
                    iconColor: HoopTheme.vibrantOrange,
                    value: preferences.communityNotifications ?? true,
                    onChanged: (value) {
                      provider.updateCommunityPreferences({
                        ...preferences.toJson(),
                        'communityNotifications': value,
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationRow({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: HoopTheme.getTextPrimary(
                      Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),
                Text(
                  subtitle,
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
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildAutoJoinSection(CommunityPreferences preferences) {
    return Consumer<GroupCommunityProvider>(
      builder: (context, provider, child) {
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
                              Icons.my_location,
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
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ),
                                ),
                              ),
                              Text(
                                'Coming soon',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: HoopTheme.getTextSecondary(
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      CustomSwitch(
                        value: preferences.autoJoinGroups ?? false,
                        onChanged: (value) {
                          provider.updateCommunityPreferences({
                            ...preferences.toJson(),
                            'autoJoinGroups': value,
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
                      border: Border.all(color: Colors.yellow.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Auto-join feature will automatically match you with groups that fit your preferences. Launching soon!',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
                : const Text('Save Community Settings'),
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
            child: const Text('Reset to Defaults'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupCommunityProvider>();

    // Show loading if still loading or initial load not complete
    if (provider.isLoadingPreferences ||
        (!_initialLoadComplete && provider.communityPreferences == null)) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildLoadingState()),
            ],
          ),
        ),
      );
    }

    final preferences = provider.communityPreferences;

    // Show empty state if no preferences (shouldn't happen, but just in case)
    if (preferences == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Text(
                    'Unable to load preferences',
                    style: TextStyle(
                      color: HoopTheme.getTextSecondary(
                        Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildGlobalDiscoverySection(preferences),
                    const SizedBox(height: 24),
                    _buildGroupPreferencesSection(preferences),
                    const SizedBox(height: 24),
                    _buildNotificationsSection(preferences),
                    const SizedBox(height: 24),
                    _buildAutoJoinSection(preferences),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
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