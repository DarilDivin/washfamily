import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../machines_map/domain/models/machine_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class MachineCard extends StatelessWidget {
  final MachineModel machine;
  final double? distanceKm;

  const MachineCard({super.key, required this.machine, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isAvailable = machine.status == 'AVAILABLE';
    final isInUse     = machine.status == 'IN_USE';

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/machine/${machine.id}', extra: machine),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image / Placeholder ─────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusXl)),
                child: Stack(
                  children: [
                    if (machine.photoUrls.isNotEmpty)
                      Image.network(
                        machine.photoUrls.first,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        height: 160,
                        width: double.infinity,
                        color: AppColors.inputBackground,
                        child: Center(
                          child: PhosphorIcon(
                            PhosphorIconsRegular.washingMachine,
                            size: 56,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),

                    // Badge statut
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      child: _StatusBadge(
                          isAvailable: isAvailable, isInUse: isInUse),
                    ),

                    // Distance
                    if (distanceKm != null)
                      Positioned(
                        top: AppSpacing.md,
                        right: AppSpacing.md,
                        child: _DistanceBadge(distanceKm: distanceKm!),
                      ),
                  ],
                ),
              ),

              // ── Corps ───────────────────────────────────────────────
              Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Marque + Prix
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(machine.brand, style: tt.titleMedium,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.completedBg,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            '${machine.pricePerWash.toStringAsFixed(2)} €',
                            style: tt.labelLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Chips caractéristiques
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _InfoChip(
                            icon: PhosphorIconsRegular.drop,
                            label: '${machine.capacityKg} kg'),
                        if (machine.description.contains('[Sèche-linge]'))
                          _InfoChip(
                              icon: PhosphorIconsRegular.wind,
                              label: 'Sèche-linge')
                        else if (machine.description.contains('[Combiné]'))
                          _InfoChip(
                              icon: PhosphorIconsRegular.arrowsCounterClockwise,
                              label: 'Combiné')
                        else
                          _InfoChip(
                              icon: PhosphorIconsRegular.washingMachine,
                              label: 'Lave-linge'),
                        if (machine.description.contains('Lessive fournie'))
                          _InfoChip(
                              icon: PhosphorIconsRegular.sparkle,
                              label: 'Lessive fournie',
                              highlight: true),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Adresse + Note
                    Row(
                      children: [
                        PhosphorIcon(PhosphorIconsRegular.mapPin,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            machine.address ?? 'Adresse non précisée',
                            style: tt.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (machine.reviewCount > 0) ...[
                          const SizedBox(width: AppSpacing.sm),
                          PhosphorIcon(PhosphorIconsFill.star,
                              size: 14, color: AppColors.starActive),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${machine.rating.toStringAsFixed(1)} (${machine.reviewCount})',
                            style: tt.labelSmall
                                ?.copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Composants internes ───────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isAvailable;
  final bool isInUse;
  const _StatusBadge({required this.isAvailable, required this.isInUse});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final dotColor = isAvailable
        ? AppColors.success
        : isInUse
            ? AppColors.warning
            : AppColors.textSecondary;
    final bgColor = isAvailable
        ? AppColors.confirmedBg
        : isInUse
            ? AppColors.pendingBg
            : AppColors.inputBackground;
    final textColor = isAvailable
        ? AppColors.confirmedText
        : isInUse
            ? AppColors.pendingText
            : AppColors.textSecondary;
    final label =
        isAvailable ? 'Disponible' : isInUse ? 'En cours' : 'Indisponible';

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: AppSpacing.xs / 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(label,
              style: tt.labelSmall?.copyWith(
                  color: textColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  final double distanceKm;
  const _DistanceBadge({required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final label = distanceKm < 1
        ? '${(distanceKm * 1000).toStringAsFixed(0)} m'
        : '${distanceKm.toStringAsFixed(1)} km';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(PhosphorIconsRegular.navigationArrow,
              size: 10, color: AppColors.surface),
          const SizedBox(width: AppSpacing.xs),
          Text(label,
              style: tt.labelSmall?.copyWith(
                  color: AppColors.surface, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final bool highlight;

  const _InfoChip(
      {required this.icon, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: highlight ? AppColors.completedBg : AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon,
              size: 12,
              color: highlight ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(label,
              style: tt.labelSmall?.copyWith(
                  color: highlight ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
