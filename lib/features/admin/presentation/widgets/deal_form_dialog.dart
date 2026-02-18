import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/observability/owner_action_observability_service.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/utils/remote_url_utils.dart';
import 'package:tapem/features/deals/data/providers/deals_provider.dart';
import 'package:tapem/features/deals/domain/models/deal.dart';
import 'package:tapem/l10n/app_localizations.dart';

class DealFormDialog extends ConsumerStatefulWidget {
  final Deal? deal;

  const DealFormDialog({super.key, this.deal});

  @override
  ConsumerState<DealFormDialog> createState() => _DealFormDialogState();
}

class _DealFormDialogState extends ConsumerState<DealFormDialog> {
  late final TextEditingController _partnerController;
  late final TextEditingController _titleController;
  late final TextEditingController _codeController;
  late final TextEditingController _linkController;
  late final TextEditingController _imageController;
  late final TextEditingController _partnerLogoController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priorityController;
  late final TextEditingController _categoryController;
  bool _categorySeeded = false;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.deal;
    _partnerController = TextEditingController(text: d?.partnerName);
    _titleController = TextEditingController(text: d?.title);
    _codeController = TextEditingController(text: d?.code);
    _linkController = TextEditingController(text: d?.link);
    _imageController = TextEditingController(text: d?.imageUrl);
    _partnerLogoController = TextEditingController(text: d?.partnerLogoUrl);
    _descriptionController = TextEditingController(text: d?.description);
    _priorityController = TextEditingController(
      text: d?.priority.toString() ?? '0',
    );
    _categoryController = TextEditingController(text: d?.category);
    _isActive = d?.isActive ?? true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_categorySeeded) return;
    _categorySeeded = true;
    if (_categoryController.text.trim().isNotEmpty) return;
    _categoryController.text = AppLocalizations.of(context)!.dealFormCategoryDefault;
  }

  @override
  void dispose() {
    _partnerController.dispose();
    _titleController.dispose();
    _codeController.dispose();
    _linkController.dispose();
    _imageController.dispose();
    _partnerLogoController.dispose();
    _descriptionController.dispose();
    _priorityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final partnerName = _partnerController.text.trim();
    final title = _titleController.text.trim();
    final code = _codeController.text.trim();
    final link = normalizeRemoteUrl(_linkController.text);
    final imageUrl = normalizeRemoteUrl(_imageController.text);
    final partnerLogoUrl = normalizeRemoteUrl(_partnerLogoController.text);
    final description = _descriptionController.text.trim();
    final category = _categoryController.text.trim();
    final priority = int.tryParse(_priorityController.text) ?? 0;

    final loc = AppLocalizations.of(context)!;
    if (partnerName.isEmpty || title.isEmpty || code.isEmpty || link.isEmpty) {
      _showError(loc.dealFormRequiredFieldsError);
      return;
    }

    if (!isValidHttpUrl(link)) {
      _showError(loc.dealFormInvalidUrlError);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(dealsRepositoryProvider);
      final deal =
          (widget.deal ??
                  Deal(
                    id: '',
                    title: title,
                    description: description,
                    partnerName: partnerName,
                    partnerLogoUrl: partnerLogoUrl,
                    imageUrl: imageUrl,
                    code: code,
                    link: link,
                    category: category,
                    isActive: _isActive,
                    priority: priority,
                    createdAt: DateTime.now(),
                  ))
              .copyWith(
                partnerName: partnerName,
                title: title,
                code: code,
                link: link,
                imageUrl: imageUrl,
                partnerLogoUrl: partnerLogoUrl,
                description: description,
                category: category,
                priority: priority,
                isActive: _isActive,
              );

      await OwnerActionObservabilityService.instance.trackAction(
        action: widget.deal == null
            ? 'owner.deals.create'
            : 'owner.deals.update',
        command: () => repository.saveDeal(deal),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        _showError(loc.dealFormSaveError(e.toString()));
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        viewInsets.bottom + AppSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.deal == null ? loc.dealFormTitleNew : loc.dealFormTitleEdit,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _partnerController,
                decoration: InputDecoration(labelText: loc.dealFormPartnerLabel),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: loc.dealFormTitleLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(labelText: loc.dealFormCodeLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _linkController,
                decoration: InputDecoration(labelText: loc.dealFormLinkLabel),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _imageController,
                decoration: InputDecoration(labelText: loc.dealFormImageUrlLabel),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _partnerLogoController,
                decoration: InputDecoration(
                  labelText: loc.dealFormPartnerLogoLabel,
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: loc.dealFormDescriptionLabel),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: loc.dealFormCategoryLabel,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _priorityController,
                      decoration: InputDecoration(labelText: loc.dealFormPriorityLabel),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                title: Text(loc.dealFormActiveLabel),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(loc.commonSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
