import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
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
    final brand = Theme.of(context).extension<AppBrandTheme>();
    final focus = brand?.focusRing ?? const Color(0xFF8B5CF6);
    return AnimatedContainer(
      duration: AuthTheme.animationDurationFast,
      decoration: BoxDecoration(
        color: _isFocused
            ? AuthTheme.glassColor.withOpacity(0.15)
            : AuthTheme.glassColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused
              ? focus.withOpacity(0.5)
              : AuthTheme.glassBorderColor,
          width: 1.5,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: focus.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: widget.controller,
        initialValue: widget.initialValue,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.none,
        style: AuthTheme.bodyStyle.copyWith(color: Colors.white),
        cursorColor: Colors.white,
        textInputAction: widget.textInputAction,
        readOnly: widget.readOnly,
        scrollPadding: widget.scrollPadding,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: AuthTheme.labelStyle,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, color: Colors.white70)
              : null,
          suffixIcon: widget.suffixIcon,
          errorStyle: const TextStyle(height: 0.8, color: Color(0xFFFF8A80)),
        ),
        validator: widget.validator,
        onSaved: widget.onSaved,
        onChanged: widget.onChanged,
      ),
    );
  }
}
