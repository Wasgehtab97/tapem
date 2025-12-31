import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';
import '../data/nutrition_product_cache_store.dart';
import '../data/nutrition_product_service.dart';
import '../data/nutrition_repository.dart';

final nutritionProductServiceProvider = Provider<NutritionProductService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NutritionProductService(
    repository: NutritionRepository(),
    cache: NutritionProductCacheStore(prefs),
  );
});
