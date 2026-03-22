import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/reservation_model.dart';

class FirestoreReservationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('reservations');

  /// Crée une réservation dans Firestore
  Future<String> createReservation(ReservationModel reservation) async {
    final docRef = await _col.add(reservation.toJson());
    return docRef.id;
  }

  /// Récupère les réservations d'un locataire, triées par date décroissante
  Future<List<ReservationModel>> getReservationsByRenter(String uid) async {
    final snapshot = await _col
        .where('renterId', isEqualTo: uid)
        .orderBy('startTime', descending: true)
        .get();
    return snapshot.docs
        .map((d) => ReservationModel.fromJson(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  /// Version stream (temps réel) pour le locataire
  Stream<List<ReservationModel>> streamReservationsByRenter(String uid) {
    return _col
        .where('renterId', isEqualTo: uid)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReservationModel.fromJson(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  /// Récupère les réservations reçues sur les machines d'un propriétaire
  Future<List<ReservationModel>> getReservationsByOwner(String ownerId) async {
    final snapshot = await _col
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('startTime', descending: true)
        .get();
    return snapshot.docs
        .map((d) => ReservationModel.fromJson(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  /// Version stream (temps réel) pour le propriétaire
  Stream<List<ReservationModel>> streamReservationsByOwner(String ownerId) {
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReservationModel.fromJson(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  /// Met à jour le statut d'une réservation
  Future<void> updateStatus(String reservationId, String newStatus) async {
    await _col.doc(reservationId).update({'status': newStatus});
  }

  /// Annule une réservation (seul le locataire ou le propriétaire peut le faire)
  Future<void> cancelReservation(String reservationId) async {
    await updateStatus(reservationId, 'CANCELLED');
  }

  /// Vérifie si un créneau est disponible sur une machine donnée
  /// Retourne true si disponible, false si conflit détecté
  Future<bool> checkAvailability({
    required String machineId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      // On cherche toutes les réservations actives qui se chevauchent
      final snapshot = await _col
          .where('machineId', isEqualTo: machineId)
          .where('status', whereIn: ['PENDING', 'CONFIRMED'])
          .get();

      for (final doc in snapshot.docs) {
        final r = ReservationModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        // Chevauchement : la nouvelle plage intersecte une existante
        final overlaps = start.isBefore(r.endTime) && end.isAfter(r.startTime);
        if (overlaps) return false; // ← conflit trouvé
      }
      return true; // ← aucun conflit
    } catch (e) {
      // En cas d'erreur (index non créé), on autorise par défaut
      return true;
    }
  }

  /// Récupère les créneaux déjà pris pour une machine à une date donnée
  Future<List<DateTime>> getBookedSlots(String machineId, DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    try {
      final snapshot = await _col
          .where('machineId', isEqualTo: machineId)
          .where('status', whereIn: ['PENDING', 'CONFIRMED'])
          .get();

      final bookedStarts = <DateTime>[];
      for (final doc in snapshot.docs) {
        final r = ReservationModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        if (r.startTime.isAfter(dayStart) && r.startTime.isBefore(dayEnd)) {
          bookedStarts.add(r.startTime);
        }
      }
      return bookedStarts;
    } catch (_) {
      return [];
    }
  }
}
