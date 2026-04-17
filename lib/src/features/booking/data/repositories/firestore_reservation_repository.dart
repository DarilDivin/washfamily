import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../domain/models/reservation_model.dart';
import '../../../notifications/data/repositories/notification_repository.dart';

class FirestoreReservationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('reservations');

  /// Crée une réservation dans Firestore, décrémente le quota et envoie la notification au propriétaire.
  /// Retourne la réservation complète avec son vrai ID Firestore.
  Future<ReservationModel> createReservation(ReservationModel reservation) async {
    String newId = '';

    await _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(reservation.renterId);
      final userDoc = await transaction.get(userRef);

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final roles = userData['roles'] != null
            ? List<String>.from(userData['roles'] as List)
            : [(userData['role'] as String? ?? 'USER')];
        if (!roles.contains('OWNER') && !roles.contains('ADMIN')) {
          // Vérification expiration de l'abonnement
          final endDateRaw = userData['subscriptionEndDate'];
          if (endDateRaw != null) {
            final endDate = (endDateRaw as Timestamp).toDate();
            if (endDate.isBefore(DateTime.now())) {
              throw Exception('subscription_expired');
            }
          }

          final remaining = (userData['remainingReservations'] as num?)?.toInt() ?? 0;
          if (remaining > 0) {
            transaction.update(userRef, {'remainingReservations': remaining - 1});
          } else {
            throw Exception('quota_exceeded');
          }
        }
      }

      final resRef = _col.doc();
      newId = resRef.id;
      transaction.set(resRef, reservation.toJson());
    });

    // Notification au propriétaire (hors transaction pour ne pas la bloquer)
    try {
      await NotificationRepository().sendNotification(
        userId: reservation.ownerId,
        title: 'Nouvelle demande 🧺',
        message: 'Une réservation a été demandée pour votre machine le ${DateFormat("dd MMM à HH:mm", "fr").format(reservation.startTime)}.',
      );
    } catch (_) {
      // La notification n'est pas critique — on ne bloque pas le flux
    }

    return reservation.copyWith(id: newId);
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

  /// Met à jour le statut d'une réservation
  Future<void> updateStatus(String reservationId, String newStatus, {String? cancelReason}) async {
    final docRef = _col.doc(reservationId);
    
    // Lire avant pour envoyer les notifs
    final rSnapshot = await docRef.get();
    if (!rSnapshot.exists) return;
    
    await docRef.update({'status': newStatus});
    
    final r = ReservationModel.fromJson(rSnapshot.data() as Map<String, dynamic>, rSnapshot.id);

    // Notifications vers le locataire
    if (newStatus == 'CONFIRMED' || newStatus == 'CANCELLED') {
      final title = newStatus == 'CONFIRMED' ? 'Réservation confirmée ✅' : 'Réservation refusée ❌';
      String msg;
      if (newStatus == 'CONFIRMED') {
        msg = 'Le propriétaire de ${r.machineBrand} a accepté votre demande pour le ${DateFormat("d MMM à HH:mm", "fr").format(r.startTime)}.';
      } else {
        msg = cancelReason != null && cancelReason.isNotEmpty
            ? 'Votre demande pour ${r.machineBrand} a été refusée. Raison : $cancelReason'
            : 'Le propriétaire a refusé votre demande pour ${r.machineBrand}.';
      }
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

  /// Vérifie les réservations CONFIRMED qui commencent dans les 24h et envoie un rappel si pas encore fait.
  Future<void> checkAndSendReminders(String userId) async {
    try {
      final now = DateTime.now();
      final in24h = now.add(const Duration(hours: 24));

      final snapshot = await _col
          .where('renterId', isEqualTo: userId)
          .where('status', isEqualTo: 'CONFIRMED')
          .where('reminderSent', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        final r = ReservationModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        if (r.startTime.isAfter(now) && r.startTime.isBefore(in24h)) {
          await NotificationRepository().sendNotification(
            userId: userId,
            title: 'Rappel de RDV ⏰',
            message: 'Votre réservation pour ${r.machineBrand} commence ${_formatRelative(r.startTime, now)}.',
          );
          await doc.reference.update({'reminderSent': true});
        }
      }
    } catch (_) {}
  }

  String _formatRelative(DateTime start, DateTime now) {
    final diff = start.difference(now);
    if (diff.inMinutes < 60) return 'dans ${diff.inMinutes} min';
    if (diff.inHours < 2) return 'dans 1h';
    return 'dans ${diff.inHours}h (${DateFormat("HH:mm").format(start)})';
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
