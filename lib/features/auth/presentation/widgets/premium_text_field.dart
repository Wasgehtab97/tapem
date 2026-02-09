import 'package:flutter/material.dart';
import '../theme/auth_theme.dart';

class PremiumTextField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final EdgeInsets scrollPadding;

  const PremiumTextField({
    Key? key,
    required this.label,
    this.controller,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.scrollPadding = const EdgeInsets.only(bottom: 180),
  }) : super(key: key);

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      final isFocused = _focusNode.hasFocus;
      if (isFocused == _isFocused) return;
      setState(() => _isFocused = isFocused);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusColor = Colors.white;

    return AnimatedContainer(
      duration: AuthTheme.animationDurationFast,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _isFocused ? AuthTheme.surfacePressed : AuthTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? focusColor.withOpacity(0.85) : AuthTheme.border,
          width: _isFocused ? 1.4 : 1.1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextFormField(
        controller: widget.controller,
        initialValue: widget.initialValue,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.none,
        style: AuthTheme.bodyStyle.copyWith(color: AuthTheme.textPrimary),
        cursorColor: AuthTheme.textPrimary,
        textInputAction: widget.textInputAction,
        readOnly: widget.readOnly,
        scrollPadding: widget.scrollPadding,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: AuthTheme.labelStyle.copyWith(color: AuthTheme.textMuted),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, color: AuthTheme.textMuted)
              : null,
          suffixIcon: widget.suffixIcon,
          errorStyle: const TextStyle(height: 1.1, color: AuthTheme.danger),
        ),
        validator: widget.validator,
        onSaved: widget.onSaved,
        onChanged: widget.onChanged,
      ),
    );
  }
}
