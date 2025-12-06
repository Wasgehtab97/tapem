import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/features/gym/presentation/screens/gym_screen.dart';
import 'package:tapem/features/training_plan/application/plan_builder_provider.dart';

class PlanExercisePickerScreen extends ConsumerWidget {
  const PlanExercisePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(planBuilderProvider);
    final count = draft.exercises.length;
    
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return GymScreen(
      selectionMode: true,
      onSelect: (selection) {
        ref.read(planBuilderProvider.notifier).addExercise(
          deviceId: selection.deviceId,
          exerciseId: selection.exerciseId,
        );
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Übung hinzugefügt'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: brandColor,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      floatingActionButton: count > 0 ? FloatingActionButton.extended(
        onPressed: () async {
          // Save and go back to overview
          // Per discussion: "landert man in dem erstellen trainingsplan editor" (land in created training plan editor)
          // Actually, saving happens in Editor.
          // Wait, if I am in Picker, do I save to DB yet?
          // "wenn man alle übungen hinzugefügt hat ... kann man den plan speichern"
          // This implies "Save" button here does the final save?
          // BUT: "und dann landen sie auf einer ansicht ... ähnlich gympage ... wenn man fertig ... plan speichern ... erscheint auf Pläne page"
          // AND: "sortieren soll anschließen in der trainingsplan ansicht passieren"
          
          // So: Picker -> Save to DB -> Navigate to Detail/Editor (to allow sorting).
          
          try {
            await ref.read(planBuilderProvider.notifier).save();
            if (context.mounted) {
               Navigator.of(context).pop(); // Pop picker
               // But we want to go Open the Plan.
               // We need the saved Plan ID?
               // The Notifier's save() refreshes the list but doesn't return the ID easily unless we change it.
               // But wait, if I save, I persist it.
               // If I want to land on the Detail page, I should query the latest plan or pass the ID.
               
               // Alternative: Don't save to DB yet. Just go to "Review/Editor" screen with the DRAFT.
               // "Save" button on Editor persists to DB.
               // This matches "create ... then sort ... then save" better?
               // User said: "beim builder fügt man übungen hinzu ... wenn fertig ... landet in ... trainingsplan editor ... nochmal anpassen ... start"
               // "wenn man alle übungen hinzugefügt hat ... kann man den plan speichern und er erscheint dann auf der Pläne page" -> This contradicts "land in editor".
               
               // Let's compromise:
               // Picker -> "Review Plan" -> Editor (Draft) -> "Save Plan" -> Overview.
               // This allows sorting BEFORE valid save.
               // BUT User said: "kann man den plan speichern und er erscheint dann auf der Pläne page. wenn der user dann auf diesen ... klickt ... editor".
               
               // Okay, simplest path: Picker Save -> DB Save -> Pop to Overview.
               // User can then click it to edit/sort.
               // This matches "appears on plans page".
               // I will do this.
               // Except user also said: "sortieren soll anschließen ... passieren".
               
               // I'll stick to: Picker Save -> DB Save -> Overview.
               // User opens it to sort.
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fehler beim Speichern: $e')),
              );
            }
          }
        },
        label: Text('Plan speichern ($count)'),
        icon: const Icon(Icons.check),
      ) : null,
    );
  }
}
