import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_goal.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_log.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_year_summary.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_product.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_recipe.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_log.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_meta.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_year_summary.dart';

class NutritionRepository {
  final FirebaseFirestore _firestore;
  static final RegExp _dateKeyPattern = RegExp(r'^\d{8}$');

  NutritionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userCol(
    String uid,
    String collection,
  ) {
    final userId = uid.trim();
    if (userId.isEmpty) {
      throw StateError('Anmeldung erforderlich');
    }
    return _firestore.collection('users').doc(userId).collection(collection);
  }

  DocumentReference<Map<String, dynamic>> _userDoc(
    String uid,
    String collection,
    String docId,
  ) {
    return _userCol(uid, collection).doc(docId);
  }

  void _assertDateKey(String dateKey) {
    if (!_dateKeyPattern.hasMatch(dateKey)) {
      throw StateError('Ungueltiger Date-Key: $dateKey');
    }
  }

  void _assertYear(int year) {
    if (year < 2000 || year > 9999) {
      throw StateError('Ungueltiges Jahr: $year');
    }
  }

  double _normalizeWeightKg(num kg) {
    final value = kg.toDouble();
    if (!value.isFinite || value < 20 || value > 400) {
      throw StateError('Gewicht ausserhalb erlaubter Range (20-400 kg).');
    }
    return double.parse(value.toStringAsFixed(2));
  }

  Future<NutritionGoal?> fetchGoal(String uid, String dateKey) async {
    final snap = await _userDoc(uid, 'nutrition_goals', dateKey).get();
    if (!snap.exists || snap.data() == null) return null;
    return NutritionGoal.fromMap(snap.id, snap.data()!);
  }

  Future<void> upsertGoal(String uid, NutritionGoal goal) async {
    await _userDoc(
      uid,
      'nutrition_goals',
      goal.dateKey,
    ).set(goal.toMap(), SetOptions(merge: true));
  }

  Future<NutritionGoal?> fetchDefaultGoal(String uid) async {
    final snap = await _userDoc(
      uid,
      'nutrition_goal_defaults',
      'current',
    ).get();
    if (!snap.exists || snap.data() == null) return null;
    return NutritionGoal.fromMap(snap.id, snap.data()!);
  }

  Future<void> upsertDefaultGoal(String uid, NutritionGoal goal) async {
    await _userDoc(
      uid,
      'nutrition_goal_defaults',
      'current',
    ).set(goal.toMap(), SetOptions(merge: true));
  }

  Future<NutritionLog?> fetchLog(String uid, String dateKey) async {
    final snap = await _userDoc(uid, 'nutrition_logs', dateKey).get();
    if (!snap.exists || snap.data() == null) return null;
    return NutritionLog.fromMap(snap.id, snap.data()!);
  }

  Future<void> upsertLog(String uid, NutritionLog log) async {
    await _userDoc(
      uid,
      'nutrition_logs',
      log.dateKey,
    ).set(log.toMap(), SetOptions(merge: true));
  }

  Future<NutritionWeightLog?> fetchWeightLog(String uid, String dateKey) async {
    _assertDateKey(dateKey);
    final snap = await _userDoc(uid, 'nutrition_weight_logs', dateKey).get();
    if (!snap.exists || snap.data() == null) return null;
    return NutritionWeightLog.fromMap(snap.id, snap.data()!);
  }

  Future<void> upsertWeightLog(String uid, NutritionWeightLog log) async {
    _assertDateKey(log.dateKey);
    final normalizedKg = _normalizeWeightKg(log.kg);
    final normalized = NutritionWeightLog(
      dateKey: log.dateKey,
      kg: normalizedKg,
      source: log.source,
      updatedAt: log.updatedAt ?? DateTime.now(),
    );
    await _userDoc(
      uid,
      'nutrition_weight_logs',
      normalized.dateKey,
    ).set(normalized.toMap(), SetOptions(merge: true));
  }

  Future<NutritionWeightYearSummary?> fetchWeightYearSummary(
    String uid,
    int year,
  ) async {
    _assertYear(year);
    final key = year.toString();
    final snap = await _userDoc(
      uid,
      'nutrition_weight_year_summary',
      key,
    ).get();
    if (!snap.exists || snap.data() == null) return null;
    return NutritionWeightYearSummary.fromMap(year, snap.data()!);
  }

  Future<void> upsertWeightYearDay(
    String uid,
    int year,
    String dateKey, {
    required num kg,
    DateTime? updatedAt,
  }) async {
    _assertYear(year);
    _assertDateKey(dateKey);
    final normalizedKg = _normalizeWeightKg(kg);
    final timestamp = updatedAt ?? DateTime.now();
    await _userDoc(uid, 'nutrition_weight_year_summary', year.toString()).set({
      'days.$dateKey': {
        'kg': normalizedKg,
        'updatedAt': Timestamp.fromDate(timestamp),
      },
    }, SetOptions(merge: true));
  }

  Future<NutritionWeightMeta?> fetchCurrentWeight(String uid) async {
    final snap = await _userDoc(uid, 'nutrition_weight_meta', 'current').get();
    if (!snap.exists || snap.data() == null) return null;
    return NutritionWeightMeta.fromMap(snap.data()!);
  }

  Future<void> upsertCurrentWeight(
    String uid, {
    required num kg,
    required String dateKey,
    DateTime? updatedAt,
  }) async {
    _assertDateKey(dateKey);
    final normalizedKg = _normalizeWeightKg(kg);
    final meta = NutritionWeightMeta(
      kg: normalizedKg,
      dateKey: dateKey,
      updatedAt: updatedAt ?? DateTime.now(),
    );
    await _userDoc(
      uid,
      'nutrition_weight_meta',
      'current',
    ).set(meta.toMap(), SetOptions(merge: true));
  }

  Future<NutritionYearSummary?> fetchYearSummary(String uid, int year) async {
    final key = year.toString();
    final snap = await _userDoc(uid, 'nutrition_year_summary', key).get();
    if (!snap.exists || snap.data() == null) return null;
    return NutritionYearSummary.fromMap(year, snap.data()!);
  }

  Future<void> updateYearDay(
    String uid,
    int year,
    String dateKey,
    String status, {
    required int goal,
    required int total,
  }) async {
    final key = year.toString();
    await _userDoc(uid, 'nutrition_year_summary', key).set({
      'days.$dateKey': {'status': status, 'goal': goal, 'total': total},
    }, SetOptions(merge: true));
  }

  Future<NutritionProduct?> fetchProduct(String barcode) async {
    final snap = await _firestore
        .collection('nutrition_products')
        .doc(barcode)
        .get();
    if (!snap.exists || snap.data() == null) return null;
    return NutritionProduct.fromMap(snap.id, snap.data()!);
  }

  Future<void> upsertProduct(NutritionProduct product) async {
    await _firestore
        .collection('nutrition_products')
        .doc(product.barcode)
        .set(product.toMap(), SetOptions(merge: true));
  }

  // --- Recipes ---
  Future<List<NutritionRecipe>> fetchRecipes(String uid) async {
    final snap = await _userCol(uid, 'nutrition_recipes').orderBy('name').get();
    return snap.docs
        .map((d) => NutritionRecipe.fromMap(d.id, d.data()))
        .toList();
  }

  Future<String> upsertRecipe(String uid, NutritionRecipe recipe) async {
    final col = _userCol(uid, 'nutrition_recipes');
    final docId = recipe.id.isEmpty ? col.doc().id : recipe.id;
    await col
        .doc(docId)
        .set(
          recipe.copyWith(id: docId, updatedAt: DateTime.now()).toMap(),
          SetOptions(merge: true),
        );
    return docId;
  }

  Future<void> deleteRecipe(String uid, String id) async {
    if (id.isEmpty) return;
    await _userCol(uid, 'nutrition_recipes').doc(id).delete();
  }
}
