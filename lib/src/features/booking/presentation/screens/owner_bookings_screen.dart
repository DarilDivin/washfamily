import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/models/reservation_model.dart';
import '../../domain/models/reservation_status_helper.dart';
import '../../data/repositories/firestore_reservation_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Tableau de bord du propriétaire : demandes de réservation reçues.
class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = FirestoreReservationRepository();

  static const _activeStatuses = {
    'CONFIRMED', 'PICKED_UP', 'IN_PROGRESS', 'READY'
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
        title: Text('Demandes reçues', style: tt.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
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
                labelStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: tt.labelLarge,
                padding: const EdgeInsets.all(AppSpacing.xs),
                tabs: const [
                  Tab(text: 'En attente'),
                  Tab(text: 'En cours'),
                  Tab(text: 'Historique'),
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

          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (uid == null) {
            return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PhosphorIcon(PhosphorIconsRegular.lock,
                        size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Vous devez être connecté.',
                        style: tt.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary)),
                  ]),
            );
          }

          Future.microtask(
              () => _repo.autoCancelGhostings(uid, isOwner: true));

          return StreamBuilder<List<ReservationModel>>(
            stream: _repo.streamReservationsByOwner(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const PhosphorIcon(
                              PhosphorIconsRegular.warningCircle,
                              size: 48,
                              color: AppColors.error),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Erreur de chargement', style: tt.titleMedium),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: tt.bodySmall,
                          ),
                        ]),
                  ),
                );
              }

              final all = snapshot.data ?? [];
              final pending =
                  all.where((r) => r.status == 'PENDING').toList();
              final active = all
                  .where((r) => _activeStatuses.contains(r.status))
                  .toList();
              final history = all
                  .where((r) =>
                      r.status == 'CANCELLED' || r.status == 'COMPLETED')
                  .toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _OwnerList(
                      reservations: pending,
                      emptyMessage: 'Aucune demande en attente',
                      repo: _repo),
                  _OwnerList(
                      reservations: active,
                      emptyMessage: 'Aucune réservation en cours',
                      repo: _repo),
                  _OwnerList(
                      reservations: history,
                      emptyMessage: 'Aucun historique',
                      repo: _repo),
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
// _OwnerList
// ─────────────────────────────────────────────────────────────────────────────

class _OwnerList extends StatelessWidget {
  final List<ReservationModel> reservations;
  final String emptyMessage;
  final FirestoreReservationRepository repo;

  const _OwnerList({
    required this.reservations,
    required this.emptyMessage,
    required this.repo,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (reservations.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: AppColors.completedBg),
          child: const PhosphorIcon(PhosphorIconsRegular.tray,
              size: 44, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(emptyMessage,
            style: tt.titleSmall?.copyWith(color: AppColors.textPrimary)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: reservations.length,
      itemBuilder: (context, i) => _OwnerReservationCard(
        reservation: reservations[i],
        repo: repo,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OwnerReservationCard
// ─────────────────────────────────────────────────────────────────────────────

class _OwnerReservationCard extends StatefulWidget {
  final ReservationModel reservation;
  final FirestoreReservationRepository repo;

  const _OwnerReservationCard(
      {required this.reservation, required this.repo});

  @override
  State<_OwnerReservationCard> createState() => _OwnerReservationCardState();
}

class _OwnerReservationCardState extends State<_OwnerReservationCard> {
  bool _loading = false;

  static const _progressSteps = [
    'CONFIRMED', 'PICKED_UP', 'IN_PROGRESS', 'READY', 'COMPLETED'
  ];

  String? _nextStatus(String current) {
    if (current == 'PENDING') return 'CONFIRMED';
    final idx = _progressSteps.indexOf(current);
    if (idx < 0 || idx >= _progressSteps.length - 1) return null;
    return _progressSteps[idx + 1];
  }

  String _nextLabel(String current) {
    switch (current) {
      case 'CONFIRMED':
        return 'Linge récupéré';
      case 'PICKED_UP':
        return 'Démarrer le lavage';
      case 'IN_PROGRESS':
        return 'Lavage terminé';
      case 'READY':
        return 'Linge remis au client';
      default:
        return '';
    }
  }

  Future<void> _advance() async {
    final next = _nextStatus(widget.reservation.status);
    if (next == null) return;
    setState(() => _loading = true);
    await widget.repo.updateStatusByOwner(widget.reservation.id, next);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _reject() async {
    final tt = Theme.of(context).textTheme;
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          title: Row(children: [
            const PhosphorIcon(PhosphorIconsRegular.xCircle,
                color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text('Refuser la demande', style: tt.titleMedium),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Indiquez une raison (optionnel) :',
                  style: tt.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ex : Machine en maintenance ce jour-là…',
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide:
                          const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide:
                          const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide:
                          const BorderSide(color: AppColors.error)),
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd))),
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Confirmer le refus'),
            ),
          ],
        );
      },
    );
    if (reason == null) return;
    setState(() => _loading = true);
    await widget.repo.updateStatus(widget.reservation.id, 'CANCELLED',
        cancelReason: reason);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final r = widget.reservation;

    final statusLabel = ReservationStatusHelper.label(r.status);
    final statusColor = ReservationStatusHelper.textColor(r.status);
    final statusBg = ReservationStatusHelper.backgroundColor(r.status);

    final isPending = r.status == 'PENDING';
    final isActive = _progressSteps.contains(r.status) && r.status != 'COMPLETED';
    final nextStatus = _nextStatus(r.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Machine + statut ────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.completedBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const PhosphorIcon(
                  PhosphorIconsRegular.washingMachine,
                  color: AppColors.primary,
                  size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: Text(r.machineBrand, style: tt.titleSmall)),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + AppSpacing.xs,
                  vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd)),
              child: Text(statusLabel,
                  style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: statusColor)),
            ),
          ]),

          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),

          // ── Locataire ───────────────────────────────────────────────
          Row(children: [
            const PhosphorIcon(PhosphorIconsRegular.user,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Text('Locataire : ', style: tt.bodySmall),
            Text(
              r.renterId.length > 12
                  ? '${r.renterId.substring(0, 12)}…'
                  : r.renterId,
              style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),

          // ── Date & Prix ─────────────────────────────────────────────
          Row(children: [
            const PhosphorIcon(PhosphorIconsRegular.calendarBlank,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              DateFormat('EEE d MMM yyyy', 'fr').format(r.startTime),
              style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: AppSpacing.md),
            const PhosphorIcon(PhosphorIconsRegular.clock,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${DateFormat('HH:mm').format(r.startTime)} → ${DateFormat('HH:mm').format(r.endTime)}',
              style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text('${r.totalPrice.toStringAsFixed(2)} €',
                style: tt.titleMedium
                    ?.copyWith(color: AppColors.primary)),
          ]),

          // ── Options choisies ────────────────────────────────────────
          _ServiceSummary(reservation: r),

          // ── Instructions ────────────────────────────────────────────
          if (r.washInstructions != null &&
              r.washInstructions!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd)),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PhosphorIcon(
                        PhosphorIconsRegular.notepad,
                        size: 13,
                        color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: Text(r.washInstructions!,
                            style: tt.bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic))),
                  ]),
            ),
          ],

          // ── Note du locataire ───────────────────────────────────────
          if (r.renterNote != null && r.renterNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd)),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PhosphorIcon(
                        PhosphorIconsRegular.chatCircle,
                        size: 13,
                        color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: Text(r.renterNote!,
                            style: tt.bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic))),
                  ]),
            ),
          ],

          // ── Barre de progression ────────────────────────────────────
          if (isActive || r.status == 'COMPLETED') ...[
            const SizedBox(height: AppSpacing.md),
            _StatusProgressBar(currentStatus: r.status),
          ],

          // ── Actions ─────────────────────────────────────────────────
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary)),
            )
          else ...[
            // PENDING : Refuser / Confirmer
            if (isPending) ...[
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd)),
                    ),
                    child: const Text('Refuser'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _advance,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd)),
                    ),
                    child: const Text('Confirmer'),
                  ),
                ),
              ]),
            ],

            // En cours : Passer à l'étape suivante
            if (isActive && nextStatus != null) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _advance,
                icon: const PhosphorIcon(PhosphorIconsRegular.arrowRight,
                    size: 16),
                label: Text(_nextLabel(r.status)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md),
                  minimumSize: const Size(double.infinity, 0),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd)),
                ),
              ),
            ],
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusProgressBar — barre de progression pour les statuts actifs
// ─────────────────────────────────────────────────────────────────────────────

class _StatusProgressBar extends StatelessWidget {
  final String currentStatus;

  static const _steps = [
    ('CONFIRMED', 'Confirmée'),
    ('PICKED_UP', 'Récupéré'),
    ('IN_PROGRESS', 'Lavage'),
    ('READY', 'Prêt'),
    ('COMPLETED', 'Rendu'),
  ];

  const _StatusProgressBar({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final currentIdx =
        _steps.indexWhere((s) => s.$1 == currentStatus);

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final done = stepIdx < currentIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: done ? AppColors.primary : AppColors.border,
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final isDone = stepIdx < currentIdx;
        final isCurrent = stepIdx == currentIdx;
        final label = _steps[stepIdx].$2;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? AppColors.primary
                    : isDone
                        ? AppColors.primary
                        : AppColors.border,
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const PhosphorIcon(PhosphorIconsRegular.check,
                      size: 11, color: AppColors.surface)
                  : isCurrent
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface),
                        )
                      : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                fontSize: 9,
                fontWeight:
                    isCurrent ? FontWeight.w700 : FontWeight.w400,
                color: isCurrent
                    ? AppColors.primary
                    : isDone
                        ? AppColors.textSecondary
                        : AppColors.border,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ServiceSummary — résumé des options choisies par le locataire
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceSummary extends StatelessWidget {
  final ReservationModel reservation;
  const _ServiceSummary({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final r = reservation;

    final tags = <(PhosphorIconData, String)>[];
    if (r.pickupMethod == 'COLLECTED') {
      tags.add((PhosphorIconsRegular.van, 'Collecte à domicile'));
    }
    if (r.requestedFolding) {
      tags.add((PhosphorIconsRegular.tShirt, 'Pliage'));
    }
    if (r.requestedDelivery) {
      tags.add((PhosphorIconsRegular.package,
          r.deliveryAddress != null ? 'Livraison → ${r.deliveryAddress}' : 'Livraison'));
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: tags
            .map((tag) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.completedBg,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(tag.$1,
                          size: 11, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(tag.$2,
                          style: tt.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
