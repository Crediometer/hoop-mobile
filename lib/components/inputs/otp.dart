import 'package:flutter/material.dart';

class HoopOtpInput extends StatefulWidget {
  final int length;
  final TextEditingController controller;
  final void Function(String) onChanged;
  final bool autoFocus;
  final TextStyle? textStyle;
  final bool obscureText;

  const HoopOtpInput({
    super.key,
    required this.length,
    required this.controller,
    required this.onChanged,
    this.autoFocus = false,
    this.textStyle,
    this.obscureText = false,
  });

  @override
  State<HoopOtpInput> createState() => _HoopOtpInputState();
}

class _HoopOtpInputState extends State<HoopOtpInput> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  late List<String> _otpValues;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _otpValues = List.filled(widget.length, '');

    // Initialize with existing value
    if (widget.controller.text.isNotEmpty) {
      _setOtpValue(widget.controller.text);
    }

    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.text != _getOtpValue()) {
      _setOtpValue(widget.controller.text);
    }
  }

  String _getOtpValue() {
    return _otpValues.join();
  }

  void _setOtpValue(String value) {
    final chars = value.split('');
    for (int i = 0; i < widget.length; i++) {
      final char = i < chars.length ? chars[i] : '';
      _otpValues[i] = char;
      _controllers[i].text = char;
    }
    setState(() {});
  }

  void _handleTextChanged(int index, String value) {
    if (value.isNotEmpty) {
      _otpValues[index] = value[value.length - 1];
      _controllers[index].text = value[value.length - 1];

      // Move focus to next field
      if (index < widget.length - 1) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      _otpValues[index] = '';
    }

    final otpValue = _getOtpValue();
    widget.controller.text = otpValue;
    widget.onChanged(otpValue);
  }

  void _handleBackspace(int index, String value) {
    if (value.isEmpty && index > 0) {
      _otpValues[index - 1] = '';
      _controllers[index - 1].text = '';
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
      
      final otpValue = _getOtpValue();
      widget.controller.text = otpValue;
      widget.onChanged(otpValue);
    }
  }

  void _handlePaste(String pastedText) {
    final cleanText = pastedText.replaceAll(RegExp(r'\D'), '');
    final otp = cleanText.length > widget.length
        ? cleanText.substring(0, widget.length)
        : cleanText;

    _setOtpValue(otp);
    widget.controller.text = otp;
    widget.onChanged(otp);

    // Focus last field
    final focusIndex = otp.length < widget.length ? otp.length : widget.length - 1;
    FocusScope.of(context).requestFocus(_focusNodes[focusIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Focus first empty field
        final firstEmptyIndex = _otpValues.indexWhere((value) => value.isEmpty);
        final index = firstEmptyIndex == -1 ? widget.length - 1 : firstEmptyIndex;
        FocusScope.of(context).requestFocus(_focusNodes[index]);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.length,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 48,
              height: 56,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                obscureText: widget.obscureText,
                obscuringCharacter: '•',
                style: widget.textStyle ??
                    const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                onChanged: (value) => _handleTextChanged(index, value),
                onSubmitted: (_) {
                  if (index < widget.length - 1) {
                    FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                  }
                },
                onTap: () {
                  _controllers[index].selection = TextSelection.fromPosition(
                    TextPosition(offset: _controllers[index].text.length),
                  );
                },
                inputFormatters: [],
                onTapOutside: (_) {
                  _focusNodes[index].unfocus();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}