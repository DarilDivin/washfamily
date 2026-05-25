import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/subscription_repository.dart';
import '../../domain/models/subscription_plan_model.dart';
import '../../../authentication/data/providers/user_provider.dart';
import '../../../authentication/domain/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

// ── Providers ────────────────────────────────────────────────────────────────

/// Tous les plans actifs — utilisé par AdminSubscriptionsScreen.
final activePlansProvider = FutureProvider<List<SubscriptionPlanModel>>((ref) {
  return ref.read(subscriptionRepositoryProvider).getActivePlans();
});

final _plansByRoleProvider =
    FutureProvider.family<List<SubscriptionPlanModel>, String>(
  (ref, role) =>
      ref.read(subscriptionRepositoryProvider).getPlansByRole(role),
);

// ── Screen ───────────────────────────────────────────────────────────────────

class SubscriptionPlansScreen extends ConsumerWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final role = user?.isOwner == true ? 'OWNER' : 'USER';
    final plansAsync = ref.watch(_plansByRoleProvider(role));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Choisissez votre plan', style: tt.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: plansAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Erreur : $e',
              style: tt.bodyMedium?.copyWith(color: AppColors.error)),
        ),
        data: (plans) => _Body(plans: plans, user: user, role: role),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final List<SubscriptionPlanModel> plans;
  final UserModel? user;
  final String role;

  const _Body({required this.plans, required this.user, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final maxPrice = plans.isEmpty
        ? 0.0
        : plans.map((p) => p.price).reduce((a, b) => a > b ? a : b);

    final subtitle = role == 'OWNER'
        ? 'Développez votre activité de laverie'
        : 'Accédez à plus de réservations chaque mois';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text('Choisissez votre plan', style: tt.headlineLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle,
            style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.xl),

        ...plans.map((plan) => _PlanCard(
              plan: plan,
              user: user,
              isPopular: plan.price == maxPrice,
            )),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ── Plan card ────────────────────────────────────────────────────────────────

class _PlanCard extends ConsumerStatefulWidget {
  final SubscriptionPlanModel plan;
  final UserModel? user;
  final bool isPopular;

  const _PlanCard({
    required this.plan,
    required this.user,
    required this.isPopular,
  });

  @override
  ConsumerState<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends ConsumerState<_PlanCard> {
  bool _activating = false;

  bool get _isActive =>
      widget.user?.currentSubscriptionId == widget.plan.id &&
      (widget.user?.hasActiveSubscription ?? false);

  Future<void> _confirmActivation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(plan: widget.plan),
    );
    if (confirmed != true || !mounted) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _activating = true);
    try {
      await ref
          .read(subscriptionRepositoryProvider)
          .activatePlan(userId: uid, plan: widget.plan);
      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Plan ${widget.plan.name} activé avec succès !'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final plan = widget.plan;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(
              bottom: AppSpacing.md, top: AppSpacing.sm),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: widget.isPopular ? AppColors.primary : AppColors.border,
              width: widget.isPopular ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom
              Text(plan.name, style: tt.titleLarge),
              const SizedBox(height: AppSpacing.xs),

              // Prix
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${plan.price.toStringAsFixed(2)} €',
                    style:
                        tt.headlineLarge?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(width: 4),
                  Text(' / mois',
                      style: tt.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),

              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.md),

              // Features
              ...plan.features.map((f) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PhosphorIcon(
                            PhosphorIconsRegular.checkCircle,
                            size: 16,
                            color: AppColors.success),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(f,
                              style: tt.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: AppSpacing.lg),

              // CTA
              if (_isActive) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.confirmedBg,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Column(
                    children: [
                      Text('Plan actuel',
                          style: tt.labelLarge?.copyWith(
                              color: AppColors.confirmedText,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center),
                      if (widget.user?.subscriptionEndDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Expire le ${DateFormat("d MMMM yyyy", "fr").format(widget.user!.subscriptionEndDate!)}',
                          style: tt.labelSmall?.copyWith(
                              color: AppColors.confirmedText),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _activating ? null : _confirmActivation,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd)),
                    ),
                    child: _activating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: AppColors.surface, strokeWidth: 2))
                        : const Text('Activer ce plan'),
                  ),
                ),
            ],
          ),
        ),

        // Badge "Populaire"
        if (widget.isPopular)
          Positioned(
            top: 0,
            right: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text('Populaire',
                  style: tt.labelSmall?.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

// ── Dialog de confirmation ───────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final SubscriptionPlanModel plan;
  const _ConfirmDialog({required this.plan});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      title: Text("Confirmer l'abonnement", style: tt.titleMedium),
      content: Text(
        'Vous êtes sur le point d\'activer le plan ${plan.name} '
        'pour ${plan.price.toStringAsFixed(2)} €/mois.\n\n'
        '(Simulation — aucun paiement réel)',
        style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Annuler',
              style: tt.labelLarge
                  ?.copyWith(color: AppColors.textSecondary)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd)),
          ),
          child: Text('Confirmer',
              style: tt.labelLarge?.copyWith(color: AppColors.surface)),
        ),
      ],
    );
  }
}
