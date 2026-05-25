import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/models/machine_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class OwnerMachineCard extends StatelessWidget {
  final MachineModel machine;
  final String laundryId;
  final VoidCallback onEdit;
  final VoidCallback onToggleAvailability;

  const OwnerMachineCard({
    super.key,
    required this.machine,
    required this.laundryId,
    required this.onEdit,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // ── Photo / Placeholder ────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 60,
              height: 60,
              child: machine.photoUrls.isNotEmpty
                  ? Image.network(machine.photoUrls.first, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.inputBackground,
                      child: const Center(
                        child: PhosphorIcon(
                          PhosphorIconsRegular.washingMachine,
                          size: 28,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
            ),
          ),

          AppSpacing.hGapMd,

          // ── Infos ──────────────────────────────────────────────────
          Expanded(
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
                  '${machine.brand} · ${machine.capacityKg} kg',
                  style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
                if (machine.programs.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${machine.programs.length} programme${machine.programs.length > 1 ? 's' : ''}',
                    style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),

          // ── Actions ────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Switch(
                value: machine.isAvailable,
                onChanged: (_) => onToggleAvailability(),
                activeThumbColor: AppColors.surface,
                activeTrackColor: AppColors.success,
                inactiveThumbColor: AppColors.surface,
                inactiveTrackColor: AppColors.border,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.primary,
                ),
                child: Text('Modifier', style: tt.labelSmall?.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
