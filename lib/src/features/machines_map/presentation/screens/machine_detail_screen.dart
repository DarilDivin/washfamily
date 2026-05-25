import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/providers/machine_providers.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/models/wash_program_model.dart';
import '../../../laundries/data/providers/laundry_providers.dart';
import '../../../laundries/domain/models/laundry_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class MachineDetailScreen extends ConsumerStatefulWidget {
  final String laundryId;
  final String machineId;

  const MachineDetailScreen({
    super.key,
    required this.laundryId,
    required this.machineId,
  });

  @override
  ConsumerState<MachineDetailScreen> createState() =>
      _MachineDetailScreenState();
}

class _MachineDetailScreenState extends ConsumerState<MachineDetailScreen> {
  MachineModel? _machine;
  bool _loading = true;
  String? _error;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMachine();
  }

  Future<void> _loadMachine() async {
    try {
      final machine = await ref.read(machineRepositoryProvider).getMachine(
            laundryId: widget.laundryId,
            machineId: widget.machineId,
          );
      if (mounted) {
        setState(() {
          _machine = machine;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final laundryAsync = ref.watch(laundryProvider(widget.laundryId));

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null || _machine == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PhosphorIcon(PhosphorIconsRegular.washingMachine,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.lg),
              Text('Machine introuvable',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    final machine = _machine!;
    final isAvailable = machine.isAvailable;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (machine.photoUrls.isNotEmpty)
                    PageView.builder(
                      itemCount: machine.photoUrls.length,
                      onPageChanged: (i) =>
                          setState(() => _photoIndex = i),
                      itemBuilder: (_, i) => Image.network(
                        machine.photoUrls[i],
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      color: AppColors.primary,
                      child: Center(
                        child: PhosphorIcon(
                          PhosphorIconsRegular.washingMachine,
                          size: 80,
                          color: AppColors.surface.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  if (machine.photoUrls.isNotEmpty)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  if (machine.photoUrls.length > 1)
                    Positioned(
                      bottom: AppSpacing.md,
                      right: AppSpacing.lg,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          machine.photoUrls.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 2),
                            width: i == _photoIndex ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _photoIndex
                                  ? AppColors.surface
                                  : AppColors.surface
                                      .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Corps ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Infos machine ────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              machine.nickname.isNotEmpty
                                  ? machine.nickname
                                  : machine.brand,
                              style: tt.headlineLarge,
                            ),
                            if (machine.model != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${machine.brand} · ${machine.model}',
                                style: tt.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _AvailBadge(isAvailable: isAvailable),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Row(
                    children: [
                      const PhosphorIcon(PhosphorIconsRegular.drop,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Text('${machine.capacityKg} kg de capacité',
                          style: tt.bodyMedium),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Programmes ───────────────────────────────────
                  if (machine.programs.isNotEmpty) ...[
                    _SectionTitle('Programmes disponibles'),
                    const SizedBox(height: AppSpacing.md),
                    ...machine.programs.map((p) => _ProgramTile(program: p)),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // ── Services laverie ─────────────────────────────
                  laundryAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (laundry) {
                      if (laundry == null) return const SizedBox.shrink();
                      final hasServices = laundry.offersFolding ||
                          laundry.offersPickup ||
                          laundry.offersDelivery;
                      if (!hasServices) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle('Services inclus'),
                          const SizedBox(height: AppSpacing.md),
                          _LaundryServicesChips(laundry: laundry),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── CTA Réserver ─────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: FilledButton(
            onPressed: isAvailable
                ? () => context.push('/bookings/new', extra: machine)
                : null,
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.border,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd)),
            ),
            child: Text(
              isAvailable ? 'Réserver cette machine' : 'Machine indisponible',
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AvailBadge extends StatelessWidget {
  final bool isAvailable;
  const _AvailBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.confirmedBg : AppColors.cancelledBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        isAvailable ? 'Disponible' : 'Indisponible',
        style: tt.labelSmall?.copyWith(
          color: isAvailable ? AppColors.confirmedText : AppColors.cancelledText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class _ProgramTile extends StatelessWidget {
  final WashProgram program;
  const _ProgramTile({required this.program});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(program.name,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _ProgramStat(
                icon: PhosphorIconsRegular.thermometer,
                label: '${program.temperatureCelsius}°C',
              ),
              const SizedBox(width: AppSpacing.lg),
              _ProgramStat(
                icon: PhosphorIconsRegular.timer,
                label: '${program.durationMinutes} min',
              ),
              if (program.hasSpin && program.spinSpeedRpm != null) ...[
                const SizedBox(width: AppSpacing.lg),
                _ProgramStat(
                  icon: PhosphorIconsRegular.arrowsClockwise,
                  label: '${program.spinSpeedRpm} tr/min',
                ),
              ],
              if (program.isDelicate) ...[
                const SizedBox(width: AppSpacing.lg),
                _ProgramStat(
                  icon: PhosphorIconsRegular.leaf,
                  label: 'Délicat',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgramStat extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  const _ProgramStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(label,
            style:
                tt.labelSmall?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _LaundryServicesChips extends StatelessWidget {
  final LaundryModel laundry;
  const _LaundryServicesChips({required this.laundry});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (laundry.offersFolding)
          _Chip(icon: PhosphorIconsRegular.sparkle, label: 'Pliage inclus'),
        if (laundry.offersPickup)
          _Chip(
              icon: PhosphorIconsRegular.arrowsClockwise,
              label: 'Collecte disponible'),
        if (laundry.offersDelivery)
          _Chip(
              icon: PhosphorIconsRegular.navigationArrow,
              label: 'Livraison disponible'),
        if (laundry.hasDelivery)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm - 2),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              '${laundry.deliveryFee!.toStringAsFixed(2)} € · ${laundry.deliveryZoneKm} km',
              style:
                  tt.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

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
          PhosphorIcon(icon, size: 13, color: AppColors.confirmedText),
          const SizedBox(width: AppSpacing.xs),
          Text(label,
              style: tt.labelSmall?.copyWith(
                  color: AppColors.confirmedText,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
