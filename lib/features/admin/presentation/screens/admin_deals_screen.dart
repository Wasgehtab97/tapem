import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_modal.dart';
import 'package:tapem/core/widgets/premium_action_tile.dart';
import 'package:tapem/features/deals/data/providers/deals_provider.dart';
import 'package:tapem/features/deals/domain/models/deal.dart';
import 'package:tapem/features/admin/presentation/widgets/deal_form_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDealsScreen extends ConsumerWidget {
  const AdminDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(allDealsStreamProvider);
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deals verwalten'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: brandTheme?.onBrand ?? theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 20),
                          ),
                        ),
                      )
                    : const Icon(Icons.tag_rounded),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: deal.isActive,
                      activeColor: brandTheme?.outline ?? theme.colorScheme.secondary,
                      onChanged: (val) async {
                        try {
                          await ref.read(dealsRepositoryProvider).saveDeal(deal.copyWith(isActive: val));
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Fehler: $e')),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showDealDialog(context, deal),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                      onPressed: () => _confirmDelete(context, ref, deal),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        error: (e, s) => Center(child: Text('Fehler: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showDealDialog(BuildContext context, Deal? deal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BrandModalSheet(
        child: DealFormDialog(deal: deal),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Deal deal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deal löschen?'),
        content: Text('Möchtest du den Deal "${deal.partnerName}: ${deal.title}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(dealsRepositoryProvider).deleteDeal(deal.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Löschen: $e')),
          );
        }
      }
    }
  }
}
