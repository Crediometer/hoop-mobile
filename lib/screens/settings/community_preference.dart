import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/back_button.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/dtos/responses/group/index.dart';
import 'package:hoop/states/group_state.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final provider = context.read<GroupCommunityProvider>();

    // Only load if not already loaded
    if (provider.communityPreferences == null &&
        !provider.isLoadingPreferences) {
      await provider.loadCommunityPreferences();
    }

    if (mounted) {
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

    final provider = context.read<GroupCommunityProvider>();
    final preferences = provider.communityPreferences;

    if (preferences == null) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    try {
      // Get updated values from current preferences
      await provider.updateCommunityPreferences({
        'goGlobal': preferences.goGlobal,
        'distanceRadius': preferences.distanceRadius,
        'preferredGroupSize': preferences.preferredGroupSize,
        'contributionMin': preferences.contributionMin,
        'contributionMax': preferences.contributionMax,
        'totalPotMin': preferences.totalPotMin,
        'totalPotMax': preferences.totalPotMax,
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
    final provider = context.read<GroupCommunityProvider>();

    try {
      await provider.resetCommunityPreferences();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences reset to defaults'),
          backgroundColor: HoopTheme.successGreen,
          duration: Duration(seconds: 2),
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
                  CustomSwitch(
                    value: preferences.goGlobal ?? true,
                    onChanged: (value) {
                      context
                          .read<GroupCommunityProvider>()
                          .updateCommunityPreferences({
                            ...preferences.toJson(),
                            'goGlobal': value,
                          });
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
                          '${preferences.distanceRadius ?? 25} km',
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
                      value: (preferences.distanceRadius ?? 25).toDouble(),
                      onChanged: (value) {
                        context
                            .read<GroupCommunityProvider>()
                            .updateCommunityPreferences({
                              ...preferences.toJson(),
                              'distanceRadius': value.round(),
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
                            context
                                .read<GroupCommunityProvider>()
                                .updateCommunityPreferences({
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
                        '${formatCurrency(preferences.contributionMin)} - ${formatCurrency(preferences.contributionMax)}',
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
                                  Theme.of(context).brightness ==
                                      Brightness.dark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: HoopTheme.getBorderColor(
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: TextField(
                                controller: TextEditingController(
                                  text:
                                      (preferences.contributionMin?.toInt() ??
                                              5000)
                                          .toString(),
                                ),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration.collapsed(
                                  hintText: '',
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: HoopTheme.getTextPrimary(
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    final intValue =
                                        int.tryParse(value) ?? 5000;
                                    context
                                        .read<GroupCommunityProvider>()
                                        .updateCommunityPreferences({
                                          ...preferences.toJson(),
                                          'contributionMin': intValue,
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
                                  Theme.of(context).brightness ==
                                      Brightness.dark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: HoopTheme.getBorderColor(
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: TextField(
                                controller: TextEditingController(
                                  text:
                                      (preferences.contributionMax?.toInt() ??
                                              50000)
                                          .toString(),
                                ),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration.collapsed(
                                  hintText: '',
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: HoopTheme.getTextPrimary(
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    final intValue =
                                        int.tryParse(value) ?? 50000;
                                    context
                                        .read<GroupCommunityProvider>()
                                        .updateCommunityPreferences({
                                          ...preferences.toJson(),
                                          'contributionMax': intValue,
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
                        '${formatCurrency(preferences.totalPotMin)} - ${formatCurrency(preferences.totalPotMax)}',
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
                                  Theme.of(context).brightness ==
                                      Brightness.dark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: HoopTheme.getBorderColor(
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: TextField(
                                controller: TextEditingController(
                                  text:
                                      (preferences.totalPotMin?.toInt() ??
                                              50000)
                                          .toString(),
                                ),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration.collapsed(
                                  hintText: '',
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: HoopTheme.getTextPrimary(
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    final intValue =
                                        int.tryParse(value) ?? 50000;
                                    context
                                        .read<GroupCommunityProvider>()
                                        .updateCommunityPreferences({
                                          ...preferences.toJson(),
                                          'totalPotMin': intValue,
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
                                  Theme.of(context).brightness ==
                                      Brightness.dark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: HoopTheme.getBorderColor(
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: TextField(
                                controller: TextEditingController(
                                  text:
                                      (preferences.totalPotMax?.toInt() ??
                                              500000)
                                          .toString(),
                                ),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration.collapsed(
                                  hintText: '',
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: HoopTheme.getTextPrimary(
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    final intValue =
                                        int.tryParse(value) ?? 500000;
                                    context
                                        .read<GroupCommunityProvider>()
                                        .updateCommunityPreferences({
                                          ...preferences.toJson(),
                                          'totalPotMax': intValue,
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

  Widget _buildNotificationsSection(CommunityPreferences preferences) {
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
                    value: preferences.groupRecommendations ?? true,
                    onChanged: (value) {
                      context
                          .read<GroupCommunityProvider>()
                          .updateCommunityPreferences({
                            ...preferences.toJson(),
                            'groupRecommendations': value,
                          });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

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
                    value: preferences.nearbyAlerts ?? true,
                    onChanged: (value) {
                      context
                          .read<GroupCommunityProvider>()
                          .updateCommunityPreferences({
                            ...preferences.toJson(),
                            'nearbyAlerts': value,
                          });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

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
                    value: preferences.communityNotifications ?? true,
                    onChanged: (value) {
                      context
                          .read<GroupCommunityProvider>()
                          .updateCommunityPreferences({
                            ...preferences.toJson(),
                            'communityNotifications': value,
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

  Widget _buildAutoJoinSection(CommunityPreferences preferences) {
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
                    value: preferences.autoJoinGroups ?? false,
                    onChanged: (value) {
                      context
                          .read<GroupCommunityProvider>()
                          .updateCommunityPreferences({
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
