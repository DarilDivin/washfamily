import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/models/machine_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Carte compacte d'une machine dans le contexte d'une laverie.
/// Utilisée dans LaundryDetailScreen pour lister les machines disponibles.
class LaundryMachineCard extends StatelessWidget {
  final MachineModel machine;
  final String laundryId;
  final VoidCallback onTap;

  const LaundryMachineCard({
    super.key,
    required this.machine,
    required this.laundryId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // ── Photo / Placeholder ──────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSpacing.radiusLg)),
              child: SizedBox(
                width: 80,
                height: 80,
                child: machine.photoUrls.isNotEmpty
                    ? Image.network(machine.photoUrls.first, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.inputBackground,
                        child: const Center(
                          child: PhosphorIcon(
                            PhosphorIconsRegular.washingMachine,
                            size: 32,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
              ),
            ),

            // ── Infos ────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machine.nickname.isNotEmpty ? machine.nickname : machine.brand,
                      style: tt.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      machine.model != null
                          ? '${machine.brand} · ${machine.model}'
                          : machine.brand,
                      style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          '${machine.capacityKg} kg',
                          style:
                              tt.labelSmall?.copyWith(color: AppColors.textSecondary),
                        ),
                        if (machine.programs.isNotEmpty) ...[
                          Text(
                            '  ·  ${machine.programs.length} programme${machine.programs.length > 1 ? 's' : ''}',
                            style: tt.labelSmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Badge disponibilité ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _AvailabilityBadge(isAvailable: machine.isAvailable),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + AppSpacing.xs, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.confirmedBg : AppColors.cancelledBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        isAvailable ? 'Dispo' : 'Indispo',
        style: tt.labelSmall?.copyWith(
          color: isAvailable ? AppColors.confirmedText : AppColors.cancelledText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
