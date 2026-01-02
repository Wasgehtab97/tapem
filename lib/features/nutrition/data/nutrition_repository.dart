import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/nutrition_goal.dart';
import '../domain/models/nutrition_log.dart';
import '../domain/models/nutrition_year_summary.dart';
import '../domain/models/nutrition_product.dart';
import '../domain/models/nutrition_recipe.dart';

class NutritionRepository {
  final FirebaseFirestore _firestore;
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

  Future<NutritionGoal?> fetchGoal(String uid, String dateKey) async {
    final snap = await _userDoc(uid, 'nutrition_goals', dateKey).get();
    if (!snap.exists || snap.data() == null) return null;
    return NutritionGoal.fromMap(snap.id, snap.data()!);
  }

  Future<void> upsertGoal(String uid, NutritionGoal goal) async {
    await _userDoc(uid, 'nutrition_goals', goal.dateKey)
        .set(goal.toMap(), SetOptions(merge: true));
  }

  Future<NutritionGoal?> fetchDefaultGoal(String uid) async {
    final snap = await _userDoc(uid, 'nutrition_goal_defaults', 'current').get();
    if (!snap.exists || snap.data() == null) return null;
    return NutritionGoal.fromMap(snap.id, snap.data()!);
  }

  Future<void> upsertDefaultGoal(String uid, NutritionGoal goal) async {
    await _userDoc(uid, 'nutrition_goal_defaults', 'current')
        .set(goal.toMap(), SetOptions(merge: true));
  }

  Future<NutritionLog?> fetchLog(String uid, String dateKey) async {
    final snap = await _userDoc(uid, 'nutrition_logs', dateKey).get();
    if (!snap.exists || snap.data() == null) return null;
    return NutritionLog.fromMap(snap.id, snap.data()!);
  }

  Future<void> upsertLog(String uid, NutritionLog log) async {
    await _userDoc(uid, 'nutrition_logs', log.dateKey)
        .set(log.toMap(), SetOptions(merge: true));
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
  }
  ) async {
    final key = year.toString();
    await _userDoc(uid, 'nutrition_year_summary', key).set(
      {
        'days.$dateKey': {
          'status': status,
          'goal': goal,
          'total': total,
        }
      },
      SetOptions(merge: true),
    );
  }

  Future<NutritionProduct?> fetchProduct(String barcode) async {
    final snap = await _firestore.collection('nutrition_products').doc(barcode).get();
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
    final snap =
        await _userCol(uid, 'nutrition_recipes').orderBy('name').get();
    return snap.docs
        .map((d) => NutritionRecipe.fromMap(d.id, d.data()))
        .toList();
  }

  Future<String> upsertRecipe(String uid, NutritionRecipe recipe) async {
    final col = _userCol(uid, 'nutrition_recipes');
    final docId = recipe.id.isEmpty ? col.doc().id : recipe.id;
    await col.doc(docId).set(
          recipe
              .copyWith(id: docId, updatedAt: DateTime.now())
              .toMap(),
          SetOptions(merge: true),
        );
    return docId;
  }

  Future<void> deleteRecipe(String uid, String id) async {
    if (id.isEmpty) return;
    await _userCol(uid, 'nutrition_recipes').doc(id).delete();
  }
}
