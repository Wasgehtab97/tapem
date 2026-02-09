import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final isOutlined = widget.isOutlined;
    final foregroundColor = isOutlined
        ? AuthTheme.textPrimary
        : AuthTheme.actionPrimaryForeground;

    return Opacity(
      opacity: isDisabled ? 0.45 : 1.0,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedContainer(
          duration: AuthTheme.animationDurationFast,
          transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
          curve: Curves.easeOutCubic,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isOutlined
                ? (_isPressed ? AuthTheme.surfacePressed : Colors.transparent)
                : (_isPressed
                      ? const Color(0xFFDCDCDC)
                      : AuthTheme.actionPrimaryBackground),
            border: Border.all(
              color: isOutlined ? AuthTheme.borderStrong : Colors.white,
              width: isOutlined ? 1.4 : 1.0,
            ),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(isOutlined ? 0.25 : 0.35),
                      blurRadius: isOutlined ? 10 : 16,
                      offset: Offset(0, _isPressed ? 4 : 8),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        foregroundColor,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: foregroundColor, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: AuthTheme.buttonTextStyle.copyWith(
                          color: foregroundColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
