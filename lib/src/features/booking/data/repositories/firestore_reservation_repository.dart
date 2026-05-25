import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../domain/models/reservation_model.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../../messaging/data/repositories/messaging_repository.dart';
import '../../../laundries/data/repositories/laundry_product_repository.dart';

class FirestoreReservationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final MessagingRepository _messagingRepo;
  final LaundryProductRepository _productRepo;

  FirestoreReservationRepository({
    MessagingRepository? messagingRepo,
    LaundryProductRepository? productRepo,
  })  : _messagingRepo = messagingRepo ?? MessagingRepository(),
        _productRepo = productRepo ?? LaundryProductRepository();

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

    // Création de la conversation messaging si on confirme
    if (newStatus == 'CONFIRMED') {
      try {
        final existing = await _messagingRepo
            .getConversationByReservationId(reservationId);
        if (existing == null) {
          await _messagingRepo.createConversation(
            reservationId: reservationId,
            machineId: r.machineId,
            locataireId: r.renterId,
            proprietaireId: r.ownerId,
            laundryId: r.laundryId,
          );
        }
      } catch (_) {
        // Non critique — on ne bloque pas le flux
      }
    }

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

    // Auto-cancel des autres PENDING conflictuelles si on confirme.
    // Index Firestore requis : (machineId ASC, status ASC, endTime ASC)
    if (newStatus == 'CONFIRMED') {
      try {
        // Filtre serveur : PENDING sur cette machine dont la fin dépasse
        // le début de la réservation confirmée → seuls les candidats au conflit.
        final pendingSnapshot = await _col
            .where('machineId', isEqualTo: r.machineId)
            .where('status', isEqualTo: 'PENDING')
            .where('endTime', isGreaterThan: Timestamp.fromDate(r.startTime))
            .get();

        final batch = FirebaseFirestore.instance.batch();
        bool hasOverlaps = false;

        for (final pDoc in pendingSnapshot.docs) {
          if (pDoc.id == reservationId) continue;
          final pRes = ReservationModel.fromJson(pDoc.data() as Map<String, dynamic>, pDoc.id);
          final overlaps = r.startTime.isBefore(pRes.endTime) && r.endTime.isAfter(pRes.startTime);
          if (overlaps) {
            batch.update(pDoc.reference, {'status': 'CANCELLED'});
            hasOverlaps = true;
          }
        }
        if (hasOverlaps) await batch.commit();
      } catch (e) {
        // Non critique — on ne bloque pas le flux
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

  /// Nettoie les réservations PENDING dont l'heure de début est passée ou très proche (2h).
  /// Index Firestore requis : (ownerId ASC, status ASC, startTime ASC)
  ///                      et : (renterId ASC, status ASC, startTime ASC)
  Future<void> autoCancelGhostings(String userId, {required bool isOwner}) async {
    try {
      final limitDate = DateTime.now().add(const Duration(hours: 2));
      // Filtre serveur : PENDING de cet utilisateur dont le début est déjà dépassé.
      final snapshot = await _col
          .where(isOwner ? 'ownerId' : 'renterId', isEqualTo: userId)
          .where('status', isEqualTo: 'PENDING')
          .where('startTime', isLessThan: Timestamp.fromDate(limitDate))
          .get();

      if (snapshot.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'status': 'CANCELLED'});
      }
      await batch.commit();
    } catch (e) {
      // Non critique
    }
  }

  /// Annule une réservation (seul le locataire ou le propriétaire peut le faire)
  Future<void> cancelReservation(String reservationId) async {
    await updateStatus(reservationId, 'CANCELLED');
  }

  static const _ownerAllowedStatuses = [
    'CONFIRMED',
    'PICKED_UP',
    'IN_PROGRESS',
    'READY',
    'COMPLETED',
    'CANCELLED',
  ];

  /// Met à jour le statut depuis le côté propriétaire.
  ///
  /// CONFIRMED  → transaction atomique : décrémente le stock de chaque produit
  ///              sélectionné + met à jour le statut.
  ///              Throw 'product_out_of_stock:{name}' si un produit est épuisé.
  /// CANCELLED  → si le statut précédent était CONFIRMED, ré-incrémente le stock.
  /// Autres     → délègue à updateStatus.
  Future<void> updateStatusByOwner(String reservationId, String newStatus) async {
    if (!_ownerAllowedStatuses.contains(newStatus)) {
      throw Exception('invalid_status');
    }

    if (newStatus == 'CONFIRMED') {
      final docRef = _col.doc(reservationId);

      // Lecture hors transaction pour les side-effects post-commit
      final preSnap = await docRef.get();
      if (!preSnap.exists) return;
      final reservation = ReservationModel.fromJson(
          preSnap.data()! as Map<String, dynamic>, reservationId);

      // Transaction atomique : stock + statut
      await _db.runTransaction((tx) async {
        final resSnap = await tx.get(docRef);
        if (!resSnap.exists) return;
        final res = ReservationModel.fromJson(
            resSnap.data()! as Map<String, dynamic>, reservationId);

        for (final p in res.selectedProducts) {
          final productRef = _db
              .collection('laundries')
              .doc(res.laundryId)
              .collection('products')
              .doc(p.productId);
          final productSnap = await tx.get(productRef);
          if (!productSnap.exists) continue;
          final stock =
              (productSnap.data()!['stockQuantity'] as num?)?.toInt() ?? 0;
          if (stock <= 0) throw Exception('product_out_of_stock:${p.name}');
          tx.update(productRef, {'stockQuantity': stock - 1});
        }

        tx.update(docRef, {'status': 'CONFIRMED'});
      });

      // Side-effects post-transaction (conversation, notification, auto-cancel)
      try {
        final existing = await _messagingRepo
            .getConversationByReservationId(reservationId);
        if (existing == null) {
          await _messagingRepo.createConversation(
            reservationId: reservationId,
            machineId: reservation.machineId,
            locataireId: reservation.renterId,
            proprietaireId: reservation.ownerId,
            laundryId: reservation.laundryId,
          );
        }
      } catch (_) {}

      try {
        await NotificationRepository().sendNotification(
          userId: reservation.renterId,
          title: 'Réservation confirmée ✅',
          message:
              'Le propriétaire de ${reservation.machineBrand} a accepté votre demande pour le ${DateFormat("d MMM à HH:mm", "fr").format(reservation.startTime)}.',
        );
      } catch (_) {}

      try {
        final pendingSnap = await _col
            .where('machineId', isEqualTo: reservation.machineId)
            .where('status', isEqualTo: 'PENDING')
            .where('endTime',
                isGreaterThan: Timestamp.fromDate(reservation.startTime))
            .get();
        final batch = _db.batch();
        bool hasOverlaps = false;
        for (final pDoc in pendingSnap.docs) {
          if (pDoc.id == reservationId) continue;
          final pRes = ReservationModel.fromJson(
              pDoc.data() as Map<String, dynamic>, pDoc.id);
          final overlaps = reservation.startTime.isBefore(pRes.endTime) &&
              reservation.endTime.isAfter(pRes.startTime);
          if (overlaps) {
            batch.update(pDoc.reference, {'status': 'CANCELLED'});
            hasOverlaps = true;
          }
        }
        if (hasOverlaps) await batch.commit();
      } catch (_) {}
    } else if (newStatus == 'CANCELLED') {
      final snap = await _col.doc(reservationId).get();
      final wasConfirmed = snap.exists &&
          (snap.data() as Map<String, dynamic>)['status'] == 'CONFIRMED';
      ReservationModel? reservation;
      if (wasConfirmed && snap.exists) {
        reservation = ReservationModel.fromJson(
            snap.data()! as Map<String, dynamic>, reservationId);
      }

      await updateStatus(reservationId, 'CANCELLED');

      if (wasConfirmed && reservation != null) {
        for (final p in reservation.selectedProducts) {
          try {
            await _productRepo.incrementStock(
              laundryId: reservation.laundryId,
              productId: p.productId,
            );
          } catch (_) {}
        }
      }
    } else {
      await updateStatus(reservationId, newStatus);
    }
  }

  /// Vérifie si un créneau est disponible sur une machine donnée.
  /// laundryId est requis pour identifier le chemin sous-collection.
  Future<bool> checkAvailability({
    required String laundryId,
    required String machineId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final snapshot = await _col
          .where('machineId', isEqualTo: machineId)
          .where('endTime', isGreaterThan: Timestamp.fromDate(start))
          .get();

      for (final doc in snapshot.docs) {
        final r = ReservationModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        if (r.status != 'PENDING' && r.status != 'CONFIRMED') continue;
        if (end.isAfter(r.startTime)) return false;
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  /// Récupère les créneaux déjà pris pour une machine à une date donnée.
  /// laundryId est requis pour identifier le chemin sous-collection.
  Future<List<DateTime>> getBookedSlots({
    required String laundryId,
    required String machineId,
    required DateTime date,
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    try {
      final snapshot = await _col
          .where('machineId', isEqualTo: machineId)
          .where('endTime', isGreaterThan: Timestamp.fromDate(dayStart))
          .get();

      final bookedStarts = <DateTime>[];
      for (final doc in snapshot.docs) {
        final r = ReservationModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        if (r.status != 'PENDING' && r.status != 'CONFIRMED') continue;
        if (r.startTime.isAfter(dayEnd)) continue;

        var current = r.startTime;
        while (current.isBefore(r.endTime)) {
          if (!current.isBefore(dayStart) && current.isBefore(dayEnd)) {
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
