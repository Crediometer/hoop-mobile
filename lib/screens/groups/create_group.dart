import 'package:flutter/material.dart';
import 'package:hoop/constants/themes.dart';

// ============================================
// DTOs and Models
// ============================================

class GroupFormData {
  String name;
  String description;
  String contributionAmount;
  String cycleDuration;
  String cycleUnit;
  String customCycleValue;
  String customCycleUnit;
  String maxMembers;
  String adminSlots;
  String payoutOrder;
  bool isPrivate;
  bool requireApproval;
  bool allowPairing;
  String startDate;

  GroupFormData({
    this.name = "",
    this.description = "",
    this.contributionAmount = "",
    this.cycleDuration = "",
    this.cycleUnit = "days",
    this.customCycleValue = "",
    this.customCycleUnit = "days",
    this.maxMembers = "",
    this.adminSlots = "1",
    this.payoutOrder = "join-date",
    this.isPrivate = false,
    this.requireApproval = true,
    this.allowPairing = false,
    String? startDate,
  }) : startDate = startDate ?? DateTime.now().toIso8601String().split('T')[0];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'contributionAmount': contributionAmount,
      'cycleDuration': cycleDuration,
      'cycleUnit': cycleUnit,
      'customCycleValue': customCycleValue,
      'customCycleUnit': customCycleUnit,
      'maxMembers': maxMembers,
      'adminSlots': adminSlots,
      'payoutOrder': payoutOrder,
      'isPrivate': isPrivate,
      'requireApproval': requireApproval,
      'allowPairing': allowPairing,
      'startDate': startDate,
    };
  }

  GroupFormData copyWith({
    String? name,
    String? description,
    String? contributionAmount,
    String? cycleDuration,
    String? cycleUnit,
    String? customCycleValue,
    String? customCycleUnit,
    String? maxMembers,
    String? adminSlots,
    String? payoutOrder,
    bool? isPrivate,
    bool? requireApproval,
    bool? allowPairing,
    String? startDate,
  }) {
    return GroupFormData(
      name: name ?? this.name,
      description: description ?? this.description,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      cycleDuration: cycleDuration ?? this.cycleDuration,
      cycleUnit: cycleUnit ?? this.cycleUnit,
      customCycleValue: customCycleValue ?? this.customCycleValue,
      customCycleUnit: customCycleUnit ?? this.customCycleUnit,
      maxMembers: maxMembers ?? this.maxMembers,
      adminSlots: adminSlots ?? this.adminSlots,
      payoutOrder: payoutOrder ?? this.payoutOrder,
      isPrivate: isPrivate ?? this.isPrivate,
      requireApproval: requireApproval ?? this.requireApproval,
      allowPairing: allowPairing ?? this.allowPairing,
      startDate: startDate ?? this.startDate,
    );
  }
}

class CycleDuration {
  final String value;
  final String label;
  final String unit;

  CycleDuration({
    required this.value,
    required this.label,
    required this.unit,
  });
}

class CustomCycleUnit {
  final String value;
  final String label;

  CustomCycleUnit({
    required this.value,
    required this.label,
  });
}

class PayoutOrderOption {
  final String value;
  final String label;
  final String description;

  PayoutOrderOption({
    required this.value,
    required this.label,
    required this.description,
  });
}

// ============================================
// Custom Switch Widget
// ============================================

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

// ============================================
// Custom Input Field with Icon
// ============================================

class CustomInputField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onBlur;
  final String? error;
  final bool touched;
  final String hintText;
  final IconData? icon;
  final TextInputType keyboardType;
  final bool isRequired;
  final String? helperText;
  final int maxLength;
  final bool showCharCount;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomInputField({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onBlur,
    this.error,
    this.touched = false,
    this.hintText = '',
    this.icon,
    this.keyboardType = TextInputType.text,
    this.isRequired = false,
    this.helperText,
    this.maxLength = 100,
    this.showCharCount = false,
    this.readOnly = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant CustomInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.error != null && widget.touched;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: HoopTheme.getTextPrimary(isDark),
              ),
            ),
            if (widget.showCharCount)
              Text(
                '${_controller.text.length}/${widget.maxLength}',
                style: TextStyle(
                  fontSize: 12,
                  color: _controller.text.length > widget.maxLength
                      ? Colors.red
                      : HoopTheme.getTextSecondary(isDark),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? Colors.red
                  : HoopTheme.getBorderColor(isDark),
            ),
          ),
          child: Stack(
            children: [
              TextField(
                controller: _controller,
                onChanged: (value) {
                  if (value.length <= widget.maxLength) {
                    widget.onChanged(value);
                  }
                },
                onTap: widget.onTap,
                readOnly: widget.readOnly,
                keyboardType: widget.keyboardType,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(
                    left: widget.icon != null ? 40 : 12,
                    right: 12,
                    top: 12,
                    bottom: 12,
                  ),
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: HoopTheme.getTextPrimary(isDark),
                ),
              ),
              if (widget.icon != null)
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: HoopTheme.getTextSecondary(isDark),
                  ),
                ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.error!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        if (widget.helperText != null && !hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.helperText!,
              style: TextStyle(
                fontSize: 12,
                color: HoopTheme.getTextSecondary(isDark),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================
// Custom Text Area Field
// ============================================

class CustomTextAreaField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onBlur;
  final String? error;
  final bool touched;
  final String hintText;
  final int maxLines;
  final int maxLength;
  final bool showCharCount;

  const CustomTextAreaField({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onBlur,
    this.error,
    this.touched = false,
    this.hintText = '',
    this.maxLines = 4,
    this.maxLength = 200,
    this.showCharCount = true,
  }) : super(key: key);

  @override
  State<CustomTextAreaField> createState() => _CustomTextAreaFieldState();
}

class _CustomTextAreaFieldState extends State<CustomTextAreaField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant CustomTextAreaField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.error != null && widget.touched;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: HoopTheme.getTextPrimary(isDark),
              ),
            ),
            if (widget.showCharCount)
              Text(
                '${_controller.text.length}/${widget.maxLength}',
                style: TextStyle(
                  fontSize: 12,
                  color: _controller.text.length > widget.maxLength
                      ? Colors.red
                      : HoopTheme.getTextSecondary(isDark),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? Colors.red
                  : HoopTheme.getBorderColor(isDark),
            ),
          ),
          child: TextField(
            controller: _controller,
            onChanged: (value) {
              if (value.length <= widget.maxLength) {
                widget.onChanged(value);
              }
            },
            maxLines: widget.maxLines,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              isDense: true,
            ),
            style: TextStyle(
              fontSize: 14,
              color: HoopTheme.getTextPrimary(isDark),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.error!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================
// Validation Functions
// ============================================

class GroupFormValidators {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Group name is required";
    }
    if (value.trim().length < 3) {
      return "Group name must be at least 3 characters";
    }
    if (value.trim().length > 50) {
      return "Group name must be less than 50 characters";
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Description is required";
    }
    if (value.trim().length < 10) {
      return "Description must be at least 10 characters";
    }
    if (value.trim().length > 200) {
      return "Description must be less than 200 characters";
    }
    return null;
  }

  static String? validateContributionAmount(String? value) {
    if (value == null || value.isEmpty) {
      return "Contribution amount is required";
    }
    final numAmount = int.tryParse(value);
    if (numAmount == null) {
      return "Contribution must be a valid number";
    }
    if (numAmount < 100) {
      return "Contribution must be at least ₦100";
    }
    if (numAmount > 1000000) {
      return "Contribution must be less than ₦1,000,000";
    }
    return null;
  }

  static String? validateMaxMembers(String? value) {
    if (value == null || value.isEmpty) {
      return "Number of slots is required";
    }
    final numMembers = int.tryParse(value);
    if (numMembers == null) {
      return "Number of slots must be a valid number";
    }
    if (numMembers < 2) {
      return "Must have at least 2 members";
    }
    if (numMembers > 50) {
      return "Cannot exceed 50 members";
    }
    return null;
  }

  static String? validateAdminSlots(
    String? value,
    bool allowPairing,
    String maxMembers,
  ) {
    if (value == null || value.isEmpty) {
      return "Your slots is required";
    }

    final numSlots = double.tryParse(value);
    if (numSlots == null) {
      return "Your slots must be a valid number";
    }

    final max = int.tryParse(maxMembers) ?? 0;

    if (allowPairing) {
      if (numSlots < 0.5) {
        return "Minimum is 0.5 when pairing";
      }
      // Check if it's a valid 0.5 increment
      if ((numSlots * 2).roundToDouble() != numSlots * 2) {
        return "Use steps of 0.5 when pairing (e.g., 0.5, 1, 1.5, 2)";
      }
    } else {
      // When pairing is disabled, must be whole number
      if (numSlots % 1 != 0) {
        return "Must be a whole number when pairing is off";
      }
      if (numSlots < 1) {
        return "Minimum is 1";
      }
    }

    if (max > 0 && numSlots > max) {
      return "Cannot exceed total slots";
    }
    return null;
  }

  static String? validateStartDate(String? value) {
    if (value == null || value.isEmpty) {
      return "Start date is required";
    }

    try {
      final selectedDate = DateTime.parse(value);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final selectedDateOnly = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      if (selectedDateOnly.isBefore(todayDate)) {
        return "Start date cannot be in the past";
      }

      final oneYearFromNow = DateTime(
        today.year + 1,
        today.month,
        today.day,
      );
      if (selectedDateOnly.isAfter(oneYearFromNow)) {
        return "Start date cannot be more than 1 year in the future";
      }

      return null;
    } catch (e) {
      return "Invalid date format";
    }
  }

  static String? validateCycleDuration(
    String? value,
    bool useCustomCycle,
  ) {
    if (!useCustomCycle && (value == null || value.isEmpty)) {
      return "Cycle duration is required";
    }
    return null;
  }

  static String? validateCustomCycle(String? value) {
    if (value == null || value.isEmpty) {
      return "Custom cycle duration is required";
    }
    final numValue = int.tryParse(value);
    if (numValue == null) {
      return "Cycle duration must be a valid number";
    }
    if (numValue < 1) {
      return "Cycle duration must be at least 1";
    }
    if (numValue > 365) {
      return "Cycle duration cannot exceed 365 days";
    }
    return null;
  }
}

// ============================================
// Main Group Creation Flow Screen
// ============================================

class GroupCreationFlowScreen extends StatefulWidget {
  const GroupCreationFlowScreen({Key? key}) : super(key: key);

  @override
  State<GroupCreationFlowScreen> createState() => _GroupCreationFlowScreenState();
}

class _GroupCreationFlowScreenState extends State<GroupCreationFlowScreen> {
  int _currentStep = 1;
  final int _totalSteps = 3;
  
  late GroupFormData _formData;
  final Map<String, String?> _errors = {};
  final Set<String> _touchedFields = {};
  bool _isCreating = false;
  bool _useCustomCycle = false;
  
  // Data for dropdowns
  final List<CycleDuration> _predefinedCycleDurations = [
    CycleDuration(value: "1", label: "Daily", unit: "days"),
    CycleDuration(value: "2", label: "Every 2 days", unit: "days"),
    CycleDuration(value: "3", label: "Every 3 days", unit: "days"),
    CycleDuration(value: "5", label: "Every 5 days", unit: "days"),
    CycleDuration(value: "7", label: "Weekly", unit: "days"),
    CycleDuration(value: "14", label: "Bi-weekly", unit: "days"),
    CycleDuration(value: "21", label: "Every 3 weeks", unit: "days"),
    CycleDuration(value: "30", label: "Monthly", unit: "days"),
    CycleDuration(value: "60", label: "Every 2 months", unit: "days"),
    CycleDuration(value: "90", label: "Quarterly", unit: "days"),
  ];
  
  final List<CustomCycleUnit> _customCycleUnits = [
    CustomCycleUnit(value: "days", label: "Days"),
    CustomCycleUnit(value: "weeks", label: "Weeks"),
    CustomCycleUnit(value: "months", label: "Months"),
  ];
  
  final List<PayoutOrderOption> _payoutOrderOptions = [
    PayoutOrderOption(
      value: "join-date",
      label: "Join Date",
      description: "First to join, first to receive",
    ),
    PayoutOrderOption(
      value: "random",
      label: "Random",
      description: "Fair lottery system",
    ),
    PayoutOrderOption(
      value: "assignment",
      label: "Admin Assignment",
      description: "Admin create the slot order for members",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _formData = GroupFormData();
  }

  // Handle pairing changes
  @override
  void didUpdateWidget(covariant GroupCreationFlowScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // When pairing is disabled and current value has decimal, reset to whole number
    if (!_formData.allowPairing && _formData.adminSlots.isNotEmpty) {
      final currentValue = double.tryParse(_formData.adminSlots);
      if (currentValue != null && currentValue % 1 != 0) {
        _updateFormData(adminSlots: currentValue.round().toString());
      }
    }
    
    // When pairing is enabled and value is less than 0.5, set to minimum
    if (_formData.allowPairing && _formData.adminSlots.isNotEmpty) {
      final currentValue = double.tryParse(_formData.adminSlots);
      if (currentValue != null && currentValue < 0.5) {
        _updateFormData(adminSlots: '0.5');
      }
    }
  }

  void _updateFormData({
    String? name,
    String? description,
    String? contributionAmount,
    String? cycleDuration,
    String? cycleUnit,
    String? customCycleValue,
    String? customCycleUnit,
    String? maxMembers,
    String? adminSlots,
    String? payoutOrder,
    bool? isPrivate,
    bool? requireApproval,
    bool? allowPairing,
    String? startDate,
  }) {
    setState(() {
      _formData = _formData.copyWith(
        name: name,
        description: description,
        contributionAmount: contributionAmount,
        cycleDuration: cycleDuration,
        cycleUnit: cycleUnit,
        customCycleValue: customCycleValue,
        customCycleUnit: customCycleUnit,
        maxMembers: maxMembers,
        adminSlots: adminSlots,
        payoutOrder: payoutOrder,
        isPrivate: isPrivate,
        requireApproval: requireApproval,
        allowPairing: allowPairing,
        startDate: startDate,
      );

      // Clear errors for updated fields
      if (name != null) _errors.remove('name');
      if (description != null) _errors.remove('description');
      if (contributionAmount != null) _errors.remove('contributionAmount');
      if (cycleDuration != null) _errors.remove('cycleDuration');
      if (customCycleValue != null) _errors.remove('customCycleValue');
      if (maxMembers != null) _errors.remove('maxMembers');
      if (adminSlots != null) _errors.remove('adminSlots');
      if (startDate != null) _errors.remove('startDate');
    });
  }

  void _markFieldTouched(String field) {
    setState(() {
      _touchedFields.add(field);
    });
  }

  void _validateField(String field, String value) {
    String? error;

    switch (field) {
      case 'name':
        error = GroupFormValidators.validateName(value);
        break;
      case 'description':
        error = GroupFormValidators.validateDescription(value);
        break;
      case 'contributionAmount':
        error = GroupFormValidators.validateContributionAmount(value);
        break;
      case 'maxMembers':
        error = GroupFormValidators.validateMaxMembers(value);
        break;
      case 'adminSlots':
        error = GroupFormValidators.validateAdminSlots(
          value,
          _formData.allowPairing,
          _formData.maxMembers,
        );
        break;
      case 'startDate':
        error = GroupFormValidators.validateStartDate(value);
        break;
      case 'cycleDuration':
        error = GroupFormValidators.validateCycleDuration(value, _useCustomCycle);
        break;
      case 'customCycleValue':
        error = GroupFormValidators.validateCustomCycle(value);
        break;
    }

    setState(() {
      if (error != null) {
        _errors[field] = error;
      } else {
        _errors.remove(field);
      }
    });
  }

  Map<String, String?> _getStepErrors(int step) {
    final errors = <String, String?>{};

    if (step == 1) {
      errors['name'] = GroupFormValidators.validateName(_formData.name);
      errors['description'] = GroupFormValidators.validateDescription(_formData.description);
      errors['contributionAmount'] = GroupFormValidators.validateContributionAmount(_formData.contributionAmount);
      errors['maxMembers'] = GroupFormValidators.validateMaxMembers(_formData.maxMembers);
      errors['adminSlots'] = GroupFormValidators.validateAdminSlots(
        _formData.adminSlots,
        _formData.allowPairing,
        _formData.maxMembers,
      );
      errors['startDate'] = GroupFormValidators.validateStartDate(_formData.startDate);
      errors['cycleDuration'] = GroupFormValidators.validateCycleDuration(
        _formData.cycleDuration,
        _useCustomCycle,
      );
      if (_useCustomCycle) {
        errors['customCycleValue'] = GroupFormValidators.validateCustomCycle(_formData.customCycleValue);
      }

      // Remove null errors
      errors.removeWhere((key, value) => value == null);
    }

    return errors;
  }

  bool _validateStep(int step) {
    final stepErrors = _getStepErrors(step);
    setState(() {
      _errors.clear();
      _errors.addAll(stepErrors);
    });
    return stepErrors.isEmpty;
  }

  bool _isStepValid(int step) {
    return _getStepErrors(step).isEmpty;
  }

  void _handleNext() {
    // Mark all step fields as touched
    final stepFields = [
      'name',
      'description',
      'contributionAmount',
      'maxMembers',
      'startDate',
      'cycleDuration',
      if (_useCustomCycle) 'customCycleValue',
    ];

    for (final field in stepFields) {
      _markFieldTouched(field);
    }

    if (_validateStep(_currentStep)) {
      if (_currentStep < _totalSteps) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  void _handlePrevious() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  String _formatCycleDuration() {
    if (_useCustomCycle) {
      return '${_formData.customCycleValue} ${_formData.customCycleUnit}';
    } else {
      final predefined = _predefinedCycleDurations.firstWhere(
        (cycle) => cycle.value == _formData.cycleDuration,
        orElse: () => CycleDuration(value: '', label: _formData.cycleDuration, unit: 'days'),
      );
      return predefined.label;
    }
  }

  String _getCycleDurationForAPI() {
    if (_useCustomCycle) {
      return '${_formData.customCycleValue} ${_formData.customCycleUnit}';
    } else {
      final predefined = _predefinedCycleDurations.firstWhere(
        (cycle) => cycle.value == _formData.cycleDuration,
        orElse: () => CycleDuration(value: '', label: '', unit: 'days'),
      );
      return '${predefined.value} ${predefined.unit}';
    }
  }

  Future<void> _handleCreateGroup() async {
    // Validate all steps before creating
    if (!_validateStep(1)) {
      setState(() {
        _currentStep = 1;
      });
      return;
    }

    try {
      setState(() {
        _isCreating = true;
      });

      // TODO: Replace with actual API call
      // final payload = {
      //   'name': _formData.name,
      //   'description': _formData.description,
      //   'contributionAmount': int.parse(_formData.contributionAmount),
      //   'cycleDuration': _getCycleDurationForAPI(),
      //   'maxMembers': int.parse(_formData.maxMembers),
      //   'adminSlots': double.parse(_formData.adminSlots),
      //   'payoutOrder': _formData.payoutOrder,
      //   'isPrivate': _formData.isPrivate,
      //   'requireApproval': _formData.requireApproval,
      //   'allowPairing': _formData.allowPairing,
      //   'startDate': _formData.startDate,
      // };
      // 
      // final response = await yourApiService.createGroup(payload);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group created successfully!'),
          backgroundColor: HoopTheme.successGreen,
        ),
      );

      // Navigate back
      Navigator.of(context).pop();

    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create group: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (index) {
        final step = index + 1;
        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: step < _currentStep
                    ? HoopTheme.successGreen
                    : step == _currentStep
                        ? HoopTheme.primaryBlue
                        : HoopTheme.getMutedColor(
                            Theme.of(context).brightness == Brightness.dark,
                          ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: step < _currentStep
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : Text(
                        '$step',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
            if (step < _totalSteps)
              Container(
                width: 32,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: step < _currentStep
                    ? HoopTheme.successGreen
                    : HoopTheme.getMutedColor(
                        Theme.of(context).brightness == Brightness.dark,
                      ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        border: Border(
          bottom: BorderSide(
            color: HoopTheme.getBorderColor(
              Theme.of(context).brightness == Brightness.dark,
            ).withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _currentStep == 1
                    ? () => Navigator.of(context).pop()
                    : _handlePrevious,
                icon: Icon(
                  Icons.arrow_back,
                  color: HoopTheme.getTextPrimary(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: HoopTheme.getMutedColor(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    'Create Group',
                    style: TextStyle(
                      color: HoopTheme.primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Step $_currentStep of $_totalSteps',
                    style: TextStyle(
                      fontSize: 12,
                      color: HoopTheme.getTextSecondary(
                        Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 48), // Spacer for symmetry
            ],
          ),
          const SizedBox(height: 16),
          _buildStepIndicator(),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text(
                  'Basic Information',
                  style: TextStyle(
                    color: HoopTheme.primaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us about your thrift group',
                  style: TextStyle(
                    color: HoopTheme.getTextSecondary(isDark),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Form Fields
          Column(
            children: [
              CustomInputField(
                label: 'Group Name',
                value: _formData.name,
                onChanged: (value) => _updateFormData(name: value),
                onBlur: (value) {
                  _markFieldTouched('name');
                  _validateField('name', value);
                },
                error: _errors['name'],
                touched: _touchedFields.contains('name'),
                hintText: 'e.g. Fashion Forward Circle',
              ),
              const SizedBox(height: 16),

              CustomTextAreaField(
                label: 'Description',
                value: _formData.description,
                onChanged: (value) => _updateFormData(description: value),
                onBlur: (value) {
                  _markFieldTouched('description');
                  _validateField('description', value);
                },
                error: _errors['description'],
                touched: _touchedFields.contains('description'),
                hintText: 'Describe what your group is about, what you\'ll be buying together, and who should join...',
                maxLength: 200,
              ),
              const SizedBox(height: 16),

              CustomInputField(
                label: 'Start Date',
                value: _formData.startDate,
                onChanged: (value) => _updateFormData(startDate: value),
                onBlur: (value) {
                  _markFieldTouched('startDate');
                  _validateField('startDate', value);
                },
                error: _errors['startDate'],
                touched: _touchedFields.contains('startDate'),
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (selectedDate != null) {
                    _updateFormData(
                      startDate: selectedDate.toIso8601String().split('T')[0],
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              CustomInputField(
                label: 'Number Of Slots',
                value: _formData.maxMembers,
                onChanged: (value) => _updateFormData(maxMembers: value),
                onBlur: (value) {
                  _markFieldTouched('maxMembers');
                  _validateField('maxMembers', value);
                },
                error: _errors['maxMembers'],
                touched: _touchedFields.contains('maxMembers'),
                icon: Icons.people,
                hintText: '20',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Allow Pairing Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: HoopTheme.getBorderColor(isDark).withOpacity(0.1),
                  ),
                ),
                child: Row(
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
                              'Allow Pairing',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: HoopTheme.getTextPrimary(isDark),
                              ),
                            ),
                            Text(
                              'Members can take half-slots (0.5, 1.5, etc.)',
                              style: TextStyle(
                                fontSize: 12,
                                color: HoopTheme.getTextSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    CustomSwitch(
                      value: _formData.allowPairing,
                      onChanged: (value) => _updateFormData(allowPairing: value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              CustomInputField(
                label: 'Your Slots',
                value: _formData.adminSlots,
                onChanged: (value) => _updateFormData(adminSlots: value),
                onBlur: (value) {
                  _markFieldTouched('adminSlots');
                  _validateField('adminSlots', value);
                },
                error: _errors['adminSlots'],
                touched: _touchedFields.contains('adminSlots'),
                icon: Icons.people,
                hintText: _formData.allowPairing ? 'e.g. 1.5' : 'e.g. 1',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              CustomInputField(
                label: 'Contribution Amount (NGN)',
                value: _formData.contributionAmount,
                onChanged: (value) => _updateFormData(contributionAmount: value),
                onBlur: (value) {
                  _markFieldTouched('contributionAmount');
                  _validateField('contributionAmount', value);
                },
                error: _errors['contributionAmount'],
                touched: _touchedFields.contains('contributionAmount'),
                icon: Icons.attach_money,
                hintText: '150',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Cycle Duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cycle Duration',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: HoopTheme.getTextPrimary(isDark),
                        ),
                      ),
                      Row(
                        children: [
                          CustomSwitch(
                            value: _useCustomCycle,
                            onChanged: (value) {
                              setState(() {
                                _useCustomCycle = value;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Custom cycle',
                            style: TextStyle(
                              fontSize: 14,
                              color: HoopTheme.getTextSecondary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_useCustomCycle)
                    Row(
                      children: [
                        Expanded(
                          child: CustomInputField(
                            label: 'Duration',
                            value: _formData.customCycleValue,
                            onChanged: (value) => _updateFormData(customCycleValue: value),
                            onBlur: (value) {
                              _markFieldTouched('customCycleValue');
                              _validateField('customCycleValue', value);
                            },
                            error: _errors['customCycleValue'],
                            touched: _touchedFields.contains('customCycleValue'),
                            hintText: 'e.g., 3',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unit',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: HoopTheme.getTextPrimary(isDark),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: HoopTheme.getBorderColor(isDark),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _formData.customCycleUnit,
                                    isExpanded: true,
                                    items: _customCycleUnits.map((unit) {
                                      return DropdownMenuItem<String>(
                                        value: unit.value,
                                        child: Text(unit.label),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _updateFormData(customCycleUnit: value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _errors.containsKey('cycleDuration') && _touchedFields.contains('cycleDuration')
                                  ? Colors.red
                                  : HoopTheme.getBorderColor(isDark),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _formData.cycleDuration.isNotEmpty ? _formData.cycleDuration : null,
                              hint: Text(
                                'Select Cycle Duration',
                                style: TextStyle(
                                  color: HoopTheme.getTextSecondary(isDark),
                                ),
                              ),
                              isExpanded: true,
                              items: _predefinedCycleDurations.map((duration) {
                                return DropdownMenuItem<String>(
                                  value: duration.value,
                                  child: Text(duration.label),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _updateFormData(cycleDuration: value);
                                  _markFieldTouched('cycleDuration');
                                  _validateField('cycleDuration', value);
                                }
                              },
                            ),
                          ),
                        ),
                        if (_errors.containsKey('cycleDuration') && _touchedFields.contains('cycleDuration'))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _errors['cycleDuration']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                  const SizedBox(height: 8),
                  Text(
                    _useCustomCycle
                        ? 'Contributions will be collected every ${_formData.customCycleValue.isNotEmpty ? _formData.customCycleValue : 'N'} ${_formData.customCycleUnit}'
                        : 'How often members contribute',
                    style: TextStyle(
                      fontSize: 12,
                      color: HoopTheme.getTextSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Financial Details Header
          Center(
            child: Column(
              children: [
                Text(
                  'Financial Details',
                  style: TextStyle(
                    color: HoopTheme.primaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up contribution and payout structure',
                  style: TextStyle(
                    color: HoopTheme.getTextSecondary(isDark),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Payout Order
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payout Order',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: HoopTheme.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: _payoutOrderOptions.map((option) {
                  final isSelected = _formData.payoutOrder == option.value;
                  return GestureDetector(
                    onTap: () => _updateFormData(payoutOrder: option.value),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? HoopTheme.primaryBlue
                              : HoopTheme.getBorderColor(isDark),
                          width: isSelected ? 2 : 1,
                        ),
                        color: isSelected
                            ? HoopTheme.primaryBlue.withOpacity(0.05)
                            : Colors.transparent,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: HoopTheme.getTextPrimary(isDark),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: HoopTheme.getTextSecondary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Late Payment Penalty Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HoopTheme.getMutedColor(isDark).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info,
                  color: HoopTheme.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Late Payment Penalty',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: HoopTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'A standard 2.5% penalty applies to late payments',
                        style: TextStyle(
                          fontSize: 12,
                          color: HoopTheme.getTextSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Group Settings Header
          Center(
            child: Column(
              children: [
                Text(
                  'Group Settings',
                  style: TextStyle(
                    color: HoopTheme.primaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure privacy and member requirements',
                  style: TextStyle(
                    color: HoopTheme.getTextSecondary(isDark),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Privacy and Approval Toggles
          Column(
            children: [
              // Private Group Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: HoopTheme.getBorderColor(isDark).withOpacity(0.1),
                  ),
                ),
                child: Row(
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
                            _formData.isPrivate ? Icons.visibility_off : Icons.visibility,
                            color: HoopTheme.primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Private Group',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: HoopTheme.getTextPrimary(isDark),
                              ),
                            ),
                            Text(
                              'Only visible to invited members',
                              style: TextStyle(
                                fontSize: 12,
                                color: HoopTheme.getTextSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    CustomSwitch(
                      value: _formData.isPrivate,
                      onChanged: (value) => _updateFormData(isPrivate: value),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Require Approval Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: HoopTheme.getBorderColor(isDark).withOpacity(0.1),
                  ),
                ),
                child: Row(
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
                            Icons.shield,
                            color: HoopTheme.vibrantOrange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Require Approval',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: HoopTheme.getTextPrimary(isDark),
                              ),
                            ),
                            Text(
                              'Review join requests manually',
                              style: TextStyle(
                                fontSize: 12,
                                color: HoopTheme.getTextSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    CustomSwitch(
                      value: _formData.requireApproval,
                      onChanged: (value) => _updateFormData(requireApproval: value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text(
                  'Review & Create',
                  style: TextStyle(
                    color: HoopTheme.primaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Double-check your group details',
                  style: TextStyle(
                    color: HoopTheme.getTextSecondary(isDark),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Group Preview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: HoopTheme.getBorderColor(isDark).withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: HoopTheme.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 12),
                _buildReviewItem('Name', _formData.name),
                const SizedBox(height: 8),
                _buildReviewItem('Description', _formData.description),
                const SizedBox(height: 8),
                _buildReviewItem(
                  'Start Date',
                  _formatDate(_formData.startDate),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Financial Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: HoopTheme.getBorderColor(isDark).withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Details',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: HoopTheme.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 12,
                  children: [
                    _buildFinancialItem(
                      'Contribution',
                      '₦${_formatNumber(_formData.contributionAmount)}',
                      HoopTheme.successGreen,
                    ),
                    _buildFinancialItem(
                      'Cycle',
                      _formatCycleDuration(),
                      null,
                    ),
                    _buildFinancialItem(
                      'Max Members',
                      _formData.maxMembers,
                      null,
                    ),
                    _buildFinancialItem(
                      'Late Penalty',
                      '2.5%',
                      null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Settings Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: HoopTheme.getBorderColor(isDark).withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: HoopTheme.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    _buildSettingItem(
                      'Privacy',
                      _formData.isPrivate ? 'Private' : 'Public',
                      _formData.isPrivate ? HoopTheme.vibrantOrange : HoopTheme.successGreen,
                    ),
                    _buildSettingItem(
                      'Join Approval',
                      _formData.requireApproval ? 'Required' : 'Automatic',
                      _formData.requireApproval ? HoopTheme.vibrantOrange : HoopTheme.successGreen,
                    ),
                    _buildSettingItem(
                      'Payout Order',
                      _formatPayoutOrder(_formData.payoutOrder),
                      HoopTheme.primaryBlue,
                    ),
                    _buildSettingItem(
                      'Allow Pairing',
                      _formData.allowPairing ? 'Yes' : 'No',
                      _formData.allowPairing ? HoopTheme.successGreen : HoopTheme.getTextSecondary(isDark),
                    ),
                    _buildSettingItem(
                      'Your Slots',
                      _formData.adminSlots,
                      HoopTheme.primaryBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HoopTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info,
                  color: HoopTheme.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to Launch!',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: HoopTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Once created, some settings like contribution amount and cycle duration cannot be changed.',
                        style: TextStyle(
                          fontSize: 12,
                          color: HoopTheme.primaryBlue.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: HoopTheme.getTextSecondary(isDark),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: HoopTheme.getTextPrimary(isDark),
          ),
          maxLines: label == 'Description' ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (label == 'Description')
          Text(
            '${_formData.description.length}/200 characters',
            style: TextStyle(
              fontSize: 12,
              color: HoopTheme.getTextSecondary(isDark),
            ),
          ),
      ],
    );
  }

  Widget _buildFinancialItem(String label, String value, Color? valueColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: HoopTheme.getTextSecondary(isDark),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor ?? HoopTheme.getTextPrimary(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: HoopTheme.getTextSecondary(
                Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatNumber(String numberString) {
    try {
      final number = int.parse(numberString);
      return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } catch (e) {
      return numberString;
    }
  }

  String _formatPayoutOrder(String payoutOrder) {
    return payoutOrder
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildFooter() {
    final isStep1Valid = _isStepValid(1);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        border: Border(
          top: BorderSide(
            color: HoopTheme.getBorderColor(isDark).withOpacity(0.1),
          ),
        ),
      ),
      child: _currentStep < _totalSteps
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isStep1Valid ? _handleNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HoopTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue'),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating || !isStep1Valid ? null : _handleCreateGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HoopTheme.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Creating Group...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Create Group'),
                          const SizedBox(width: 8),
                          Icon(Icons.check, size: 20),
                        ],
                      ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _currentStep == 1
                ? _buildStep1()
                : _currentStep == 2
                    ? _buildStep2()
                    : _buildStep3(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }
}