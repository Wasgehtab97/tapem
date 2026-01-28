import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_calendar_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_day_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_entry_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_goals_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_home_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_product_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_recipe_edit_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_recipe_list_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_scan_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_search_screen.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_product.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_recipe.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';

/// Separater Navigator-Stack für die Ernährungs-Section, damit die BottomTabbar
/// sichtbar bleibt. Alle Nutrition-Routen laufen hier durch.
class _OverlayCloseObserver extends NavigatorObserver {
  final OverlayNumericKeypadController controller;
  _OverlayCloseObserver(this.controller);

  void _close() {
    controller.close();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _close();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _close();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _close();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _close();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class NutritionTabNavigator extends ConsumerWidget {
  const NutritionTabNavigator({super.key});

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRouter.nutrition:
      case AppRouter.nutritionHome:
        return MaterialPageRoute(builder: (_) => const NutritionHomeScreen());
      case AppRouter.nutritionDay:
        return MaterialPageRoute(builder: (_) => const NutritionDayScreen());
      case AppRouter.nutritionGoals:
        return MaterialPageRoute(builder: (_) => const NutritionGoalsScreen());
      case AppRouter.nutritionCalendar:
        return MaterialPageRoute(builder: (_) => const NutritionCalendarScreen());
      case AppRouter.nutritionSearch:
        return MaterialPageRoute(builder: (_) => const NutritionSearchScreen());
      case AppRouter.nutritionRecipes:
        final args = settings.arguments as Map<String, dynamic>? ?? const {};
        return MaterialPageRoute(
          builder: (_) => NutritionRecipeListScreen(
            meal: args['meal'] as String?,
            isSelectionMode: args['isSelectionMode'] as bool? ?? false,
            date: args['date'] as DateTime?,
          ),
        );
      case AppRouter.nutritionRecipeEdit:
        final rawArgs = settings.arguments;
        NutritionRecipe? recipe;
        bool isLogMode = false;
        String? logMeal;
        DateTime? logDate;

        if (rawArgs is NutritionRecipe) {
          recipe = rawArgs;
        } else if (rawArgs is Map) {
          final val = rawArgs['recipe'];
          if (val is NutritionRecipe) {
            recipe = val;
          }
           isLogMode = rawArgs['isLogMode'] as bool? ?? false;
           logMeal = rawArgs['meal'] as String?;
           logDate = rawArgs['date'] as DateTime?;

        }
        return MaterialPageRoute(
            builder: (_) => NutritionRecipeEditScreen(
                  recipe: recipe,
                  isLogMode: isLogMode,
                  logMeal: logMeal,
                  logDate: logDate,
                ));
      case AppRouter.nutritionEntry:
        final args = settings.arguments as Map<String, dynamic>? ?? const {};
        return MaterialPageRoute(
          builder: (_) => NutritionEntryScreen(
            initialBarcode: args['barcode'] as String?,
            initialName: args['name'] as String?,
            initialMeal: args['meal'] as String? ?? 'breakfast',
            initialProduct: args['product'] as NutritionProduct?,
            initialQty: (args['qty'] as num?)?.toDouble(),
            entryIndex: args['index'] as int?,
          ),
        );
      case AppRouter.nutritionScan:
        final args = settings.arguments as Map<String, dynamic>? ?? const {};
        return MaterialPageRoute(
          builder: (_) => NutritionScanScreen(
            initialMeal: args['meal'] as String? ?? 'breakfast',
            returnBarcode: args['returnBarcode'] as bool? ?? false,
          ),
        );
      case AppRouter.nutritionProduct:
        final args = settings.arguments as Map<String, dynamic>? ?? const {};
        return MaterialPageRoute(
          builder: (_) => NutritionProductScreen(
            barcode: args['barcode'] as String? ?? '',
            initialMeal: args['meal'] as String? ?? 'breakfast',
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => const NutritionDayScreen());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keypad = ref.watch(overlayNumericKeypadControllerProvider);
    return Navigator(
      initialRoute: AppRouter.nutritionDay,
      onGenerateRoute: _onGenerateRoute,
      observers: [
        _OverlayCloseObserver(keypad),
      ],
    );
  }
}
