import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/models/reservation_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Étape 3 du tunnel : Confirmation avec animation de succès.
class BookingSuccessScreen extends StatefulWidget {
  final ReservationModel reservation;

  const BookingSuccessScreen({super.key, required this.reservation});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(
        parent: _controller, curve: const Interval(0.4, 1.0));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final r = widget.reservation;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),

              // ── Animation checkmark ────────────────────────────────
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                  child: const PhosphorIcon(
                    PhosphorIconsRegular.check,
                    size: 56,
                    color: AppColors.surface,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              FadeTransition(
                opacity: _fadeAnim,
                child: Column(children: [
                  Text('Demande envoyée !', style: tt.headlineLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Le propriétaire a reçu votre demande. Vous serez notifié dès confirmation.',
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ]),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Récapitulatif ──────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _SuccessRow(
                          icon: PhosphorIconsRegular.washingMachine,
                          label: 'Machine',
                          value: r.machineBrand),
                      Divider(height: AppSpacing.xl, color: AppColors.border),
                      _SuccessRow(
                        icon: PhosphorIconsRegular.calendarBlank,
                        label: 'Date',
                        value: DateFormat('EEE d MMM yyyy', 'fr')
                            .format(r.startTime),
                      ),
                      Divider(height: AppSpacing.xl, color: AppColors.border),
                      _SuccessRow(
                        icon: PhosphorIconsRegular.clock,
                        label: 'Créneau',
                        value:
                            '${DateFormat('HH:mm').format(r.startTime)} → ${DateFormat('HH:mm').format(r.endTime)}',
                      ),
                      Divider(height: AppSpacing.xl, color: AppColors.border),
                      _SuccessRow(
                        icon: PhosphorIconsRegular.hourglass,
                        label: 'Statut',
                        value: 'En attente',
                        valueColor: AppColors.pendingText,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // ── Actions ────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(children: [
                  FilledButton(
                    onPressed: () => context.go('/bookings'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd)),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: const Text('Voir mes réservations'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary),
                    child: const Text('Retour à l\'accueil'),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SuccessRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(children: [
      PhosphorIcon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: AppSpacing.sm),
      Text(label, style: tt.bodySmall),
      const Spacer(),
      Text(value,
          style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary)),
    ]);
  }
}
