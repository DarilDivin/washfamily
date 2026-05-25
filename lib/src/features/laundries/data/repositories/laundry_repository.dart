import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/laundry_model.dart';

class LaundryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('laundries');

  /// Stream de toutes les laveries actives pour la carte
  Stream<List<LaundryModel>> streamActiveLaundries() {
    return _col
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LaundryModel.fromJson(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  /// Récupère une laverie par son id
  Future<LaundryModel?> getLaundryById(String laundryId) async {
    final doc = await _col.doc(laundryId).get();
    if (!doc.exists) return null;
    return LaundryModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Stream temps réel d'une laverie spécifique
  Stream<LaundryModel?> streamLaundry(String laundryId) {
    return _col.doc(laundryId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return LaundryModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Récupère la laverie du propriétaire connecté (null si aucune)
  Future<LaundryModel?> getOwnerLaundry(String ownerId) async {
    final snap = await _col
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return LaundryModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Crée une nouvelle laverie — retourne le laundryId créé
  Future<String> createLaundry(LaundryModel laundry) async {
    final ref = await _col.add(laundry.toJson());
    return ref.id;
  }

  /// Met à jour les champs d'une laverie existante
  Future<void> updateLaundry(String laundryId, Map<String, dynamic> fields) async {
    await _col.doc(laundryId).update(fields);
  }

  /// Active ou désactive une laverie
  Future<void> setLaundryActive(String laundryId, bool isActive) async {
    await _col.doc(laundryId).update({'isActive': isActive});
  }

  /// Recalcule et met à jour le rating après une nouvelle review (transaction atomique)
  Future<void> updateRating({
    required String laundryId,
    required int newRating,
  }) async {
    final ref = _col.doc(laundryId);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final currentCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
      final currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;

      final newCount = currentCount + 1;
      final newAverage =
          ((currentRating * currentCount) + newRating) / newCount;

      tx.update(ref, {
        'reviewCount': newCount,
        'rating': double.parse(newAverage.toStringAsFixed(1)),
      });
    });
  }
}
