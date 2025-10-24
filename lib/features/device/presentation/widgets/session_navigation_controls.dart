import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

class SessionNavigationControls extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Widget center;

  const SessionNavigationControls({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SessionNavigationIconButton(
          icon: Icons.chevron_left,
          onPressed: onPrevious,
          tooltip: material.previousPageTooltip,
        ),
        const SizedBox(width: 12),
        center,
        const SizedBox(width: 12),
        SessionNavigationIconButton(
          icon: Icons.chevron_right,
          onPressed: onNext,
          tooltip: material.nextPageTooltip,
        ),
      ],
    );
  }
}

class SessionNavigationIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const SessionNavigationIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: color.withOpacity(0.4),
        minimumSize: const Size(40, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
