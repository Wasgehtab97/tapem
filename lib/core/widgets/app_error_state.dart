import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';

/// Generischer Error State für Listen/Datenladung.
///
/// Zeigt Error-Icon, Fehlermeldung und Retry-Button.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Erneut versuchen',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    errorColor.withOpacity(0.15),
                    errorColor.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: errorColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: errorColor.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Fehler beim Laden',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: errorColor,
                  side: BorderSide(color: errorColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
