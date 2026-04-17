import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../data/subscription_repository.dart';
import '../../domain/models/subscription_plan_model.dart';
import '../../../authentication/domain/models/user_model.dart';
import '../../../authentication/data/providers/user_provider.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final activePlansProvider = FutureProvider<List<SubscriptionPlanModel>>((ref) {
  return ref.read(subscriptionRepositoryProvider).getActivePlans();
});

// ── Screen ───────────────────────────────────────────────────────────────────

class SubscriptionPlansScreen extends ConsumerWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(activePlansProvider);
    final userAsync  = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Abonnements',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (plans) => _Body(plans: plans, userAsync: userAsync),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final List<SubscriptionPlanModel> plans;
  final AsyncValue<UserModel?> userAsync;

  const _Body({required this.plans, required this.userAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = userAsync.valueOrNull;
    final activePlanId = user?.currentSubscriptionId;
    final activePlan = activePlanId != null
        ? plans.where((p) => p.id == activePlanId).firstOrNull
        : null;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      children: [
        // ── Statut actuel ───────────────────────────────────────
        if (userAsync.isLoading)
          const _SkeletonCard()
        else if (activePlan != null && user != null)
          _CurrentPlanCard(plan: activePlan, user: user)
        else
          _FreeTierCard(remaining: user?.remainingReservations ?? 2),

        const SizedBox(height: 32),

        // ── Titre section plans ─────────────────────────────────
        const Text('Choisissez une formule',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        const Text('Sans engagement · Renouvelable chaque mois',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
        const SizedBox(height: 20),

        // ── Cartes de plans ─────────────────────────────────────
        ...plans.map((plan) => _PlanCard(
              plan: plan,
              isActive: plan.id == activePlanId,
            )),

        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text('Plus tard',
                style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Carte statut actuel ───────────────────────────────────────────────────────

class _CurrentPlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final UserModel user;

  const _CurrentPlanCard({required this.plan, required this.user});

  @override
  Widget build(BuildContext context) {
    final remaining = user.remainingReservations;
    final total     = plan.maxReservationsPerMonth;
    final progress  = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;
    final expiry    = user.subscriptionEndDate;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              const Text('Votre formule',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B))),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Actif',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nom du plan
          Text(plan.name.toUpperCase(),
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Color(0xFF0F172A))),

          if (expiry != null) ...[
            const SizedBox(height: 4),
            Text(
              'Expire le ${DateFormat("d MMMM yyyy", "fr").format(expiry)}',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Réservations restantes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Réservations restantes',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151))),
              Text('$remaining / $total',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.3
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte tier gratuit ────────────────────────────────────────────────────────

class _FreeTierCard extends StatelessWidget {
  final int remaining;
  const _FreeTierCard({required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aucun abonnement actif',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text('$remaining réservation${remaining > 1 ? 's' : ''} gratuite${remaining > 1 ? 's' : ''} disponible${remaining > 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte plan ────────────────────────────────────────────────────────────────

class _PlanCard extends ConsumerWidget {
  final SubscriptionPlanModel plan;
  final bool isActive;

  const _PlanCard({required this.plan, required this.isActive});

  Future<void> _subscribe(BuildContext context, WidgetRef ref) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref.read(subscriptionRepositoryProvider).subscribeUserToPlan(uid, plan);
      if (context.mounted) {
        Navigator.pop(context);
        ref.invalidate(activePlansProvider);
        ref.invalidate(currentUserProvider);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Abonnement ${plan.name} activé.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFF0F172A)
              : const Color(0xFFE2E8F0),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : nom + prix
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(plan.name.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFF64748B))),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    plan.price == 0
                        ? 'Gratuit'
                        : '${plan.price.toStringAsFixed(0)} €',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A)),
                  ),
                  if (plan.price > 0)
                    const Text(' / mois',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            '${plan.maxReservationsPerMonth} réservation${plan.maxReservationsPerMonth > 1 ? 's' : ''} par mois',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151)),
          ),

          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check,
                          size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(f,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B))),
                      ),
                    ],
                  ),
                )),
          ],

          const SizedBox(height: 20),

          // CTA
          if (isActive)
            Row(
              children: const [
                Icon(Icons.check_circle_rounded,
                    size: 16, color: Color(0xFF0F172A)),
                SizedBox(width: 6),
                Text('Plan actuel',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A))),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _subscribe(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFF0F172A)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Souscrire',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Skeleton loader ───────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
