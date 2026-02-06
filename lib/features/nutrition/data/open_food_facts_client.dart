import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/models/nutrition_product.dart';

class OpenFoodFactsClient {
  OpenFoodFactsClient({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _requestTimeout = Duration(seconds: 8);

  int _toInt(dynamic v) {
    if (v is num) return v.round();
    if (v is String) {
      final parsed = double.tryParse(v.replaceAll(',', '.'));
      if (parsed != null) return parsed.round();
    }
    return 0;
  }

  double _getNumber(
    Map<String, dynamic> source,
    List<String> keys, {
    double Function(double value)? transform,
  }) {
    for (final key in keys) {
      final raw = source[key];
      if (raw == null) continue;
      final parsed = double.tryParse(raw.toString().replaceAll(',', '.'));
      if (parsed != null) {
        return transform != null ? transform(parsed) : parsed;
      }
    }
    return 0;
  }

  Map<String, String> _searchLocaleParams() {
    final locale = PlatformDispatcher.instance.locale;
    final lc = locale.languageCode.trim().toLowerCase();
    final cc = (locale.countryCode ?? '').trim().toUpperCase();
    return {'lc': lc.isEmpty ? 'en' : lc, if (cc.isNotEmpty) 'cc': cc};
  }

  NutritionProduct _buildProduct(String barcode, Map<String, dynamic> product) {
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
    final kcal = _getNumber(nutriments, const [
      'energy-kcal_100g',
      'energy-kcal',
      'energy-kcal_value',
      'energy-kcal_serving',
    ]);
    final kJ = _getNumber(nutriments, const ['energy_100g', 'energy']);
    final kcalFinal = kcal > 0 ? kcal : (kJ > 0 ? kJ / 4.184 : 0);

    return NutritionProduct(
      barcode: barcode,
      name:
          (product['product_name'] as String?) ??
          (product['product_name_de'] as String?) ??
          (product['product_name_en'] as String?) ??
          barcode,
      kcalPer100: kcalFinal.round(),
      proteinPer100: _toInt(
        nutriments['proteins_100g'] ?? nutriments['proteins'],
      ),
      carbsPer100: _toInt(
        nutriments['carbohydrates_100g'] ?? nutriments['carbohydrates'],
      ),
      fatPer100: _toInt(nutriments['fat_100g'] ?? nutriments['fat']),
      updatedAt: DateTime.now(),
    );
  }

  Future<NutritionProduct?> fetchProduct(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return null;
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$code'
      '.json?fields=code,product_name,product_name_de,product_name_en,nutriments',
    );
    final http.Response res;
    try {
      res = await _client.get(uri).timeout(_requestTimeout);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final status = data['status'];
    if (!(status == 1 || status == '1')) return null;
    final product = data['product'] as Map<String, dynamic>? ?? {};
    final built = _buildProduct(code, product);
    if (kDebugMode) {
      debugPrint('[OFF] fetchProduct code=$code ok');
    }
    return built;
  }

  Future<List<NutritionProduct>> searchProducts(
    String query, {
    int pageSize = 20,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
      'search_terms': q,
      'search_simple': '1',
      'json': '1',
      'page': '1',
      'page_size': pageSize.toString(),
      'fields': 'code,product_name,product_name_de,product_name_en,nutriments',
      'sort_by': 'unique_scans_n',
      ..._searchLocaleParams(),
    });
    final http.Response res;
    try {
      res = await _client.get(uri).timeout(_requestTimeout);
    } on TimeoutException {
      return [];
    } catch (_) {
      return [];
    }
    if (res.statusCode != 200) {
      if (kDebugMode) {
        debugPrint('[OFF] search status=${res.statusCode}');
      }
      return [];
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final products = data['products'] as List<dynamic>? ?? const [];
    final results = <NutritionProduct>[];
    for (final raw in products) {
      if (raw is! Map<String, dynamic>) continue;
      final code = raw['code']?.toString().trim();
      if (code == null || code.isEmpty) continue;
      results.add(_buildProduct(code, raw));
    }
    if (kDebugMode) {
      debugPrint('[OFF] search "$q" -> ${results.length} results');
    }
    return results;
  }
}
