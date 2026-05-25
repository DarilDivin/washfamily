import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../laundries/domain/models/laundry_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Feuille persistante superposée à la carte.
/// 3 états : réduit (0.12) · mi-hauteur (0.40) · plein écran (0.92)
class NearbyMachinesSheet extends StatefulWidget {
  final List<LaundryModel> laundries;
  final double? userLat;
  final double? userLng;

  const NearbyMachinesSheet({
    super.key,
    required this.laundries,
    this.userLat,
    this.userLng,
  });

  @override
  State<NearbyMachinesSheet> createState() => _NearbyMachinesSheetState();
}

class _NearbyMachinesSheetState extends State<NearbyMachinesSheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _isExpanded = false;

  // Filtres actifs
  bool _filterFolding = false;
  bool _filterPickup = false;
  bool _filterDelivery = false;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(() {
      final expanded =
          _sheetController.isAttached && _sheetController.size > 0.6;
      if (expanded != _isExpanded) setState(() => _isExpanded = expanded);
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  double? _distanceTo(LaundryModel l) {
    if (widget.userLat == null || widget.userLng == null) return null;
    const r = 6371.0;
    final dLat = _toRad(l.latitude - widget.userLat!);
    final dLng = _toRad(l.longitude - widget.userLng!);
    return r * (dLat * dLat + dLng * dLng).sqrt();
  }

  double _toRad(double deg) => deg * 3.14159265358979 / 180;

  List<LaundryModel> get _filtered {
    var list = [...widget.laundries];
    if (_filterFolding) list = list.where((l) => l.offersFolding).toList();
    if (_filterPickup) list = list.where((l) => l.offersPickup).toList();
    if (_filterDelivery) list = list.where((l) => l.offersDelivery).toList();
    if (widget.userLat != null) {
      list.sort((a, b) =>
          (_distanceTo(a) ?? 9999).compareTo(_distanceTo(b) ?? 9999));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.40,
      minChildSize: 0.12,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.12, 0.40, 0.92],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.scaffoldBackground,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radius2xl)),
            border: Border(
              top: BorderSide(color: AppColors.border),
              left: BorderSide(color: AppColors.border),
              right: BorderSide(color: AppColors.border),
            ),
          ),
          child: Column(
            children: [
              // ── Poignée ─────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  final target =
                      _sheetController.size > 0.3 ? 0.12 : 0.40;
                  _sheetController.animateTo(target,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                },
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

              // ── En-tête ──────────────────────────────────────────────
              // ClipRect + AnimatedAlign pour animer hauteur ET opacité.
              // AnimatedOpacity seul ne réduit pas la hauteur → overflow à 0.12.
              ClipRect(
               child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                heightFactor: _sheetController.isAttached &&
                        _sheetController.size > 0.18
                    ? 1.0
                    : 0.0,
                child: AnimatedOpacity(
                opacity: _sheetController.isAttached &&
                        _sheetController.size > 0.18
                    ? 1.0
                    : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Laveries à proximité',
                                    style: tt.titleLarge),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${filtered.length} laverie${filtered.length > 1 ? 's' : ''} trouvée${filtered.length > 1 ? 's' : ''}',
                                  style: tt.labelSmall?.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Filtres ────────────────────────────────────────
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl),
                        children: [
                          _FilterChip(
                            label: 'Pliage',
                            icon: PhosphorIconsRegular.sparkle,
                            active: _filterFolding,
                            onTap: () =>
                                setState(() => _filterFolding = !_filterFolding),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FilterChip(
                            label: 'Collecte',
                            icon: PhosphorIconsRegular.arrowsClockwise,
                            active: _filterPickup,
                            onTap: () =>
                                setState(() => _filterPickup = !_filterPickup),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FilterChip(
                            label: 'Livraison',
                            icon: PhosphorIconsRegular.navigationArrow,
                            active: _filterDelivery,
                            onTap: () =>
                                setState(() => _filterDelivery = !_filterDelivery),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),       // Column
              ),         // AnimatedOpacity
               ),        // AnimatedAlign
              ),          // ClipRect

              // ── Liste ────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(
                            bottom: 120,
                            top: AppSpacing.xs,
                            left: AppSpacing.lg,
                            right: AppSpacing.lg),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _LaundryCard(
                          laundry: filtered[i],
                          distanceKm: _distanceTo(filtered[i]),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FilterChip
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final PhosphorIconData icon;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border:
              Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon,
                size: 13,
                color: active ? AppColors.surface : AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: active ? AppColors.surface : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LaundryCard — carte compacte dans le sheet
// ─────────────────────────────────────────────────────────────────────────────

class _LaundryCard extends StatelessWidget {
  final LaundryModel laundry;
  final double? distanceKm;

  const _LaundryCard({required this.laundry, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => context.push('/laundry/${laundry.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Photo / placeholder
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSpacing.radiusXl)),
              child: SizedBox(
                width: 96,
                height: 96,
                child: laundry.photoUrls.isNotEmpty
                    ? Image.network(laundry.photoUrls.first,
                        fit: BoxFit.cover)
                    : Container(
                        color: AppColors.inputBackground,
                        child: const Center(
                          child: PhosphorIcon(
                              PhosphorIconsRegular.washingMachine,
                              size: 36,
                              color: AppColors.textSecondary),
                        ),
                      ),
              ),
            ),

            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(laundry.name,
                        style: tt.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.xs),
                    Row(children: [
                      const PhosphorIcon(PhosphorIconsRegular.mapPin,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          laundry.address,
                          style: tt.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    const SizedBox(height: AppSpacing.sm),
                    Row(children: [
                      if (laundry.reviewCount > 0) ...[
                        const PhosphorIcon(PhosphorIconsFill.star,
                            size: 12, color: AppColors.starActive),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${laundry.rating.toStringAsFixed(1)} (${laundry.reviewCount})',
                          style: tt.labelSmall
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                        if (distanceKm != null)
                          Text(' · ',
                              style: tt.labelSmall
                                  ?.copyWith(color: AppColors.textSecondary)),
                      ],
                      if (distanceKm != null)
                        Text(
                          distanceKm! < 1
                              ? '${(distanceKm! * 1000).toStringAsFixed(0)} m'
                              : '${distanceKm!.toStringAsFixed(1)} km',
                          style: tt.bodySmall,
                        ),
                    ]),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: const PhosphorIcon(PhosphorIconsRegular.caretRight,
                  size: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 200;
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!compact) ...[
                      const PhosphorIcon(PhosphorIconsRegular.washingMachine,
                          size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    Text('Aucune laverie à proximité',
                        style: tt.titleMedium,
                        textAlign: TextAlign.center),
                    if (!compact) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Aucune laverie ne correspond à vos filtres.',
                        textAlign: TextAlign.center,
                        style: tt.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

extension on double {
  double sqrt() {
    if (this == 0) return 0;
    var g = this / 2;
    for (var i = 0; i < 20; i++) {
      g = (g + this / g) / 2;
    }
    return g;
  }
}
