import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/providers/laundry_providers.dart';
import '../../domain/models/laundry_model.dart';
import '../../../authentication/data/repositories/user_repository.dart';
import '../../../machines_map/data/providers/machine_providers.dart';
import '../../../machines_map/domain/models/machine_model.dart';
import '../../../machines_map/presentation/widgets/machine_card.dart';
import '../../../reviews/presentation/widgets/star_rating_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

final _ownerBadgeProvider =
    FutureProvider.family<bool, String>((ref, ownerId) async {
  final user = await UserRepository().getUser(ownerId);
  return user?.hasVerifiedBadge ?? false;
});

class LaundryDetailScreen extends ConsumerStatefulWidget {
  final String laundryId;

  const LaundryDetailScreen({super.key, required this.laundryId});

  @override
  ConsumerState<LaundryDetailScreen> createState() =>
      _LaundryDetailScreenState();
}

class _LaundryDetailScreenState extends ConsumerState<LaundryDetailScreen> {
  int _photoIndex = 0;

  String _todayKey() {
    const days = [
      'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
    ];
    return days[DateTime.now().weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final laundryAsync = ref.watch(laundryProvider(widget.laundryId));
    final machinesAsync = ref.watch(machinesProvider(widget.laundryId));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: laundryAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (laundry) {
          if (laundry == null) {
            return const Center(child: Text('Laverie introuvable'));
          }
          return _Body(
            laundry: laundry,
            machinesAsync: machinesAsync,
            photoIndex: _photoIndex,
            onPhotoChanged: (i) => setState(() => _photoIndex = i),
            todayKey: _todayKey(),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Body — scrollable principal
// ─────────────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final LaundryModel laundry;
  final AsyncValue<List<MachineModel>> machinesAsync;
  final int photoIndex;
  final ValueChanged<int> onPhotoChanged;
  final String todayKey;

  const _Body({
    required this.laundry,
    required this.machinesAsync,
    required this.photoIndex,
    required this.onPhotoChanged,
    required this.todayKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final hasBadge =
        ref.watch(_ownerBadgeProvider(laundry.ownerId)).valueOrNull ?? false;

    return CustomScrollView(
      slivers: [
        // ── SliverAppBar avec carrousel ──────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: _PhotoCarousel(
              photoUrls: laundry.photoUrls,
              currentIndex: photoIndex,
              onPageChanged: onPhotoChanged,
              laundryName: laundry.name,
              hasVerifiedBadge: hasBadge,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Rating & Adresse ─────────────────────────────────
                AppSpacing.gapLg,
                _RatingRow(laundry: laundry),
                AppSpacing.gapMd,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PhosphorIcon(PhosphorIconsRegular.mapPin,
                        size: 16, color: AppColors.textSecondary),
                    AppSpacing.hGapXs,
                    Expanded(
                      child: Text(
                        laundry.address,
                        style: tt.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),

                // ── Description ──────────────────────────────────────
                if (laundry.description != null &&
                    laundry.description!.isNotEmpty) ...[
                  AppSpacing.gapLg,
                  Text(
                    laundry.description!,
                    style: tt.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary, height: 1.5),
                  ),
                ],

                const Divider(
                    color: AppColors.border, thickness: 1, height: AppSpacing.xxl),

                // ── Horaires ─────────────────────────────────────────
                _SectionTitle('Horaires d\'ouverture'),
                AppSpacing.gapMd,
                _OpeningHours(
                    openingHours: laundry.openingHours, todayKey: todayKey),

                const Divider(
                    color: AppColors.border, thickness: 1, height: AppSpacing.xxl),

                // ── Services ─────────────────────────────────────────
                _SectionTitle('Services proposés'),
                AppSpacing.gapMd,
                _ServicesSection(laundry: laundry),

                const Divider(
                    color: AppColors.border, thickness: 1, height: AppSpacing.xxl),

                // ── Machines ─────────────────────────────────────────
                _SectionTitle('Nos machines'),
                AppSpacing.gapMd,
                _MachinesList(
                    machinesAsync: machinesAsync, laundryId: laundry.id),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PhotoCarousel
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoCarousel extends StatelessWidget {
  final List<String> photoUrls;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final String laundryName;
  final bool hasVerifiedBadge;

  const _PhotoCarousel({
    required this.photoUrls,
    required this.currentIndex,
    required this.onPageChanged,
    required this.laundryName,
    this.hasVerifiedBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo ou placeholder
        if (photoUrls.isEmpty)
          Container(
            color: AppColors.inputBackground,
            child: const Center(
              child: PhosphorIcon(
                PhosphorIconsRegular.washingMachine,
                size: 56,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          PageView.builder(
            itemCount: photoUrls.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, i) => Image.network(
              photoUrls[i],
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, _) => Container(
                color: AppColors.inputBackground,
                child: const Center(
                  child: PhosphorIcon(PhosphorIconsRegular.washingMachine,
                      size: 48, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),

        // Dégradé bas + nom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
                stops: const [0.3, 1.0],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    laundryName,
                    style: tt.titleLarge?.copyWith(color: AppColors.surface),
                    maxLines: 2,
                  ),
                ),
                if (hasVerifiedBadge) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Tooltip(
                    message: 'Laverie vérifiée',
                    child: const PhosphorIcon(
                      PhosphorIconsFill.sealCheck,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Indicateurs de page
        if (photoUrls.length > 1)
          Positioned(
            bottom: AppSpacing.md,
            right: AppSpacing.lg,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                photoUrls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: i == currentIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == currentIndex
                        ? AppColors.surface
                        : AppColors.surface.withValues(alpha: 0.5),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RatingRow
// ─────────────────────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final LaundryModel laundry;
  const _RatingRow({required this.laundry});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final rating = laundry.rating.clamp(0.0, 5.0).round();

    return Row(
      children: [
        StarRatingWidget(rating: rating, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(
          laundry.rating.toStringAsFixed(1),
          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '(${laundry.reviewCount} avis)',
          style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OpeningHours
// ─────────────────────────────────────────────────────────────────────────────

class _OpeningHours extends StatelessWidget {
  final Map<String, String> openingHours;
  final String todayKey;

  const _OpeningHours(
      {required this.openingHours, required this.todayKey});

  static const _orderedDays = [
    'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (openingHours.isEmpty) {
      return Text(
        'Horaires non renseignés',
        style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }

    final entries = _orderedDays
        .where((d) => openingHours.containsKey(d))
        .map((d) => MapEntry(d, openingHours[d]!))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final index = e.key;
          final day = e.value.key;
          final hours = e.value.value;
          final isToday = day == todayKey;
          final isLast = index == entries.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _capitalize(day),
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: isToday ? FontWeight.w700 : null,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.textBody,
                        ),
                      ),
                    ),
                    Text(
                      hours,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: isToday ? FontWeight.w700 : null,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          "Auj.",
                          style: tt.labelSmall?.copyWith(
                              color: AppColors.surface, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                    color: AppColors.border, thickness: 1, height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────────────────────────────────────
// _ServicesSection
// ─────────────────────────────────────────────────────────────────────────────

class _ServicesSection extends StatelessWidget {
  final LaundryModel laundry;
  const _ServicesSection({required this.laundry});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final chips = <_ServiceChipData>[];

    if (laundry.offersFolding) {
      chips.add(_ServiceChipData(
          icon: PhosphorIconsRegular.sparkle, label: 'Pliage inclus'));
    }
    if (laundry.offersPickup) {
      chips.add(_ServiceChipData(
          icon: PhosphorIconsRegular.arrowsClockwise, label: 'Collecte disponible'));
    }
    if (laundry.offersDelivery) {
      chips.add(_ServiceChipData(
          icon: PhosphorIconsRegular.navigationArrow, label: 'Livraison disponible'));
    }

    if (chips.isEmpty) {
      return Text(
        'Aucun service additionnel',
        style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: chips.map((c) => _ServiceChip(data: c)).toList(),
        ),
        if (laundry.hasDelivery) ...[
          AppSpacing.gapMd,
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PhosphorIcon(PhosphorIconsRegular.info,
                    size: 14, color: AppColors.textSecondary),
                AppSpacing.hGapXs,
                Text(
                  'Livraison : ${laundry.deliveryFee!.toStringAsFixed(2)} € (rayon ${laundry.deliveryZoneKm} km)',
                  style: tt.labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ServiceChipData {
  final PhosphorIconData icon;
  final String label;
  _ServiceChipData({required this.icon, required this.label});
}

class _ServiceChip extends StatelessWidget {
  final _ServiceChipData data;
  const _ServiceChip({required this.data});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm - 2),
      decoration: BoxDecoration(
        color: AppColors.confirmedBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(data.icon, size: 14, color: AppColors.confirmedText),
          AppSpacing.hGapXs,
          Text(
            data.label,
            style: tt.labelSmall?.copyWith(
                color: AppColors.confirmedText, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MachinesList
// ─────────────────────────────────────────────────────────────────────────────

class _MachinesList extends StatelessWidget {
  final AsyncValue<List<MachineModel>> machinesAsync;
  final String laundryId;

  const _MachinesList({required this.machinesAsync, required this.laundryId});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return machinesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      ),
      error: (e, _) =>
          Text('Erreur : $e', style: tt.bodySmall),
      data: (machines) {
        if (machines.isEmpty) {
          return Column(
            children: [
              const PhosphorIcon(PhosphorIconsRegular.washingMachine,
                  size: 48, color: AppColors.textSecondary),
              AppSpacing.gapMd,
              Text(
                'Aucune machine disponible pour l\'instant',
                style: tt.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }

        return Column(
          children: machines
              .map((m) => LaundryMachineCard(
                    machine: m,
                    laundryId: laundryId,
                    onTap: () =>
                        context.push('/laundry/$laundryId/machine/${m.id}'),
                  ))
              .toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionTitle
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}
