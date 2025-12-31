import '../domain/models/nutrition_product.dart';
import 'nutrition_product_cache_store.dart';
import 'nutrition_repository.dart';
import 'open_food_facts_client.dart';

class NutritionProductService {
  final NutritionRepository _repo;
  final NutritionProductCacheStore _cache;
  final OpenFoodFactsClient _api;

  bool _isEmptyProduct(NutritionProduct? p) {
    if (p == null) return true;
    return p.kcalPer100 == 0 &&
        p.proteinPer100 == 0 &&
        p.carbsPer100 == 0 &&
        p.fatPer100 == 0;
  }

  NutritionProductService({
    required NutritionRepository repository,
    required NutritionProductCacheStore cache,
    OpenFoodFactsClient? api,
  })  : _repo = repository,
        _cache = cache,
        _api = api ?? OpenFoodFactsClient();

  Future<NutritionProduct?> getByBarcode(String barcode) async {
    final cached = _cache.get(barcode);
    if (cached != null && !_isEmptyProduct(cached)) return cached;
    NutritionProduct? remote;
    try {
      remote = await _repo.fetchProduct(barcode);
    } catch (_) {
      remote = null;
    }
    if (remote != null && !_isEmptyProduct(remote)) {
      await _cache.put(remote);
      return remote;
    }
    final apiProduct = await _api.fetchProduct(barcode);
    if (apiProduct != null) {
      try {
        await _repo.upsertProduct(apiProduct);
      } catch (_) {
        // Ignore Firestore write errors; still return OFF data.
      }
      await _cache.put(apiProduct);
    }
    return apiProduct;
  }

  Future<void> saveProduct(NutritionProduct product) async {
    await _repo.upsertProduct(product);
    await _cache.put(product);
  }

  Future<List<NutritionProduct>> searchByName(String query) async {
    return _api.searchProducts(query);
  }
}
