import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import 'package:tapem/l10n/app_localizations.dart';

import '../../domain/session_story_data.dart';
import '../../session_story_share_service.dart';
import 'session_story_card.dart';

class SessionStoryModal extends StatefulWidget {
  final SessionStoryData story;
  final SessionStoryShareService shareService;
  final Future<Uri?> Function()? buildLink;
  final void Function(String? target)? onShared;
  final VoidCallback? onSaved;
  final VoidCallback? onViewed;

  const SessionStoryModal({
    super.key,
    required this.story,
    required this.shareService,
    this.buildLink,
    this.onShared,
    this.onSaved,
    this.onViewed,
  });

  static Future<void> show({
    required BuildContext context,
    required SessionStoryData story,
    required SessionStoryShareService shareService,
    Future<Uri?> Function()? buildLink,
    void Function(String? target)? onShared,
    VoidCallback? onSaved,
    VoidCallback? onViewed,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SessionStoryModal(
          story: story,
          shareService: shareService,
          buildLink: buildLink,
          onShared: onShared,
          onSaved: onSaved,
          onViewed: onViewed,
        ),
      ),
    );
  }

  @override
  State<SessionStoryModal> createState() => _SessionStoryModalState();
}

class _SessionStoryModalState extends State<SessionStoryModal> {
  final GlobalKey _repaintKey = GlobalKey();
  late final ConfettiController _confettiController;
  bool _isSharing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    if (widget.story.hasPrs) {
      _confettiController.play();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onViewed?.call();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (ctx, controller) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            loc.storycardTitle,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: loc.commonClose,
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SessionStoryCard(
                      data: widget.story,
                      repaintKey: _repaintKey,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.download),
                            label: Text(loc.storycardSaveButton),
                            onPressed: _isSaving ? null : _handleSave,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            icon: _isSharing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.share),
                            label: Text(loc.storycardShareButton),
                            onPressed: _isSharing ? null : _handleShare,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      maxBlastForce: 14,
                      minBlastForce: 6,
                      emissionFrequency: 0.08,
                      numberOfParticles: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleShare() async {
    setState(() {
      _isSharing = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    try {
      Uri? link;
      if (widget.buildLink != null) {
        link = await widget.buildLink!.call();
      }
      final result = await widget.shareService.shareImage(
        context: context,
        repaintKey: _repaintKey,
        data: widget.story,
        deepLink: link,
      );
      if (result.shared) {
        widget.onShared?.call(result.target);
        messenger.showSnackBar(
          SnackBar(content: Text(loc.storycardShareSuccess)),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(loc.storycardShareUnavailable)),
        );
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.storycardShareError(error.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    try {
      final path = await widget.shareService.saveImage(
        repaintKey: _repaintKey,
        data: widget.story,
      );
      widget.onSaved?.call();
      messenger.showSnackBar(
        SnackBar(content: Text(loc.storycardSaveSuccess(path))),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.storycardSaveError(error.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
