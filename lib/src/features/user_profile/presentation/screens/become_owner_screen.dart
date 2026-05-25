import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../authentication/data/providers/user_provider.dart';
import '../../../authentication/data/repositories/user_repository.dart';
import '../../../authentication/domain/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class BecomeOwnerScreen extends ConsumerStatefulWidget {
  const BecomeOwnerScreen({super.key});

  @override
  ConsumerState<BecomeOwnerScreen> createState() => _BecomeOwnerScreenState();
}

class _BecomeOwnerScreenState extends ConsumerState<BecomeOwnerScreen> {
  bool _accepted = false;
  bool _isLoading = false;

  static const _commitments = [
    'Maintenir votre machine en bon état de fonctionnement',
    'Respecter les créneaux de réservation confirmés',
    'Gérer le linge des locataires avec soin',
    'Communiquer rapidement via la messagerie',
  ];

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      await UserRepository().addRole(uid, 'OWNER');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bienvenue ! Créez maintenant votre laverie.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          ),
        );
        context.go('/laundry/create');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    // Redirect si déjà OWNER
    ref.listen<AsyncValue<UserModel?>>(currentUserProvider, (_, next) {
      if (next.value?.isOwner == true && mounted) {
        context.go('/owner-dashboard');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Devenir propriétaire', style: tt.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          // ── Header ──────────────────────────────────────────────────
          AppSpacing.gapXl,
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.completedBg,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: PhosphorIcon(PhosphorIconsRegular.storefront,
                    size: 48, color: AppColors.primary),
              ),
            ),
          ),
          AppSpacing.gapLg,
          Text('Devenez propriétaire',
              style: tt.headlineLarge, textAlign: TextAlign.center),
          AppSpacing.gapSm,
          Text(
            'Proposez votre machine à laver et générez des revenus supplémentaires.',
            style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapXl,

          // ── Engagements ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vos engagements', style: tt.titleMedium),
                AppSpacing.gapLg,
                ..._commitments.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const PhosphorIcon(
                            PhosphorIconsRegular.checkCircle,
                            size: 20,
                            color: AppColors.success,
                          ),
                          AppSpacing.hGapMd,
                          Expanded(
                            child: Text(c, style: tt.bodyMedium),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          AppSpacing.gapLg,

          // ── CGU ──────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conditions propriétaire', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                AppSpacing.gapSm,
                SizedBox(
                  height: 120,
                  child: SingleChildScrollView(
                    child: Text(
                      'En devenant propriétaire sur WashFamily, vous acceptez de proposer '
                      'un service de blanchisserie sérieux et responsable. WashFamily se réserve '
                      'le droit de suspendre tout compte ne respectant pas ces engagements. '
                      'Les litiges entre locataires et propriétaires doivent être signalés '
                      'via l\'application.',
                      style: tt.bodyMedium?.copyWith(
                          color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Checkbox CGU
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _accepted,
            onChanged: (v) => setState(() => _accepted = v ?? false),
            activeColor: AppColors.primary,
            title: Text(
              "J'ai lu et j'accepte les conditions propriétaire",
              style: tt.bodyMedium,
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),

          AppSpacing.gapXl,
          const SizedBox(height: 80),
        ],
      ),

      // ── CTA ──────────────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: FilledButton(
            onPressed: (_accepted && !_isLoading) ? _submit : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.border,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.surface, strokeWidth: 2),
                  )
                : const Text('Devenir propriétaire'),
          ),
        ),
      ),
    );
  }
}
