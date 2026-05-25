import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../authentication/data/providers/user_provider.dart';
import '../../../authentication/domain/models/user_model.dart';
import '../../../laundries/data/providers/laundry_providers.dart';
import '../../../laundries/data/repositories/laundry_product_repository.dart';
import '../../../laundries/domain/models/laundry_model.dart';
import '../../../laundries/domain/models/laundry_product_model.dart';
import '../../../laundries/presentation/widgets/owner_product_tile.dart';
import '../../../machines_map/data/providers/machine_providers.dart';
import '../../../machines_map/domain/models/machine_model.dart';
import '../../../machines_map/presentation/widgets/owner_machine_card.dart';
import '../../../booking/domain/models/reservation_model.dart';
import '../../../booking/domain/models/reservation_status_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  LaundryModel? _laundry;
  bool _loadingLaundry = true;
  List<ReservationModel> _recentReservations = [];
  int _totalReservations = 0;
  int _inProgressCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _loadingLaundry = false); return; }

    final laundry = await ref.read(laundryRepositoryProvider).getOwnerLaundry(uid);
    if (!mounted) return;
    setState(() { _laundry = laundry; _loadingLaundry = false; });

    if (laundry != null) await _loadStats(laundry.id, uid);
  }

  Future<void> _loadStats(String laundryId, String ownerId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('reservations')
          .where('ownerId', isEqualTo: ownerId)
          .where('laundryId', isEqualTo: laundryId)
          .orderBy('createdAt', descending: true)
          .get();

      final all = snap.docs
          .map((d) => ReservationModel.fromJson(d.data(), d.id))
          .toList();

      if (mounted) {
        setState(() {
          _totalReservations = all.length;
          _inProgressCount = all
              .where((r) => r.status == 'IN_PROGRESS' || r.status == 'PICKED_UP')
              .length;
          _recentReservations = all.take(3).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleMachineAvailability(MachineModel machine) async {
    if (_laundry == null) return;
    await ref.read(machineRepositoryProvider).setMachineAvailable(
          laundryId: _laundry!.id,
          machineId: machine.id,
          isAvailable: !machine.isAvailable,
        );
  }

  Future<void> _toggleLaundryActive(bool value) async {
    if (_laundry == null) return;
    await ref
        .read(laundryRepositoryProvider)
        .setLaundryActive(_laundry!.id, value);
    setState(() => _laundry = _laundry!.copyWith(isActive: value));
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    // Guard — redirect si pas OWNER
    ref.listen<AsyncValue<UserModel?>>(currentUserProvider, (_, next) {
      if (next.hasValue && next.value != null && !next.value!.isOwner && mounted) {
        context.go('/home');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Mon tableau de bord', style: tt.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: _loadingLaundry
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _laundry == null
              ? _NoLaundryState()
              : _DashboardBody(
                  laundry: _laundry!,
                  totalReservations: _totalReservations,
                  inProgressCount: _inProgressCount,
                  recentReservations: _recentReservations,
                  onToggleLaundryActive: _toggleLaundryActive,
                  onToggleMachine: _toggleMachineAvailability,
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// État vide : pas encore de laverie
// ─────────────────────────────────────────────────────────────────────────────

class _NoLaundryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PhosphorIcon(PhosphorIconsRegular.storefront,
                size: 64, color: AppColors.textSecondary),
            AppSpacing.gapLg,
            Text('Vous n\'avez pas encore de laverie',
                style: tt.titleMedium, textAlign: TextAlign.center),
            AppSpacing.gapSm,
            Text(
              'Créez votre laverie pour commencer à recevoir des réservations.',
              style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXl,
            FilledButton.icon(
              onPressed: () => context.push('/laundry/create'),
              icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 18),
              label: const Text('Créer ma laverie'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard complet
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardBody extends ConsumerWidget {
  final LaundryModel laundry;
  final int totalReservations;
  final int inProgressCount;
  final List<ReservationModel> recentReservations;
  final ValueChanged<bool> onToggleLaundryActive;
  final ValueChanged<MachineModel> onToggleMachine;

  const _DashboardBody({
    required this.laundry,
    required this.totalReservations,
    required this.inProgressCount,
    required this.recentReservations,
    required this.onToggleLaundryActive,
    required this.onToggleMachine,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final machinesAsync = ref.watch(machinesProvider(laundry.id));

    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        // ── En-tête laverie ──────────────────────────────────────────
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
              Row(children: [
                Expanded(
                  child: Text(laundry.name,
                      style: tt.headlineLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                AppSpacing.hGapMd,
                _ActiveBadge(isActive: laundry.isActive),
              ]),
              AppSpacing.gapMd,
              Row(children: [
                const PhosphorIcon(PhosphorIconsRegular.mapPin,
                    size: 14, color: AppColors.textSecondary),
                AppSpacing.hGapXs,
                Expanded(
                  child: Text(laundry.address,
                      style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
              AppSpacing.gapLg,
              Row(children: [
                Expanded(
                  child: Text(
                    laundry.isActive ? 'Laverie visible' : 'Laverie masquée',
                    style: tt.bodyMedium,
                  ),
                ),
                Switch(
                  value: laundry.isActive,
                  onChanged: onToggleLaundryActive,
                  activeThumbColor: AppColors.surface,
                  activeTrackColor: AppColors.success,
                  inactiveThumbColor: AppColors.surface,
                  inactiveTrackColor: AppColors.border,
                ),
              ]),
              AppSpacing.gapSm,
              OutlinedButton.icon(
                onPressed: () => context.push('/laundry/edit/${laundry.id}'),
                icon: const PhosphorIcon(PhosphorIconsRegular.pencilSimple, size: 16),
                label: const Text('Modifier la laverie'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  minimumSize: const Size(double.infinity, 0),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ],
          ),
        ),

        AppSpacing.gapLg,

        // ── Statistiques rapides ─────────────────────────────────────
        Row(children: [
          Expanded(child: _StatCard(
            label: 'Réservations',
            value: '$totalReservations',
            icon: PhosphorIconsRegular.calendarBlank,
          )),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _StatCard(
            label: 'En cours',
            value: '$inProgressCount',
            icon: PhosphorIconsRegular.washingMachine,
            highlight: inProgressCount > 0,
          )),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _StatCard(
            label: 'Note',
            value: laundry.reviewCount > 0
                ? laundry.rating.toStringAsFixed(1)
                : '—',
            icon: PhosphorIconsFill.star,
            iconColor: AppColors.starActive,
            sub: laundry.reviewCount > 0 ? '${laundry.reviewCount} avis' : null,
          )),
        ]),

        AppSpacing.gapLg,

        // ── Machines ─────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mes machines', style: tt.titleMedium),
            TextButton.icon(
              onPressed: () =>
                  context.push('/laundry/${laundry.id}/machine/add'),
              icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 16),
              label: const Text('Ajouter'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        AppSpacing.gapSm,

        machinesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Text('Erreur : $e', style: tt.bodySmall),
          data: (machines) {
            if (machines.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Aucune machine — ajoutez-en une pour commencer.',
                  style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Column(
              children: machines
                  .map((m) => OwnerMachineCard(
                        machine: m,
                        laundryId: laundry.id,
                        onEdit: () => context.push(
                          '/laundry/${laundry.id}/machine/edit',
                          extra: {'laundryId': laundry.id, 'machineId': m.id},
                        ),
                        onToggleAvailability: () => onToggleMachine(m),
                      ))
                  .toList(),
            );
          },
        ),

        AppSpacing.gapLg,

        // ── Produits ─────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mes produits', style: tt.titleMedium),
            TextButton.icon(
              onPressed: () =>
                  context.push('/laundry/${laundry.id}/products/add'),
              icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 16),
              label: const Text('Ajouter'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        AppSpacing.gapSm,

        StreamBuilder<List<LaundryProductModel>>(
          stream: LaundryProductRepository().streamAllProducts(laundry.id),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            final products = snap.data ?? [];
            if (products.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Aucun produit — ajoutez des articles pour vos locataires.',
                  style: tt.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              );
            }
            final repo = LaundryProductRepository();
            return Column(
              children: products
                  .map((p) => OwnerProductTile(
                        product: p,
                        onEdit: () => context.push(
                          '/laundry/${laundry.id}/products/add',
                          extra: p,
                        ),
                        onDelete: () async {
                          await repo.deleteProduct(
                            laundryId: laundry.id,
                            productId: p.id,
                          );
                        },
                        onToggleAvailable: (val) async {
                          await repo.setProductAvailable(
                            laundryId: laundry.id,
                            productId: p.id,
                            isAvailable: val,
                          );
                        },
                      ))
                  .toList(),
            );
          },
        ),

        AppSpacing.gapLg,

        // ── Réservations récentes ─────────────────────────────────────
        if (recentReservations.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Réservations récentes', style: tt.titleMedium),
              TextButton(
                onPressed: () => context.push('/profile/owner-bookings'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: const Text('Voir tout'),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: recentReservations.asMap().entries.map((e) {
                final i = e.key;
                final r = e.value;
                final isLast = i == recentReservations.length - 1;
                return Column(children: [
                  _ReservationRow(reservation: r),
                  if (!isLast)
                    const Divider(height: 1, color: AppColors.border),
                ]);
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sous-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveBadge extends StatelessWidget {
  final bool isActive;
  const _ActiveBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isActive ? AppColors.confirmedBg : AppColors.cancelledBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.confirmedText : AppColors.cancelledText,
          ),
        ),
        AppSpacing.hGapXs,
        Text(
          isActive ? 'Active' : 'Inactive',
          style: tt.labelSmall?.copyWith(
            color: isActive ? AppColors.confirmedText : AppColors.cancelledText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final PhosphorIconData icon;
  final Color? iconColor;
  final String? sub;
  final bool highlight;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.sub,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: highlight ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(icon,
              size: 18,
              color: iconColor ??
                  (highlight ? AppColors.primary : AppColors.textSecondary)),
          AppSpacing.gapSm,
          Text(value,
              style: tt.titleMedium?.copyWith(
                  color: highlight ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: FontWeight.w700)),
          if (sub != null)
            Text(sub!,
                style: tt.labelSmall?.copyWith(color: AppColors.textSecondary)),
          AppSpacing.gapXs,
          Text(label,
              style: tt.labelSmall?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ReservationRow extends StatelessWidget {
  final ReservationModel reservation;
  const _ReservationRow({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bg = ReservationStatusHelper.backgroundColor(reservation.status);
    final fg = ReservationStatusHelper.textColor(reservation.status);
    final label = ReservationStatusHelper.label(reservation.status);
    final start = reservation.startTime;
    final dateLabel =
        '${start.day.toString().padLeft(2,'0')}/${start.month.toString().padLeft(2,'0')} '
        '${start.hour.toString().padLeft(2,'0')}h${start.minute.toString().padLeft(2,'0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + AppSpacing.xs, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
          child: Text(label,
              style: tt.labelSmall?.copyWith(
                  color: fg, fontWeight: FontWeight.w600, fontSize: 10)),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Text(
            reservation.machineBrand,
            style: tt.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(dateLabel,
            style: tt.bodySmall?.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }
}
