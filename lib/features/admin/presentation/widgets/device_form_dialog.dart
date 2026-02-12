import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/manufacturer/domain/models/manufacturer.dart';
import 'package:tapem/features/manufacturer/providers/manufacturer_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_modal.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';

class DeviceFormDialog extends ConsumerStatefulWidget {
  const DeviceFormDialog({
    super.key,
    required this.muscleGroups,
    required this.onSave,
    this.initialDevice,
    this.nextDeviceId,
  });

  final int? nextDeviceId;
  final Device? initialDevice;
  final List<MuscleGroup> muscleGroups;
  final Future<void> Function(
    String name,
    String description,
    bool isMulti,
    List<String> muscleGroupIds,
    String? manufacturerId,
    String? manufacturerName,
  ) onSave;

  @override
  ConsumerState<DeviceFormDialog> createState() => _DeviceFormDialogState();
}

class _DeviceFormDialogState extends ConsumerState<DeviceFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late bool _isMulti;
  final Set<String> _selectedMuscleGroups = {};
  Manufacturer? _selectedManufacturer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final device = widget.initialDevice;
    _nameCtrl = TextEditingController(text: device?.name);
    _descCtrl = TextEditingController(text: device?.description);
    _isMulti = device?.isMulti ?? false;

    if (device != null) {
      // Use muscleGroupIds if available, fallback to primary groups
      final ids = device.muscleGroupIds.isNotEmpty
          ? device.muscleGroupIds
          : device.primaryMuscleGroups;
      _selectedMuscleGroups.addAll(ids);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.outline ?? theme.colorScheme.secondary;
    final isEdit = widget.initialDevice != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: BrandModalSurface(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandModalHeader(
                title: isEdit ? 'Gerät bearbeiten' : 'Neues Gerät anlegen',
                subtitle: isEdit ? 'UID: ${widget.initialDevice?.uid}' : 'ID: ${widget.nextDeviceId}',
                icon: isEdit ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                accent: accent,
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: 24),
              
              // Name Input
              _PremiumTextField(
                controller: _nameCtrl,
                label: 'Name',
                hint: 'z.B. Beinpresse',
                icon: Icons.fitness_center_rounded,
              ),
              const SizedBox(height: 16),

              // Manufacturer Dropdown
              _ManufacturerDropdown(
                selectedManufacturerId: _selectedManufacturer?.id ?? widget.initialDevice?.manufacturerId,
                onChanged: (m) => setState(() => _selectedManufacturer = m),
                accent: accent,
              ),
              const SizedBox(height: 16),

              // Description Input
              _PremiumTextField(
                controller: _descCtrl,
                label: 'Beschreibung',
                hint: 'Optional (Model etc.)',
                icon: Icons.description_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Multi-Device Switch
              _PremiumSwitchTile(
                title: 'Inkludiert mehrere Übungen?',
                subtitle: 'Für Kabelzüge oder Racks',
                value: _isMulti,
                onChanged: (val) => setState(() => _isMulti = val),
                accent: accent,
              ),
              const SizedBox(height: 24),

              // Muscle Groups (Shown only if not multi-device)
              if (!_isMulti) ...[
                Text(
                  'Muskelgruppen',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.muscleGroups.map((group) {
                    final isSelected = _selectedMuscleGroups.contains(group.id);
                    return FilterChip(
                      label: Text(group.name),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedMuscleGroups.add(group.id);
                          } else {
                            _selectedMuscleGroups.remove(group.id);
                          }
                        });
                      },
                      backgroundColor: Colors.white.withOpacity(0.05),
                      selectedColor: accent.withOpacity(0.2),
                      checkmarkColor: accent,
                      labelStyle: TextStyle(
                        color: isSelected ? accent : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected 
                              ? accent.withOpacity(0.5) 
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white60,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Abbrechen'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isEdit ? 'Speichern' : 'Erstellen',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Namen ein.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // For Edit, we might keep the existing manufacturer if no new one selected
      final mId = _selectedManufacturer?.id ?? widget.initialDevice?.manufacturerId;
      final mName = _selectedManufacturer?.name ?? widget.initialDevice?.manufacturerName;

      await widget.onSave(
        name,
        _descCtrl.text.trim(),
        _isMulti,
        _selectedMuscleGroups.toList(),
        mId,
        mName,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white60,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: Icon(icon, color: Colors.white54, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumSwitchTile extends StatelessWidget {
  const _PremiumSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
     required this.accent,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? accent.withOpacity(0.1) : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? accent.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: accent,
            activeTrackColor: accent.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

class _ManufacturerDropdown extends ConsumerWidget {
  final String? selectedManufacturerId;
  final ValueChanged<Manufacturer?> onChanged;
  final Color accent;

  const _ManufacturerDropdown({
    required this.selectedManufacturerId,
    required this.onChanged,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manufacturersAsync = ref.watch(gymManufacturersProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hersteller',
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white60,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        manufacturersAsync.when(
          loading: () => const Center(child: LinearProgressIndicator()),
          error: (err, st) => Text('Fehler beim Laden', style: TextStyle(color: theme.colorScheme.error)),
          data: (manufacturers) {
            if (manufacturers.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white38, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: const Text(
                        'Keine Hersteller aktiviert.',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRouter.manageManufacturers),
                      child: const Text('Verwalten'),
                    ),
                  ],
                ),
              );
            }

            Manufacturer? selected;
            if (selectedManufacturerId != null) {
              try {
                selected = manufacturers.firstWhere((m) => m.id == selectedManufacturerId);
              } catch (_) {}
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Manufacturer>(
                  value: selected,
                  hint: const Text('Hersteller wählen', style: TextStyle(color: Colors.white38)),
                  isExpanded: true,
                  dropdownColor: Colors.grey[900],
                  icon: Icon(Icons.keyboard_arrow_down, color: accent),
                  items: manufacturers.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(m.name, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
