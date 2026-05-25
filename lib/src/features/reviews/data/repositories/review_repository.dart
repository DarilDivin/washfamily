import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/review_model.dart';

part 'review_repository.g.dart';

@Riverpod(keepAlive: true)
ReviewRepository reviewRepository(ReviewRepositoryRef ref) {
  return ReviewRepository();
}

/// Provider de stream d'avis pour une machine — consommé dans MachineDetailScreen.
@riverpod
Stream<List<ReviewModel>> reviewsStream(ReviewsStreamRef ref, String machineId) {
  return ref.watch(reviewRepositoryProvider).streamReviewsByMachine(machineId);
}

class ReviewRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _reviews => _db.collection('reviews');
  CollectionReference get _machines => _db.collection('machines');
  CollectionReference get _reservations => _db.collection('reservations');

  /// Soumet un avis de façon atomique.
  /// L'ID du document review == reservationId : unicité naturelle.
  Future<void> submitReview(ReviewModel review) async {
    final reviewRef = _reviews.doc(review.reservationId);
    final machineRef = _machines.doc(review.machineId);
    final reservationRef = _reservations.doc(review.reservationId);

    await _db.runTransaction((tx) async {
      // 1. Vérification unicité
      final reviewDoc = await tx.get(reviewRef);
      if (reviewDoc.exists) throw Exception('already_reviewed');

      // 2. Lecture des stats machine
      final machineDoc = await tx.get(machineRef);
      final stats = (machineDoc.data() as Map<String, dynamic>?)?['stats']
          as Map<String, dynamic>?;
      final oldRating = (stats?['rating'] as num?)?.toDouble() ?? 0.0;
      final oldCount = (stats?['reviewCount'] as num?)?.toInt() ?? 0;

      // 3. Calcul du nouveau rating pondéré
      final newCount = oldCount + 1;
      final newRating = ((oldRating * oldCount) + review.rating) / newCount;

      // 4. Écriture atomique
      tx.set(reviewRef, review.toJson());
      tx.update(machineRef, {
        'stats.rating': newRating,
        'stats.reviewCount': newCount,
      });
      tx.update(reservationRef, {'hasBeenReviewed': true});
    });
  }

  Future<List<ReviewModel>> getReviewsByMachine(String machineId) async {
    final snap = await _reviews
        .where('machineId', isEqualTo: machineId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => ReviewModel.fromJson(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  /// Stream temps-réel des avis d'une machine, triés par date DESC.
  /// Index Firestore requis : (machineId ASC, createdAt DESC)
  Stream<List<ReviewModel>> streamReviewsByMachine(String machineId) {
    return _reviews
        .where('machineId', isEqualTo: machineId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                ReviewModel.fromJson(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<bool> hasReviewed(String reservationId) async {
    final doc = await _reviews.doc(reservationId).get();
    return doc.exists;
  }
}
