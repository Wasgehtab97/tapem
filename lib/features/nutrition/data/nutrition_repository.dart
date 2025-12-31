import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/nutrition_goal.dart';
import '../domain/models/nutrition_log.dart';
import '../domain/models/nutrition_year_summary.dart';
import '../domain/models/nutrition_product.dart';

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

  Future<void> updateYearStatus(
    String uid,
    int year,
    String dateKey,
    String status,
  ) async {
    final key = year.toString();
    await _userDoc(uid, 'nutrition_year_summary', key).set(
      {'days.$dateKey': status},
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
}
