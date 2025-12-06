import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/auth_theme.dart';

class PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  const PremiumButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
  }) : super(key: key);

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: AuthTheme.animationDurationFast,
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AuthTheme.glassBorderRadius),
          gradient: widget.isOutlined || isDisabled
              ? null
              : AuthTheme.primaryGradient,
          color: isDisabled 
            ? AuthTheme.glassColor 
            : (widget.isOutlined ? Colors.transparent : null),
          border: widget.isOutlined
              ? Border.all(color: Colors.white.withOpacity(0.5), width: 2)
              : null,
          boxShadow: isDisabled || widget.isOutlined
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(_isPressed ? 0.6 : 0.4),
                    blurRadius: _isPressed ? 10 : 20,
                    offset: Offset(0, _isPressed ? 2 : 8),
                  )
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: AuthTheme.buttonTextStyle.copyWith(
                        color: isDisabled ? Colors.white.withOpacity(0.5) : Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
