import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/repositories/review_repository.dart';
import '../../domain/models/review_model.dart';
import '../../../booking/domain/models/reservation_model.dart';
import '../widgets/star_rating_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class LeaveReviewScreen extends ConsumerStatefulWidget {
  final ReservationModel reservation;
  const LeaveReviewScreen({super.key, required this.reservation});

  @override
  ConsumerState<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends ConsumerState<LeaveReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une note avant de publier.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSubmitting = true);

    final review = ReviewModel(
      id: widget.reservation.id,
      machineId: widget.reservation.machineId,
      ownerId: widget.reservation.ownerId,
      renterId: uid,
      reservationId: widget.reservation.id,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );

    try {
      await ref.read(reviewRepositoryProvider).submitReview(review);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci pour votre avis !'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final msg = e.toString().contains('already_reviewed')
            ? 'Vous avez déjà laissé un avis pour cette réservation.'
            : 'Une erreur est survenue. Veuillez réessayer.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final r = widget.reservation;

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Votre avis'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      // ── Bouton publier en bas — hors du scroll, insensible au clavier ──
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              disabledBackgroundColor: AppColors.border,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text('Publier',
                    style: tt.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.surface,
                        fontSize: 15)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête machine ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.completedBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Center(
                    child: PhosphorIcon(PhosphorIconsRegular.washingMachine,
                        color: AppColors.primary, size: 22),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.machineBrand,
                          style: tt.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (r.machineAddress != null &&
                          r.machineAddress!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(r.machineAddress!,
                            style: tt.bodySmall
                                ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ]),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Note ─────────────────────────────────────────────────
            Text('NOTE',
                style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.md),
            StarRatingWidget(
              rating: _rating,
              size: 44,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _rating == 0
                  ? 'Appuyez sur une étoile pour noter'
                  : _ratingLabel(_rating),
              style: tt.bodySmall?.copyWith(
                color: _rating == 0 ? AppColors.textSecondary : AppColors.primary,
                fontWeight: _rating > 0 ? FontWeight.w600 : FontWeight.w400,
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Commentaire ──────────────────────────────────────────
            Text('COMMENTAIRE (OPTIONNEL)',
                style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 400,
              style: tt.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Partagez votre expérience…',
                hintStyle:
                    tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.inputBackground,
                counterStyle:
                    tt.bodySmall?.copyWith(color: AppColors.textSecondary),
                contentPadding: const EdgeInsets.all(AppSpacing.lg),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Disclaimer ───────────────────────────────────────────
            Row(children: [
              const PhosphorIcon(PhosphorIconsRegular.info,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Votre avis est public et visible par tous les utilisateurs.',
                  style: tt.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Très mauvais';
      case 2:
        return 'Mauvais';
      case 3:
        return 'Correct';
      case 4:
        return 'Bien';
      case 5:
        return 'Excellent !';
      default:
        return '';
    }
  }
}
