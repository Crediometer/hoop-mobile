import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoop/utils/helpers/formatters/hoop_formatter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class HoopInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final bool isDarkMode;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final bool autoValidate;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool showCounter;
  final EdgeInsetsGeometry? contentPadding;
  final String? errorText;
  final bool? filled;
  final Color? fillColor;
  final bool readOnly; // Added
  final VoidCallback? onTap; // Added
  final TextCapitalization textCapitalization; // Added
  final bool autocorrect; // Added
  final bool enableSuggestions; // Added
  final bool expands; // Added
  final TextAlign textAlign; // Added
  final TextAlignVertical? textAlignVertical; // Added
  final Widget? buildCounter; // Added
  final Iterable<String>? autofillHints; // Added
  final MouseCursor? mouseCursor; // Added

  const HoopInput({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.isDarkMode = false,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
    this.validator,
    this.autoValidate = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.showCounter = false,
    this.contentPadding,
    this.errorText,
    this.filled,
    this.fillColor,
    this.readOnly = false, // Added with default
    this.onTap, // Added
    this.textCapitalization = TextCapitalization.none, // Added with default
    this.autocorrect = true, // Added with default
    this.enableSuggestions = true, // Added with default
    this.expands = false, // Added with default
    this.textAlign = TextAlign.start, // Added with default
    this.textAlignVertical, // Added
    this.buildCounter, // Added
    this.autofillHints, // Added
    this.mouseCursor, // Added
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFillColor =
        fillColor ?? (isDarkMode ? const Color(0xFF1C1F2E) : Colors.grey[200]);
    final effectiveFilled = filled ?? true;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly, // Added
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      focusNode: focusNode,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      style: TextStyle(
        color: isDarkMode
            ? (enabled ? Colors.white : Colors.white.withOpacity(0.5))
            : (enabled ? Colors.black : Colors.black.withOpacity(0.5)),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          fontSize: 14,
        ),
        filled: effectiveFilled,
        fillColor: effectiveFilled
            ? (enabled
                  ? effectiveFillColor
                  : effectiveFillColor?.withOpacity(0.5))
            : null,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white24 : Colors.grey.withOpacity(0.4),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.blueAccent : Colors.blue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode
                ? Colors.white24.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        errorText: errorText,
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          height: 0.8,
        ),
        counterText: showCounter ? null : '',
        counter: buildCounter,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        alignLabelWithHint: maxLines != null && maxLines! > 1,
      ),
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: autoValidate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      onTap: onTap, // Added
      textCapitalization: textCapitalization, // Added
      autocorrect: autocorrect, // Added
      enableSuggestions: enableSuggestions, // Added
      expands: expands, // Added
      textAlign: textAlign, // Added
      textAlignVertical: textAlignVertical, // Added
      autofillHints: autofillHints, // Added
      mouseCursor: mouseCursor, // Added
      cursorColor: isDarkMode
          ? Colors.blueAccent
          : Colors.blue, // Added cursor color
      cursorWidth: 1.5, // Added cursor width
      cursorRadius: const Radius.circular(1), // Added cursor radius
    );
  }
}

// ==================== DATE INPUT ====================
class HoopDateInput extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final bool isDarkMode;
  final Function(DateTime)? onDateSelected;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? Function(String?)? validator;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final String? errorText;
  final bool? filled;
  final Color? fillColor;
  final Widget? prefixIcon;
  final DateFormat? dateFormat;

  const HoopDateInput({
    super.key,
    required this.controller,
    this.hintText = 'Select date',
    this.labelText,
    this.isDarkMode = false,
    this.onDateSelected,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.validator,
    this.enabled = true,
    this.contentPadding,
    this.errorText,
    this.filled,
    this.fillColor,
    this.prefixIcon,
    this.dateFormat,
  });

  @override
  State<HoopDateInput> createState() => _HoopDateInputState();
}

class _HoopDateInputState extends State<HoopDateInput> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectDate() async {
    if (!widget.enabled) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.initialDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: widget.isDarkMode
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.blueAccent,
                    onPrimary: Colors.white,
                    surface: Color(0xFF2D3447),
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light(),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = HoopFormatters.formatDate(picked);
      widget.controller.text = formattedDate;
      widget.onDateSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HoopInput(
      controller: widget.controller,
      hintText: widget.hintText,
      labelText: widget.labelText,
      isDarkMode: widget.isDarkMode,
      validator: widget.validator,
      enabled: widget.enabled,
      contentPadding: widget.contentPadding,
      errorText: widget.errorText,
      filled: widget.filled,
      fillColor: widget.fillColor,
      prefixIcon: widget.prefixIcon ?? const Icon(Icons.calendar_today),
      readOnly: true,
      onTap: _selectDate,
    );
  }
}

// Optional: Create a HoopInput builder for common configurations
class HoopInputBuilder {
  static HoopInput email({
    required TextEditingController controller,
    String? labelText,
    bool isDarkMode = false,
    String? hintText,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
    FocusNode? focusNode,
    bool autoValidate = true,
    bool enabled = true,
  }) {
    return HoopInput(
      controller: controller,
      labelText: labelText ?? 'Email',
      hintText: hintText ?? 'Enter your email',
      isDarkMode: isDarkMode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      autoValidate: autoValidate,
      enabled: enabled,
      validator: autoValidate
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            }
          : null,
      prefixIcon: Icon(
        Icons.email,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      ),
    );
  }

  static HoopInput phone({
    required TextEditingController controller,
    String? labelText,
    bool isDarkMode = false,
    String? hintText,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
    FocusNode? focusNode,
    bool autoValidate = true,
    bool enabled = true,
  }) {
    return HoopInput(
      controller: controller,
      labelText: labelText ?? 'Phone',
      hintText: hintText ?? 'Enter your phone number',
      isDarkMode: isDarkMode,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      autoValidate: autoValidate,
      enabled: enabled,
      validator: autoValidate
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              final phoneRegex = RegExp(r'^[0-9\+\-\s\(\)]{10,}$');
              if (!phoneRegex.hasMatch(value)) {
                return 'Enter a valid phone number';
              }
              return null;
            }
          : null,
      prefixIcon: Icon(
        Icons.phone,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      ),
    );
  }

  static HoopInput search({
    required TextEditingController controller,
    String? hintText,
    bool isDarkMode = false,
    Function(String)? onChanged,
    FocusNode? focusNode,
    bool enabled = true,
  }) {
    return HoopInput(
      controller: controller,
      hintText: hintText ?? 'Search...',
      isDarkMode: isDarkMode,
      onChanged: onChanged,
      focusNode: focusNode,
      enabled: enabled,
      prefixIcon: Icon(
        Icons.search,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      ),
      suffixIcon: IconButton(
        icon: Icon(
          Icons.clear,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        onPressed: () {
          controller.clear();
          onChanged?.call('');
        },
      ),
    );
  }

  static HoopInput multiline({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    bool isDarkMode = false,
    int minLines = 3,
    int maxLines = 5,
    bool enabled = true,
    bool autoValidate = false,
  }) {
    return HoopInput(
      controller: controller,
      labelText: labelText ?? 'Description',
      hintText: hintText ?? 'Enter description...',
      isDarkMode: isDarkMode,
      minLines: minLines,
      maxLines: maxLines,
      enabled: enabled,
      autoValidate: autoValidate,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
    );
  }

  static HoopInput number({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    bool isDarkMode = false,
    bool decimal = false,
    bool enabled = true,
    bool autoValidate = false,
  }) {
    return HoopInput(
      controller: controller,
      labelText: labelText ?? 'Number',
      hintText: hintText ?? 'Enter number',
      isDarkMode: isDarkMode,
      keyboardType: decimal
          ? TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      enabled: enabled,
      autoValidate: autoValidate,
      validator: autoValidate
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Number is required';
              }
              if (decimal) {
                final parsed = double.tryParse(value);
                if (parsed == null) {
                  return 'Enter a valid number';
                }
              } else {
                final parsed = int.tryParse(value);
                if (parsed == null) {
                  return 'Enter a valid whole number';
                }
              }
              return null;
            }
          : null,
    );
  }
}

// ==================== PASSWORD INPUT ====================
class HoopPasswordInput extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final bool isDarkMode;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final bool autoValidate;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final String? errorText;
  final bool? filled;
  final Color? fillColor;
  final bool showToggle;

  const HoopPasswordInput({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.isDarkMode = false,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
    this.validator,
    this.autoValidate = false,
    this.enabled = true,
    this.contentPadding,
    this.errorText,
    this.filled,
    this.fillColor,
    this.showToggle = true,
  });

  @override
  State<HoopPasswordInput> createState() => _HoopPasswordInputState();
}

class _HoopPasswordInputState extends State<HoopPasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return HoopInput(
      controller: widget.controller,
      hintText: widget.hintText ?? 'Enter password',
      labelText: widget.labelText,
      obscureText: _obscureText,
      isDarkMode: widget.isDarkMode,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      focusNode: widget.focusNode,
      validator: widget.validator,
      autoValidate: widget.autoValidate,
      enabled: widget.enabled,
      contentPadding: widget.contentPadding,
      errorText: widget.errorText,
      filled: widget.filled,
      fillColor: widget.fillColor,
      suffixIcon: widget.showToggle
          ? IconButton(
              icon: Icon(
                _obscureText ? Iconsax.eye : Iconsax.eye_slash,
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            )
          : null,
    );
  }
}

// ==================== PIN INPUT ====================
class HoopPinInput extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final bool obscureText;
  final bool isDarkMode;
  final double pinSize;
  final double spacing;
  final bool enabled;
  final bool autoFocus;
  final TextEditingController? controller;
  final String? errorText;
  final TextInputType keyboardType;
  final TextStyle? textStyle;

  const HoopPinInput({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.onChanged,
    this.obscureText = false,
    this.isDarkMode = false,
    this.pinSize = 50,
    this.spacing = 10,
    this.enabled = true,
    this.autoFocus = false,
    this.controller,
    this.errorText,
    this.keyboardType = TextInputType.number,
    this.textStyle,
  });

  @override
  State<HoopPinInput> createState() => _HoopPinInputState();
}

class _HoopPinInputState extends State<HoopPinInput> {
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    // Only dispose the internal controller, not the external one
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PinInputWidget(
          length: widget.length,
          onCompleted: widget.onCompleted,
          obscureText: widget.obscureText,
          isDarkMode: widget.isDarkMode,
          pinSize: widget.pinSize,
          spacing: widget.spacing,
          enabled: widget.enabled,
          autoFocus: widget.autoFocus,
          controller: _internalController,
          keyboardType: widget.keyboardType,
          textStyle: widget.textStyle,
        ),
        if (widget.errorText != null && widget.errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}

class _PinInputWidget extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final bool obscureText;
  final bool isDarkMode;
  final double pinSize;
  final double spacing;
  final bool enabled;
  final bool autoFocus;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextStyle? textStyle;

  const _PinInputWidget({
    required this.length,
    required this.onCompleted,
    required this.obscureText,
    required this.isDarkMode,
    required this.pinSize,
    required this.spacing,
    required this.enabled,
    required this.autoFocus,
    required this.controller,
    required this.keyboardType,
    this.textStyle,
    this.onChanged,
  });

  @override
  __PinInputWidgetState createState() => __PinInputWidgetState();
}

class __PinInputWidgetState extends State<_PinInputWidget> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  String _currentPin = '';

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );

    // Initialize with external controller value if it exists
    if (widget.controller.text.isNotEmpty) {
      _setPinFromExternalController(widget.controller.text);
    }

    // Listen to external controller changes
    widget.controller.addListener(_onExternalControllerChanged);
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    widget.controller.removeListener(_onExternalControllerChanged);
    super.dispose();
  }

  void _onExternalControllerChanged() {
    if (widget.controller.text != _currentPin) {
      _setPinFromExternalController(widget.controller.text);
    }
  }

  void _setPinFromExternalController(String value) {
    if (value.length <= widget.length) {
      for (int i = 0; i < widget.length; i++) {
        if (i < value.length) {
          _controllers[i].text = value[i];
        } else {
          _controllers[i].text = '';
        }
      }
      _currentPin = value;
    }
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }

      // Update current pin
      final chars = _currentPin.split('');
      if (index < chars.length) {
        chars[index] = value;
      } else {
        chars.add(value);
      }
      _currentPin = chars.join('');

      // Update external controller
      widget.controller.text = _currentPin;

      if (widget.onChanged != null) widget.onChanged!(_currentPin);
      // Check if completed
      if (_currentPin.length == widget.length) {
        widget.onCompleted(_currentPin);
        return;
      }

    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();

      // Update current pin
      if (index < _currentPin.length) {
        _currentPin = _currentPin.substring(0, index);
      } else if (index == _currentPin.length) {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      }

      // Update external controller
      widget.controller.text = _currentPin;
    }
  }

  void _onBackspace(int index) {
    if (index > 0 && _controllers[index].text.isEmpty) {
      _controllers[index - 1].text = '';
      _focusNodes[index - 1].requestFocus();

      // Update current pin
      if (index <= _currentPin.length) {
        _currentPin = _currentPin.substring(0, index - 1);
        widget.controller.text = _currentPin;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        return Container(
          margin: EdgeInsets.only(
            right: index < widget.length - 1 ? widget.spacing : 0,
          ),
          width: widget.pinSize,
          height: widget.pinSize,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: widget.keyboardType,
            maxLength: 1,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            autofocus: widget.autoFocus && index == 0,
            style:
                widget.textStyle ??
                TextStyle(
                  fontSize: widget.pinSize * 0.4,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.isDarkMode ? Colors.blue : Colors.blueAccent,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.isDarkMode ? Colors.grey : Colors.grey,
                  width: 1,
                ),
              ),
              filled: true,
              fillColor: widget.isDarkMode
                  ? Colors.grey[900]
                  : Colors.grey[100],
            ),
            onChanged: (value) => _onChanged(index, value),
            onTap: () {
              // Move cursor to end
              _controllers[index].selection = TextSelection.fromPosition(
                TextPosition(offset: _controllers[index].text.length),
              );
            },
            onSubmitted: (_) {
              if (index < widget.length - 1) {
                _focusNodes[index + 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}

// ==================== DROPDOWN INPUT ====================
class HoopDropdownInput<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? hintText;
  final String? labelText;
  final bool isDarkMode;
  final String? Function(T?)? validator;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final String? errorText;
  final bool? filled;
  final Color? fillColor;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const HoopDropdownInput({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.labelText,
    this.isDarkMode = false,
    this.validator,
    this.enabled = true,
    this.contentPadding,
    this.errorText,
    this.filled,
    this.fillColor,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFillColor =
        fillColor ?? (isDarkMode ? const Color(0xFF1C1F2E) : Colors.grey[200]);
    final effectiveFilled = filled ?? true;

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.grey : Colors.grey[600],
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          fontSize: 14,
        ),
        filled: effectiveFilled,
        fillColor: effectiveFilled
            ? (enabled
                  ? effectiveFillColor
                  : effectiveFillColor?.withOpacity(0.5))
            : null,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon ?? const Icon(Icons.arrow_drop_down),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white24 : Colors.grey.withOpacity(0.4),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode
                ? Colors.white24.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        errorText: errorText,
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          height: 0.8,
        ),
      ),
      icon: const SizedBox.shrink(),
      isExpanded: true,
      dropdownColor: isDarkMode ? const Color(0xFF2D3447) : Colors.white,
    );
  }
}

// ==================== TIME INPUT ====================
class HoopTimeInput extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final bool isDarkMode;
  final Function(TimeOfDay)? onTimeSelected;
  final TimeOfDay? initialTime;
  final String? Function(String?)? validator;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final String? errorText;
  final bool? filled;
  final Color? fillColor;
  final Widget? prefixIcon;
  final DateFormat? timeFormat;

  const HoopTimeInput({
    super.key,
    required this.controller,
    this.hintText = 'Select time',
    this.labelText,
    this.isDarkMode = false,
    this.onTimeSelected,
    this.initialTime,
    this.validator,
    this.enabled = true,
    this.contentPadding,
    this.errorText,
    this.filled,
    this.fillColor,
    this.prefixIcon,
    this.timeFormat,
  });

  @override
  State<HoopTimeInput> createState() => _HoopTimeInputState();
}

class _HoopTimeInputState extends State<HoopTimeInput> {
  Future<void> _selectTime() async {
    if (!widget.enabled) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: widget.initialTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: widget.isDarkMode
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.blueAccent,
                    onPrimary: Colors.white,
                    surface: Color(0xFF2D3447),
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light(),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );

      final formatter = widget.timeFormat ?? DateFormat('hh:mm a');
      final formattedTime = formatter.format(dateTime);

      widget.controller.text = formattedTime;
      widget.onTimeSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HoopInput(
      controller: widget.controller,
      hintText: widget.hintText,
      labelText: widget.labelText,
      isDarkMode: widget.isDarkMode,
      validator: widget.validator,
      enabled: widget.enabled,
      contentPadding: widget.contentPadding,
      errorText: widget.errorText,
      filled: widget.filled,
      fillColor: widget.fillColor,
      prefixIcon: widget.prefixIcon ?? const Icon(Icons.access_time),
      readOnly: true,
      onTap: _selectTime,
    );
  }
}

// ==================== DATE & TIME INPUT ====================
class HoopDateTimeInput extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final bool isDarkMode;
  final Function(DateTime)? onDateTimeSelected;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? Function(String?)? validator;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final String? errorText;
  final bool? filled;
  final Color? fillColor;
  final Widget? prefixIcon;
  final DateFormat? dateTimeFormat;

  const HoopDateTimeInput({
    super.key,
    required this.controller,
    this.hintText = 'Select date and time',
    this.labelText,
    this.isDarkMode = false,
    this.onDateTimeSelected,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.validator,
    this.enabled = true,
    this.contentPadding,
    this.errorText,
    this.filled,
    this.fillColor,
    this.prefixIcon,
    this.dateTimeFormat,
  });

  @override
  State<HoopDateTimeInput> createState() => _HoopDateTimeInputState();
}

class _HoopDateTimeInputState extends State<HoopDateTimeInput> {
  late DateFormat _dateTimeFormat;

  @override
  void initState() {
    super.initState();
    _dateTimeFormat = widget.dateTimeFormat ?? DateFormat('MM/dd/yyyy hh:mm a');
  }

  Future<void> _selectDateTime() async {
    if (!widget.enabled) return;

    // First select date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.initialDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: widget.isDarkMode
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.blueAccent,
                    onPrimary: Colors.white,
                    surface: Color(0xFF2D3447),
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light(),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Then select time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(pickedDate),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: widget.isDarkMode
                ? ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Colors.blueAccent,
                      onPrimary: Colors.white,
                      surface: Color(0xFF2D3447),
                      onSurface: Colors.white,
                    ),
                  )
                : ThemeData.light(),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final dateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        final formattedDateTime = _dateTimeFormat.format(dateTime);
        widget.controller.text = formattedDateTime;
        widget.onDateTimeSelected?.call(dateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HoopInput(
      controller: widget.controller,
      hintText: widget.hintText,
      labelText: widget.labelText,
      isDarkMode: widget.isDarkMode,
      validator: widget.validator,
      enabled: widget.enabled,
      contentPadding: widget.contentPadding,
      errorText: widget.errorText,
      filled: widget.filled,
      fillColor: widget.fillColor,
      prefixIcon: widget.prefixIcon ?? const Icon(Icons.date_range),
      readOnly: true,
      onTap: _selectDateTime,
    );
  }
}

// ==================== EXTENSION ON HOOPINPUT ====================
extension HoopInputExtensions on HoopInput {
  // Add readOnly property
  static HoopInput copyWithReadOnly({
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
    String? hintText,
    String? labelText,
    bool isDarkMode = false,
    Widget? prefixIcon,
  }) {
    return HoopInput(
      controller: controller,
      hintText: hintText,
      labelText: labelText,
      isDarkMode: isDarkMode,
      prefixIcon: prefixIcon,
      enabled: !readOnly,
      onTap: onTap,
    );
  }
}
