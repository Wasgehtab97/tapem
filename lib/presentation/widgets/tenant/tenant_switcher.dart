// lib/presentation/widgets/tenant/tenant_switcher.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapem/domain/models/tenant.dart';
import 'package:tapem/domain/usecases/tenant/fetch_all_tenants.dart';
import 'package:tapem/domain/usecases/tenant/get_saved_gym_id.dart';
import 'package:tapem/domain/usecases/tenant/switch_tenant.dart';
import 'package:tapem/presentation/widgets/common/loading_indicator.dart';

/// Widget, um zwischen verschiedenen Gyms (Tenants) zu wechseln.
class TenantSwitcher extends StatelessWidget {
  const TenantSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fetchUc = context.read<FetchAllTenantsUseCase>();
    final getIdUc = context.read<GetSavedGymIdUseCase>();
    final switchUc = context.read<SwitchTenantUseCase>();

    return FutureBuilder<List<Tenant>>(
      future: fetchUc(),
      builder: (ctx, snapTenants) {
        if (snapTenants.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (snapTenants.hasError) {
          return Tooltip(
            message: 'Gyms konnten nicht geladen werden',
            child: const Icon(Icons.error_outline, color: Colors.red),
          );
        }
        final tenants = snapTenants.data ?? [];

        return FutureBuilder<String?>(
          future: getIdUc(),
          builder: (ctx2, snapCurrent) {
            if (snapCurrent.connectionState == ConnectionState.waiting) {
              return const LoadingIndicator();
            }
            final currentId = snapCurrent.data;
            return DropdownButton<String>(
              value: currentId,
              hint: const Text('Gym wählen'),
              items: tenants.map((t) {
                return DropdownMenuItem(
                  value: t.gymId,
                  child: Row(
                    children: [
                      if (t.config.logoUrl.isNotEmpty)
                        Image.network(t.config.logoUrl, width: 24, height: 24),
                      const SizedBox(width: 8),
                      Text(t.config.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newId) async {
                if (newId != null && newId != currentId) {
                  await switchUc(newId);
                  // nach dem Wechsel aktualisieren wir die Seite neu
                  (ctx2 as Element).markNeedsBuild();
                }
              },
            );
          },
        );
      },
    );
  }
}
