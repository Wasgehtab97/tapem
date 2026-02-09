import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/utils/remote_url_utils.dart';
import 'package:tapem/features/deals/domain/models/deal.dart';
import 'package:url_launcher/url_launcher.dart';

class DealCard extends StatefulWidget {
  const DealCard({super.key, required this.deal, required this.onTrackClick});

  final Deal deal;
  final VoidCallback onTrackClick;

  @override
  State<DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<DealCard> {
  bool _isExpanded = false;

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _launchUrl() async {
    final uri = parseHttpUri(widget.deal.link);
    if (uri == null) {
      _showSnackBar('Ungültiger Shop-Link.');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        widget.onTrackClick();
        return;
      }
      _showSnackBar('Shop konnte nicht geöffnet werden.');
    } catch (_) {
      _showSnackBar('Shop konnte nicht geöffnet werden.');
    }
  }

  Widget _buildDealImageFallback(Color onSurface) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Icon(Icons.broken_image, color: onSurface.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildPartnerLogoFallback(Color onSurface) {
    return Center(
      child: Icon(
        Icons.storefront_outlined,
        size: 18,
        color: onSurface.withOpacity(0.25),
      ),
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.deal.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Code '${widget.deal.code}' kopiert!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.outline ?? theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;
    final dealImageUri = parseHttpUri(widget.deal.imageUrl);
    final partnerLogoUri = parseHttpUri(widget.deal.partnerLogoUrl);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(color: onSurface.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Image
          SizedBox(
            height: 170, // Slightly taller
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (dealImageUri != null)
                  Image.network(
                    dealImageUri.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
                        _buildDealImageFallback(onSurface),
                  ),
                if (dealImageUri == null) _buildDealImageFallback(onSurface),
                // Premium Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 0.7, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                // Partner Logo (top left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: partnerLogoUri != null
                          ? Image.network(
                              partnerLogoUri.toString(),
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, stack) =>
                                  _buildPartnerLogoFallback(onSurface),
                            )
                          : _buildPartnerLogoFallback(onSurface),
                    ),
                  ),
                ),
                // Category Chip (top right) - Glassmorphism style
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      widget.deal.category.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Area with subtle gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.surface, AppColors.surface.withOpacity(0.9)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.deal.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Text(
                      widget.deal.description,
                      maxLines: _isExpanded ? null : 2,
                      overflow: _isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onSurface.withOpacity(0.6),
                        height: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (widget.deal.description.length > 80)
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _isExpanded ? 'WENIGER ANZEIGEN' : 'MEHR ANZEIGEN',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),

                // Actions
                Row(
                  children: [
                    // Code Button
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => _copyCode(context),
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                            border: Border.all(
                              color: accent.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.copy_rounded, size: 14, color: accent),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.deal.code,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Shop Button
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                          gradient: LinearGradient(
                            colors: [accent, accent.withOpacity(0.8)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _launchUrl,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.black,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'ZUM SHOP',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Footer (fills space and adds credibility)
                const SizedBox(height: AppSpacing.md),
                Divider(color: onSurface.withOpacity(0.05), height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 12,
                      color: onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'VERIFIZIERTER PARTNER-DEAL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: onSurface.withOpacity(0.3),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
