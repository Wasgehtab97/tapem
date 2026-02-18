import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/observability/owner_action_observability_service.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/destructive_action.dart';
import 'package:tapem/core/widgets/brand_modal.dart';
import 'package:tapem/core/widgets/premium_action_tile.dart';
import 'package:tapem/features/deals/data/providers/deals_provider.dart';
import 'package:tapem/features/deals/domain/models/deal.dart';
import 'package:tapem/features/admin/presentation/widgets/deal_form_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/l10n/app_localizations.dart';

class AdminDealsScreen extends ConsumerWidget {
  const AdminDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final dealsAsync = ref.watch(allDealsStreamProvider);
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.adminDealsTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: brandTheme?.onBrand ?? theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: loc.commonCreate,
            onPressed: () => _showDealDialog(context, null),
          ),
        ],
      ),
      body: dealsAsync.when(
        data: (deals) => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: deals.length,
          itemBuilder: (context, index) {
            final deal = deals[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: PremiumActionTile(
                title: deal.partnerName,
                subtitle: deal.title,
                leading: deal.partnerLogoUrl.isNotEmpty
                    ? Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                          child: Image.network(
                            deal.partnerLogoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                      )
                    : const Icon(Icons.tag_rounded),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      container: true,
                      toggled: deal.isActive,
                      label: '${loc.dealFormActiveLabel}: ${deal.partnerName}',
                      hint: deal.title,
                      child: Switch(
                        value: deal.isActive,
                        activeColor:
                            brandTheme?.outline ?? theme.colorScheme.secondary,
                        onChanged: (val) async {
                          try {
                            await OwnerActionObservabilityService.instance
                                .trackAction(
                                  action: 'owner.deals.toggle_active',
                                  command: () => ref
                                      .read(dealsRepositoryProvider)
                                    .saveDeal(deal.copyWith(isActive: val)),
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    val
                                        ? loc.adminDealsStatusActive
                                        : loc.adminDealsStatusInactive,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(loc.adminDealsToggleError(e.toString())),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: loc.dealFormTitleEdit,
                      onPressed: () => _showDealDialog(context, deal),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: loc.commonDelete,
                      onPressed: () => _confirmDelete(context, ref, deal),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        error: (e, s) => Center(
          child: Text(loc.adminDealsLoadError(e.toString())),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _showDealDialog(BuildContext context, Deal? deal) async {
    final loc = AppLocalizations.of(context)!;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BrandModalSheet(child: DealFormDialog(deal: deal)),
    );
    if (!context.mounted || saved != true) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deal == null ? loc.adminDealsCreateSuccess : loc.adminDealsUpdateSuccess,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Deal deal) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDestructiveActionDialog(
      context: context,
      title: loc.adminDealsDeleteTitle,
      message: loc.adminDealsDeleteMessage('${deal.partnerName}: ${deal.title}'),
      auditHint: loc.adminDealsDeleteAuditHint,
      confirmLabel: loc.commonDelete,
      cancelLabel: loc.commonCancel,
    );

    if (!confirmed) {
      return;
    }
    try {
      await OwnerActionObservabilityService.instance.trackAction(
        action: 'owner.deals.delete',
        command: () => ref.read(dealsRepositoryProvider).deleteDeal(deal.id),
      );
      if (!context.mounted) return;
      showUndoSnackBar(
        context: context,
        message: loc.adminDealsDeleted,
        onUndo: () => OwnerActionObservabilityService.instance.trackAction(
          action: 'owner.deals.undo_delete',
          command: () => ref.read(dealsRepositoryProvider).saveDeal(deal),
        ),
        undoLabel: loc.undo,
        undoSuccessMessage: loc.adminDealsRestored,
        undoErrorPrefix: loc.adminDealsUndoErrorPrefix,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(loc.adminDealsDeleteError(e.toString()))),
        );
      }
    }
  }
}
