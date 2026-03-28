import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../domain/models/reservation_model.dart';
import '../../../notifications/data/repositories/notification_repository.dart';

class FirestoreReservationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('reservations');

  /// Crée une réservation dans Firestore et décrémente les réservations de l'utilisateur
  Future<String> createReservation(ReservationModel reservation) async {
    return await _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(reservation.renterId);
      final userDoc = await transaction.get(userRef);
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final role = userData['role'] as String? ?? 'USER';
        if (role != 'OWNER' && role != 'ADMIN') {
          final remaining = (userData['remainingReservations'] as num?)?.toInt() ?? 0;
          if (remaining > 0) {
            transaction.update(userRef, {'remainingReservations': remaining - 1});
          } else {
            throw Exception('Plus de réservations disponibles.');
          }
        }
      }

      final resRef = _col.doc();
      transaction.set(resRef, reservation.toJson());
      return resRef.id;
    });
  }

  /// Récupère les réservations d'un locataire, triées par date décroissante
  Future<List<ReservationModel>> getReservationsByRenter(String uid) async {
    final snapshot = await _col
        .where('renterId', isEqualTo: uid)
        .get();
    final list = snapshot.docs
        .map((d) => ReservationModel.fromJson(d.data() as Map<String, dynamic>, d.id))
        .toList();
    list.sort((a, b) => b.startTime.compareTo(a.startTime));
    return list;
  }

  /// Version stream (temps réel) pour le locataire
  Stream<List<ReservationModel>> streamReservationsByRenter(String uid) {
    return _col
        .where('renterId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => ReservationModel.fromJson(d.data() as Map<String, dynamic>, d.id))
              .toList();
          list.sort((a, b) => b.startTime.compareTo(a.startTime));
          return list;
        });
  }

  /// Récupère les réservations reçues sur les machines d'un propriétaire
  Future<List<ReservationModel>> getReservationsByOwner(String ownerId) async {
    final snapshot = await _col
        .where('ownerId', isEqualTo: ownerId)
        .get();
    final list = snapshot.docs
        .map((d) => ReservationModel.fromJson(d.data() as Map<String, dynamic>, d.id))
        .toList();
    list.sort((a, b) => b.startTime.compareTo(a.startTime));
    return list;
  }

  /// Version stream (temps réel) pour le propriétaire
  Stream<List<ReservationModel>> streamReservationsByOwner(String ownerId) {
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => ReservationModel.fromJson(d.data() as Map<String, dynamic>, d.id))
              .toList();
          list.sort((a, b) => b.startTime.compareTo(a.startTime));
          return list;
        });
  }

  /// Crée une nouvelle réservation
  Future<void> addReservation(ReservationModel reservation) async {
    final docRef = _col.doc(reservation.id);
    await docRef.set(reservation.toJson());

    // Notification au propriétaire
    await NotificationRepository().sendNotification(
      userId: reservation.ownerId,
      title: 'Nouvelle demande 🧺',
      message: 'Quelqu\'un souhaite réserver votre machine le ${DateFormat("dd MMM à HH:mm", "fr").format(reservation.startTime)}.',
    );
  }

  /// Met à jour le statut d'une réservation
  Future<void> updateStatus(String reservationId, String newStatus) async {
    final docRef = _col.doc(reservationId);
    
    // Lire avant pour envoyer les notifs
    final rSnapshot = await docRef.get();
    if (!rSnapshot.exists) return;
    
    await docRef.update({'status': newStatus});
    
    final r = ReservationModel.fromJson(rSnapshot.data() as Map<String, dynamic>, rSnapshot.id);

    // Notifications vers le locataire
    if (newStatus == 'CONFIRMED' || newStatus == 'CANCELLED') {
      final title = newStatus == 'CONFIRMED' ? 'Réservation confirmée ✅' : 'Réservation refusée ❌';
      final msg = newStatus == 'CONFIRMED' ? 'Le propriétaire de ${r.machineBrand} a accepté votre demande.' : 'Le propriétaire a annulé ou refusé votre demande pour ${r.machineBrand}.';
      await NotificationRepository().sendNotification(userId: r.renterId, title: title, message: msg);
    }

    // Auto-cancel des autres PENDING conflictuelles si on confirme
    if (newStatus == 'CONFIRMED') {
      try {
        final pendingSnapshot = await _col.where('machineId', isEqualTo: r.machineId).get();
        final batch = FirebaseFirestore.instance.batch();
        bool hasOverlaps = false;

        for (final pDoc in pendingSnapshot.docs) {
          if (pDoc.id == reservationId) continue;
          final pRes = ReservationModel.fromJson(pDoc.data() as Map<String, dynamic>, pDoc.id);
          if (pRes.status == 'PENDING') {
            final overlaps = r.startTime.isBefore(pRes.endTime) && r.endTime.isAfter(pRes.startTime);
            if (overlaps) {
              batch.update(pDoc.reference, {'status': 'CANCELLED'});
              hasOverlaps = true;
            }
          }
        }
        if (hasOverlaps) await batch.commit();
      } catch (e) {
        // Ignorer l'erreur silencieusement en cas d'échec de batch
      }
    }
  }

  /// Nettoie les réservations PENDING dont l'heure de début est passée ou très proche (2h)
  Future<void> autoCancelGhostings(String userId, {required bool isOwner}) async {
    try {
      final snapshot = await _col.where(isOwner ? 'ownerId' : 'renterId', isEqualTo: userId).get();
      final batch = FirebaseFirestore.instance.batch();
      final limitDate = DateTime.now().add(const Duration(hours: 2));
      bool needsCommit = false;

      for (final doc in snapshot.docs) {
        final r = ReservationModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        if (r.status == 'PENDING' && r.startTime.isBefore(limitDate)) {
          batch.update(doc.reference, {'status': 'CANCELLED'});
          needsCommit = true;
        }
      }
      if (needsCommit) await batch.commit();
    } catch (e) {
      // Ignorer
    }
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
      final snapshot = await _col
          .where('machineId', isEqualTo: machineId)
          .get();

      for (final doc in snapshot.docs) {
        final r = ReservationModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        
        if (r.status != 'PENDING' && r.status != 'CONFIRMED') continue;

        // Chevauchement : la nouvelle plage intersecte une existante
        final overlaps = start.isBefore(r.endTime) && end.isAfter(r.startTime);
        if (overlaps) return false; // ← conflit trouvé
      }
      return true; // ← aucun conflit
    } catch (e) {
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
          .get();

      final bookedStarts = <DateTime>[];
      for (final doc in snapshot.docs) {
        final r = ReservationModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        
        if (r.status != 'PENDING' && r.status != 'CONFIRMED') continue;

        var current = r.startTime;
        while (current.isBefore(r.endTime)) {
          if (current.isAfter(dayStart.subtract(const Duration(seconds: 1))) && current.isBefore(dayEnd)) {
            bookedStarts.add(current);
          }
          current = current.add(const Duration(hours: 1));
        }
      }
      return bookedStarts;
    } catch (_) {
      return [];
    }
  }
}
