import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/subscription_plan_model.dart';

final subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>((ref) => SubscriptionRepository());

class SubscriptionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _plans => _db.collection('subscriptions');
  CollectionReference get _userSubs =>
      _db.collection('user_subscriptions');

  // ── Lecture des plans ─────────────────────────────────────────────

  Future<List<SubscriptionPlanModel>> getActivePlans() async {
    final snap = await _plans
        .where('isActive', isEqualTo: true)
        .orderBy('price')
        .get();
    return snap.docs
        .map((d) =>
            SubscriptionPlanModel.fromJson(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  Future<List<SubscriptionPlanModel>> getPlansByRole(String role) async {
    final snap = await _plans
        .where('targetRole', isEqualTo: role)
        .where('isActive', isEqualTo: true)
        .orderBy('price')
        .get();
    return snap.docs
        .map((d) =>
            SubscriptionPlanModel.fromJson(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  Future<SubscriptionPlanModel?> getPlanById(String planId) async {
    final doc = await _plans.doc(planId).get();
    if (!doc.exists) return null;
    return SubscriptionPlanModel.fromJson(
        doc.data() as Map<String, dynamic>, doc.id);
  }

  Stream<SubscriptionPlanModel?> streamActivePlan(String userId) {
    return _db.collection('users').doc(userId).snapshots().asyncExpand((snap) {
      if (!snap.exists) return Stream.value(null);
      final planId =
          snap.data()?['currentSubscriptionId'] as String?;
      if (planId == null || planId.isEmpty) return Stream.value(null);
      return _plans.doc(planId).snapshots().map((planSnap) {
        if (!planSnap.exists) return null;
        return SubscriptionPlanModel.fromJson(
            planSnap.data() as Map<String, dynamic>, planSnap.id);
      });
    });
  }

  // ── Seed des plans par défaut ──────────────────────────────────────

  Future<void> seedPlansIfEmpty() async {
    try {
      final snap = await _plans.limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final batch = _db.batch();
      for (final plan in _defaultPlans) {
        batch.set(_plans.doc(plan.id), plan.toJson());
      }
      await batch.commit();
    } catch (_) {}
  }

  static final List<SubscriptionPlanModel> _defaultPlans = [
    // ── Locataire (USER) ─────────────────────────────────────────────
    const SubscriptionPlanModel(
      id: 'user_essentiel',
      name: 'Essentiel',
      price: 3.99,
      targetRole: 'USER',
      reservationQuota: 4,
      features: [
        '4 réservations par mois',
        'Accès à toutes les laveries',
        'Support par email',
      ],
    ),
    const SubscriptionPlanModel(
      id: 'user_confort',
      name: 'Confort',
      price: 6.99,
      targetRole: 'USER',
      reservationQuota: 10,
      features: [
        '10 réservations par mois',
        'Accès à toutes les laveries',
        'Rappels de créneau',
        'Support prioritaire',
      ],
    ),
    const SubscriptionPlanModel(
      id: 'user_premium',
      name: 'Premium',
      price: 11.99,
      targetRole: 'USER',
      reservationQuota: -1,
      features: [
        'Réservations illimitées',
        'Accès à toutes les laveries',
        'Rappels de créneau',
        'Support prioritaire 24/7',
        'Annulation flexible',
      ],
    ),

    // ── Propriétaire (OWNER) ─────────────────────────────────────────
    const SubscriptionPlanModel(
      id: 'owner_starter',
      name: 'Starter',
      price: 4.99,
      targetRole: 'OWNER',
      reservationQuota: 0,
      maxMachines: 1,
      commissionRate: 0.15,
      analyticsLevel: 'NONE',
      features: [
        '1 machine publiée',
        'Commission 15% par réservation',
        'Tableau de bord basique',
      ],
    ),
    const SubscriptionPlanModel(
      id: 'owner_pro',
      name: 'Pro',
      price: 9.99,
      targetRole: 'OWNER',
      reservationQuota: 0,
      maxMachines: 5,
      commissionRate: 0.10,
      hasVerifiedBadge: true,
      analyticsLevel: 'BASIC',
      features: [
        'Jusqu\'à 5 machines publiées',
        'Commission 10% par réservation',
        'Badge "Laverie vérifiée"',
        'Analytics basiques',
        'Support prioritaire',
      ],
    ),
    const SubscriptionPlanModel(
      id: 'owner_business',
      name: 'Business',
      price: 19.99,
      targetRole: 'OWNER',
      reservationQuota: 0,
      maxMachines: -1,
      commissionRate: 0.05,
      hasVerifiedBadge: true,
      analyticsLevel: 'FULL',
      features: [
        'Machines illimitées',
        'Commission 5% par réservation',
        'Badge "Laverie vérifiée"',
        'Analytics complets',
        'Support dédié 24/7',
        'Mise en avant dans la recherche',
      ],
    ),
  ];

  // ── Activation d'un plan (simulation) ────────────────────────────

  Future<void> activatePlan({
    required String userId,
    required SubscriptionPlanModel plan,
  }) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: plan.durationDays));

    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(userId);
      final subRef = _userSubs.doc();

      tx.set(subRef, {
        'userId': userId,
        'planId': plan.id,
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(endDate),
        'status': 'ACTIVE',
        'paymentId': 'SIMULATED',
      });

      tx.update(userRef, {
        'currentSubscriptionId': plan.id,
        'subscriptionEndDate': Timestamp.fromDate(endDate),
        'remainingReservations': plan.reservationQuota,
        'hasVerifiedBadge': plan.hasVerifiedBadge,
      });
    });
  }

  // ── Vérification expiration ───────────────────────────────────────

  Future<void> checkAndResetIfExpired(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return;
      final data = doc.data()!;
      final endRaw = data['subscriptionEndDate'];
      if (endRaw == null) return;
      final endDate = (endRaw as Timestamp).toDate();
      if (!endDate.isBefore(DateTime.now())) return;

      await _db.collection('users').doc(userId).update({
        'currentSubscriptionId': FieldValue.delete(),
        'subscriptionEndDate': FieldValue.delete(),
        'remainingReservations': 0,
        'hasVerifiedBadge': false,
      });

      // Marquer l'abonnement comme expiré
      final subSnap = await _userSubs
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'ACTIVE')
          .limit(1)
          .get();
      if (subSnap.docs.isNotEmpty) {
        await subSnap.docs.first.reference.update({'status': 'EXPIRED'});
      }
    } catch (_) {}
  }

  // ── Décrémentation du quota ───────────────────────────────────────

  Future<void> decrementQuota(String userId) async {
    final userRef = _db.collection('users').doc(userId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final roles = data['roles'] != null
          ? List<String>.from(data['roles'] as List)
          : [(data['role'] as String? ?? 'USER')];
      if (roles.contains('OWNER') || roles.contains('ADMIN')) return;

      final remaining =
          (data['remainingReservations'] as num?)?.toInt() ?? 0;
      if (remaining == -1) return; // illimité
      if (remaining <= 0) throw Exception('quota_exceeded');
      tx.update(userRef, {'remainingReservations': remaining - 1});
    });
  }

  // ── Backward compat ───────────────────────────────────────────────

  Future<void> subscribeUserToPlan(
      String userId, SubscriptionPlanModel plan) async {
    await activatePlan(userId: userId, plan: plan);
  }
}
