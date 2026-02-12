import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    _priorityController = TextEditingController(text: d?.priority.toString() ?? '0');
    _categoryController = TextEditingController(text: d?.category ?? 'Supplements');
    _isActive = d?.isActive ?? true;
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
    final loc = AppLocalizations.of(context)!;
    final partnerName = _partnerController.text.trim();
    final title = _titleController.text.trim();
    final code = _codeController.text.trim();
    final link = normalizeRemoteUrl(_linkController.text);
    final imageUrl = normalizeRemoteUrl(_imageController.text);
    final partnerLogoUrl = normalizeRemoteUrl(_partnerLogoController.text);
    final description = _descriptionController.text.trim();
    final category = _categoryController.text.trim();
    final priority = int.tryParse(_priorityController.text) ?? 0;

    if (partnerName.isEmpty || title.isEmpty || code.isEmpty || link.isEmpty) {
      _showError('Bitte alle Pflichtfelder ausfüllen (Partner, Titel, Code, Link).');
      return;
    }

    if (!isValidHttpUrl(link)) {
      _showError('Shop-Link ist keine gültige URL.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(dealsRepositoryProvider);
      final deal = (widget.deal ??
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

      await repository.saveDeal(deal);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _showError('Fehler beim Speichern: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    
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
                widget.deal == null ? 'Neuer Deal' : 'Deal bearbeiten',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _partnerController,
              decoration: const InputDecoration(labelText: 'Partner Name *'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titel *'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Rabattcode *'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(labelText: 'Shop Link *'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(labelText: 'Bild URL'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _partnerLogoController,
              decoration: const InputDecoration(labelText: 'Partner-Logo URL'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Beschreibung'),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Kategorie'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _priorityController,
                    decoration: const InputDecoration(labelText: 'Priorität'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              title: const Text('Deal aktiv?'),
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
                  : const Text('Speichern'),
            ),
          ],
        ),
      ),
    ),
  );
}
}
