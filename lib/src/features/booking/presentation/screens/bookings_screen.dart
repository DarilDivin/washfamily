import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/models/reservation_model.dart';
import '../../domain/models/reservation_status_helper.dart';
import '../../data/repositories/firestore_reservation_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = FirestoreReservationRepository();

  static const _activeStatuses = {
    'PENDING', 'CONFIRMED', 'PICKED_UP', 'IN_PROGRESS', 'READY'
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Mes Réservations', style: tt.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                ),
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle:
                    tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: tt.labelLarge,
                padding: const EdgeInsets.all(AppSpacing.xs),
                tabs: const [
                  Tab(text: 'En cours'),
                  Tab(text: 'Terminées'),
                  Tab(text: 'Annulées'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          final uid = authSnapshot.data?.uid;

          if (authSnapshot.connectionState == ConnectionState.waiting ||
              uid == null) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          Future.microtask(() async {
            await _repo.autoCancelGhostings(uid, isOwner: false);
            await _repo.checkAndSendReminders(uid);
          });

          return StreamBuilder<List<ReservationModel>>(
            stream: _repo.streamReservationsByRenter(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary));
              }
              if (snapshot.hasError) {
                return _ErrorWidget(message: snapshot.error.toString());
              }

              final all = snapshot.data ?? [];
              final active = all
                  .where((r) => _activeStatuses.contains(r.status))
                  .toList();
              final completed =
                  all.where((r) => r.status == 'COMPLETED').toList();
              final cancelled =
                  all.where((r) => r.status == 'CANCELLED').toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _ReservationList(
                      reservations: active,
                      emptyMessage: 'Aucune réservation en cours',
                      emptyIcon: PhosphorIconsRegular.calendarBlank),
                  _ReservationList(
                      reservations: completed,
                      emptyMessage: 'Aucune réservation terminée',
                      emptyIcon: PhosphorIconsRegular.clockCounterClockwise),
                  _ReservationList(
                      reservations: cancelled,
                      emptyMessage: 'Aucune réservation annulée',
                      emptyIcon: PhosphorIconsRegular.xCircle),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ReservationList extends StatelessWidget {
  final List<ReservationModel> reservations;
  final String emptyMessage;
  final PhosphorIconData emptyIcon;

  const _ReservationList({
    required this.reservations,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return _EmptyState(message: emptyMessage, icon: emptyIcon);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      itemCount: reservations.length,
      itemBuilder: (context, i) =>
          _ReservationCard(reservation: reservations[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final r = reservation;

    final statusLabel = ReservationStatusHelper.label(r.status);
    final statusColor = ReservationStatusHelper.textColor(r.status);
    final statusBg = ReservationStatusHelper.backgroundColor(r.status);
    final statusIcon = ReservationStatusHelper.icon(r.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── En-tête ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.completedBg,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const PhosphorIcon(
                      PhosphorIconsRegular.washingMachine,
                      color: AppColors.primary,
                      size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Machine',
                          style: tt.labelSmall?.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5)),
                      Text(r.machineBrand.toUpperCase(),
                          style: tt.titleSmall
                              ?.copyWith(color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + AppSpacing.xs,
                      vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(statusIcon,
                          color: statusColor, size: 13),
                      const SizedBox(width: AppSpacing.xs),
                      Text(statusLabel,
                          style: tt.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border),

          // ── Date & Prix ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const PhosphorIcon(PhosphorIconsRegular.calendarBlank,
                            size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          DateFormat('EEEE d MMM yyyy', 'fr')
                              .format(r.startTime),
                          style: tt.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textBody),
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.sm),
                      Row(children: [
                        const PhosphorIcon(PhosphorIconsRegular.clock,
                            size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${DateFormat('HH:mm').format(r.startTime)} - ${DateFormat('HH:mm').format(r.endTime)}',
                          style: tt.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textBody),
                        ),
                      ]),
                      if (r.machineAddress != null &&
                          r.machineAddress!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PhosphorIcon(PhosphorIconsRegular.mapPin,
                                size: 15, color: AppColors.textSecondary),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(r.machineAddress!,
                                  style: tt.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 56,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                ),
                Column(
                  children: [
                    Text('Total', style: tt.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      '${r.totalPrice.toStringAsFixed(2)} €',
                      style: tt.titleLarge
                          ?.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Détails du service ────────────────────────────────────
          _ServiceDetails(reservation: r),

          // ── Action : Annuler ──────────────────────────────────────
          if (r.status == 'PENDING') ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.radiusXl)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: OutlinedButton(
                onPressed: () => _cancel(context, r),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd)),
                ),
                child: const Text('Annuler la réservation'),
              ),
            ),
          ],

          // ── Action : Laisser un avis ──────────────────────────────
          if (r.status == 'COMPLETED' && !r.hasBeenReviewed) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.radiusXl)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: OutlinedButton.icon(
                onPressed: () => context.push('/reviews/new', extra: r),
                icon: const PhosphorIcon(PhosphorIconsRegular.star,
                    size: 15),
                label: const Text('Laisser un avis'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.textPrimary),
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, ReservationModel r) async {
    final tt = Theme.of(context).textTheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        title: Row(children: [
          const PhosphorIcon(PhosphorIconsRegular.warning,
              color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text('Annulation', style: tt.titleMedium),
        ]),
        content: Text(
            'Voulez-vous vraiment annuler cette réservation ? Cette action est irréversible.',
            style: tt.bodyMedium
                ?.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Retour')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirestoreReservationRepository().cancelReservation(r.id);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ServiceDetails — affiche le programme, mode de remise et options choisies
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceDetails extends StatelessWidget {
  final ReservationModel reservation;
  const _ServiceDetails({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final r = reservation;

    final hasDetails = r.selectedProgramId != null ||
        r.pickupMethod == 'COLLECTED' ||
        r.requestedFolding ||
        r.requestedDelivery ||
        (r.washInstructions != null && r.washInstructions!.isNotEmpty);

    if (!hasDetails) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.pickupMethod == 'COLLECTED')
            _DetailChip(
              icon: PhosphorIconsRegular.van,
              label: 'Collecte à domicile',
            ),
          if (r.requestedFolding)
            _DetailChip(
              icon: PhosphorIconsRegular.tShirt,
              label: 'Pliage demandé',
            ),
          if (r.requestedDelivery)
            _DetailChip(
              icon: PhosphorIconsRegular.package,
              label: r.deliveryAddress != null
                  ? 'Livraison → ${r.deliveryAddress}'
                  : 'Livraison demandée',
            ),
          if (r.washInstructions != null &&
              r.washInstructions!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PhosphorIcon(PhosphorIconsRegular.chatCircle,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    r.washInstructions!,
                    style: tt.bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(children: [
        PhosphorIcon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.textBody),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  final PhosphorIconData icon;
  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxl - AppSpacing.xs),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.completedBg,
          ),
          child: PhosphorIcon(icon, size: 52, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(message, style: tt.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text('Découvrez les machines près de chez vous !',
            style: tt.bodySmall),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ErrorWidget extends StatelessWidget {
  final String message;
  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
              color: AppColors.cancelledBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.error)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PhosphorIcon(PhosphorIconsRegular.warningCircle,
                  color: AppColors.error, size: 40),
              const SizedBox(height: AppSpacing.md),
              Text('Erreur de chargement',
                  style: tt.titleSmall
                      ?.copyWith(color: AppColors.cancelledText)),
              const SizedBox(height: AppSpacing.sm),
              Text(message,
                  textAlign: TextAlign.center,
                  style: tt.bodySmall
                      ?.copyWith(color: AppColors.cancelledText)),
            ],
          ),
        ),
      ),
    );
  }
}
