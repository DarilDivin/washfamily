import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/models/laundry_product_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class OwnerProductTile extends StatelessWidget {
  final LaundryProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleAvailable;

  const OwnerProductTile({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailable,
  });

  PhosphorIconData get _categoryIcon {
    return product.category == 'ACCESSORY'
        ? PhosphorIconsRegular.package
        : PhosphorIconsRegular.drop;
  }

  Widget _stockBadge(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final Color bg;
    final Color fg;
    final String label;

    if (product.stockQuantity == 0) {
      bg = AppColors.cancelledBg;
      fg = AppColors.cancelledText;
      label = 'Rupture de stock';
    } else if (product.stockQuantity <= 5) {
      bg = AppColors.pendingBg;
      fg = AppColors.pendingText;
      label = 'Plus que ${product.stockQuantity}';
    } else {
      bg = AppColors.confirmedBg;
      fg = AppColors.confirmedText;
      label = '${product.stockQuantity} en stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(label,
          style: tt.labelSmall
              ?.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Center(
              child: PhosphorIcon(_categoryIcon,
                  size: 22, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: tt.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${product.pricePerUnit.toStringAsFixed(2)} € / ${product.unit}',
                  style:
                      tt.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                _stockBadge(context),
              ],
            ),
          ),
          Switch(
            value: product.isAvailable,
            onChanged: onToggleAvailable,
            activeThumbColor: AppColors.surface,
            activeTrackColor: AppColors.success,
            inactiveThumbColor: AppColors.surface,
            inactiveTrackColor: AppColors.border,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.pencilSimple,
                size: 18, color: AppColors.textSecondary),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.trash,
                size: 18, color: AppColors.error),
            onPressed: () => _confirmDelete(context),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Supprimer ce produit ?', style: tt.titleMedium),
        content: Text(
          'La suppression de "${product.name}" est définitive.',
          style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                Text('Annuler', style: tt.labelLarge?.copyWith(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
            child: Text('Supprimer',
                style: tt.labelLarge?.copyWith(color: AppColors.surface)),
          ),
        ],
      ),
    );
  }
}
