import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/models/reservation_model.dart';
import '../../data/repositories/firestore_reservation_repository.dart';
import '../../../machines_map/domain/models/machine_model.dart';
import '../../../machines_map/domain/models/wash_program_model.dart';
import '../../../laundries/domain/models/laundry_product_model.dart';
import '../../../laundries/data/repositories/laundry_product_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Étape 2 du tunnel : Récapitulatif et confirmation de la réservation.
class BookingSummaryScreen extends StatefulWidget {
  final MachineModel machine;
  final DateTime startTime;
  final DateTime endTime;
  final double price;

  const BookingSummaryScreen({
    super.key,
    required this.machine,
    required this.startTime,
    required this.endTime,
    required this.price,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final _repo = FirestoreReservationRepository();
  final _productRepo = LaundryProductRepository();
  final _washInstructionsCtrl = TextEditingController();
  String? _selectedProgramId;
  final Set<String> _selectedProductIds = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _washInstructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vous devez être connecté pour réserver.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final isAvailable = await _repo.checkAvailability(
      laundryId: widget.machine.laundryId,
      machineId: widget.machine.id,
      start: widget.startTime,
      end: widget.endTime,
    );

    if (!isAvailable) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '⚠️ Ce créneau vient d\'être réservé. Choisissez-en un autre.'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final products = await _productRepo
          .streamProducts(widget.machine.laundryId)
          .first;
      final selected = products
          .where((p) => _selectedProductIds.contains(p.id))
          .toList();
      final productsTotal =
          selected.fold<double>(0, (sum, p) => sum + p.pricePerUnit);

      final reservation = ReservationModel(
        id: '',
        machineId: widget.machine.id,
        laundryId: widget.machine.laundryId,
        machineBrand: widget.machine.brand,
        machineAddress: widget.machine.address,
        ownerId: widget.machine.ownerId,
        renterId: user.uid,
        startTime: widget.startTime,
        endTime: widget.endTime,
        totalPrice: widget.price + productsTotal,
        status: 'PENDING',
        washInstructions: _washInstructionsCtrl.text.isNotEmpty
            ? _washInstructionsCtrl.text.trim()
            : null,
        selectedProgramId: _selectedProgramId,
        selectedProducts: selected
            .map((p) => ReservationProduct(
                  productId: p.id,
                  name: p.name,
                  pricePerUnit: p.pricePerUnit,
                ))
            .toList(),
        productsTotal: productsTotal,
      );

      final created = await _repo.createReservation(reservation);

      if (mounted) {
        setState(() => _isLoading = false);
        context.pushReplacement('/bookings/success', extra: created);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = e.toString();
      if (msg.contains('quota_exceeded') ||
          msg.contains('subscription_required') ||
          msg.contains('subscription_expired')) {
        _showQuotaDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showQuotaDialog() {
    final tt = Theme.of(context).textTheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Quota atteint', style: tt.titleMedium),
        content: Text(
          'Vous avez atteint votre limite de réservations ce mois-ci.\n'
          'Passez à un plan supérieur pour continuer.',
          style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annuler',
                style: tt.labelLarge
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/subscriptions');
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd)),
            ),
            child: Text('Voir les plans',
                style: tt.labelLarge
                    ?.copyWith(color: AppColors.surface)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final duration = widget.endTime.difference(widget.startTime);
    final machine = widget.machine;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Récapitulatif', style: tt.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Étapes visuelles ───────────────────────────────────────
          _StepIndicator(currentStep: 1),
          const SizedBox(height: AppSpacing.xl),

          // ── Machine ────────────────────────────────────────────────
          _InfoCard(
            title: 'MACHINE',
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.completedBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const PhosphorIcon(
                    PhosphorIconsRegular.washingMachine,
                    color: AppColors.primary,
                    size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(machine.brand, style: tt.titleSmall),
                    if (machine.address != null)
                      Text(machine.address!, style: tt.bodySmall),
                    Row(children: [
                      const PhosphorIcon(PhosphorIconsRegular.drop,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Text('${machine.capacityKg} kg',
                          style: tt.bodySmall),
                    ]),
                  ])),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Créneau ────────────────────────────────────────────────
          _InfoCard(
            title: 'CRÉNEAU',
            child: Column(children: [
              _DetailRow(
                icon: PhosphorIconsRegular.calendarBlank,
                label: 'Date',
                value: DateFormat('EEEE d MMMM yyyy', 'fr')
                    .format(widget.startTime),
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailRow(
                icon: PhosphorIconsRegular.clock,
                label: 'Horaire',
                value:
                    '${DateFormat('HH:mm').format(widget.startTime)} → ${DateFormat('HH:mm').format(widget.endTime)}',
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailRow(
                icon: PhosphorIconsRegular.timer,
                label: 'Durée',
                value:
                    '${duration.inHours}h${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}',
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Programme de lavage ────────────────────────────────────
          if (machine.programs.isNotEmpty) ...[
            _InfoCard(
              title: 'PROGRAMME DE LAVAGE',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choisissez le programme adapté à votre linge.',
                    style: tt.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: machine.programs
                        .map((p) => _ProgramChip(
                              program: p,
                              selected: _selectedProgramId == p.id,
                              onTap: () => setState(() {
                                _selectedProgramId = _selectedProgramId == p.id
                                    ? null
                                    : p.id;
                              }),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Instructions de lavage ─────────────────────────────────
          _InfoCard(
            title: 'INSTRUCTIONS DE LAVAGE (OPTIONNEL)',
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: TextField(
                controller: _washInstructionsCtrl,
                maxLines: 3,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText:
                      'Ex : Matières délicates, tache sur la manche droite…',
                  hintStyle: tt.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  counterStyle: tt.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                style: tt.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Produits ───────────────────────────────────────────────
          StreamBuilder<List<LaundryProductModel>>(
            stream: _productRepo
                .streamProducts(widget.machine.laundryId),
            builder: (context, snap) {
              final products = snap.data ?? [];
              if (products.isEmpty) return const SizedBox.shrink();

              final byCategory = <String, List<LaundryProductModel>>{
                'DETERGENT': [],
                'SOFTENER': [],
                'ACCESSORY': [],
              };
              for (final p in products) {
                byCategory[p.category]?.add(p);
              }
              const labels = {
                'DETERGENT': 'Lessives',
                'SOFTENER': 'Adoucissants',
                'ACCESSORY': 'Accessoires',
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCard(
                    title: 'PRODUITS EN OPTION',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: byCategory.entries
                          .where((e) => e.value.isNotEmpty)
                          .expand((e) => [
                                Text(labels[e.key]!,
                                    style: tt.labelSmall?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: AppSpacing.xs),
                                ...e.value.map((p) =>
                                    _ProductSelectionTile(
                                      product: p,
                                      selected: _selectedProductIds
                                          .contains(p.id),
                                      onChanged: p.isInStock
                                          ? (val) => setState(() {
                                                if (val == true) {
                                                  _selectedProductIds
                                                      .add(p.id);
                                                } else {
                                                  _selectedProductIds
                                                      .remove(p.id);
                                                }
                                              })
                                          : null,
                                    )),
                                const SizedBox(height: AppSpacing.md),
                              ])
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            },
          ),

          // ── Prix total ─────────────────────────────────────────────
          StreamBuilder<List<LaundryProductModel>>(
            stream: _productRepo.streamProducts(widget.machine.laundryId),
            builder: (context, snap) {
              final products = snap.data ?? [];
              final productsTotal = products
                  .where((p) => _selectedProductIds.contains(p.id))
                  .fold<double>(0, (s, p) => s + p.pricePerUnit);
              final total = widget.price + productsTotal;

              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.completedBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _PriceRow(
                        label: 'Prix lavage',
                        value: widget.price,
                        tt: tt),
                    if (productsTotal > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _PriceRow(
                          label: '+ Produits',
                          value: productsTotal,
                          tt: tt),
                      const Divider(
                          height: AppSpacing.lg, color: AppColors.border),
                    ] else
                      const SizedBox(height: AppSpacing.sm),
                    Row(children: [
                      const PhosphorIcon(PhosphorIconsRegular.currencyEur,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text('Total',
                            style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                      Text(
                        '${total.toStringAsFixed(2)} €',
                        style:
                            tt.titleLarge?.copyWith(color: AppColors.primary),
                      ),
                    ]),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 80),
        ],
      ),

      // ── CTA Confirmer ──────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: FilledButton(
            onPressed: _isLoading ? null : _confirm,
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: AppColors.surface, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const PhosphorIcon(PhosphorIconsRegular.check,
                          size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('Confirmer la réservation'),
                    ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProgramChip
// ─────────────────────────────────────────────────────────────────────────────

class _ProgramChip extends StatelessWidget {
  final WashProgram program;
  final bool selected;
  final VoidCallback onTap;

  const _ProgramChip({
    required this.program,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(PhosphorIconsRegular.thermometer,
                size: 13,
                color: selected
                    ? AppColors.surface
                    : AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${program.name} · ${program.temperatureCelsius}°C',
              style: tt.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    selected ? AppColors.surface : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${program.durationMinutes}min',
              style: tt.labelSmall?.copyWith(
                color: selected
                    ? AppColors.surface.withValues(alpha: 0.75)
                    : AppColors.textSecondary,
              ),
            ),
            if (program.isDelicate) ...[
              const SizedBox(width: AppSpacing.xs),
              PhosphorIcon(PhosphorIconsRegular.leaf,
                  size: 11,
                  color: selected ? AppColors.surface : AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StepIndicator
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Step(n: 1, label: 'Créneau', done: currentStep > 0),
      _StepLine(active: currentStep >= 1),
      _Step(n: 2, label: 'Récap', active: currentStep == 1),
      _StepLine(active: false),
      _Step(n: 3, label: 'Confirmé', active: false),
    ]);
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String label;
  final bool active;
  final bool done;
  const _Step(
      {required this.n,
      required this.label,
      this.active = false,
      this.done = false});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final highlight = active || done;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: highlight ? AppColors.primary : AppColors.border,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: done
            ? const PhosphorIcon(PhosphorIconsRegular.check,
                color: AppColors.surface, size: 16)
            : Text('$n',
                style: tt.labelLarge?.copyWith(
                    color: highlight
                        ? AppColors.surface
                        : AppColors.textSecondary)),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(label,
          style: tt.labelSmall?.copyWith(
              fontSize: 10,
              color: highlight
                  ? AppColors.primary
                  : AppColors.textSecondary)),
    ]);
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({required this.active});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 14),
          color: active ? AppColors.primary : AppColors.border,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _InfoCard
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: tt.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.5)),
        const SizedBox(height: AppSpacing.md),
        child,
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DetailRow
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        child: PhosphorIcon(icon, size: 15, color: AppColors.primary),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(label, style: tt.bodySmall),
            Text(value,
                style: tt.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ])),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProductSelectionTile
// ─────────────────────────────────────────────────────────────────────────────

class _ProductSelectionTile extends StatelessWidget {
  final LaundryProductModel product;
  final bool selected;
  final ValueChanged<bool?>? onChanged;

  const _ProductSelectionTile({
    required this.product,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final outOfStock = !product.isInStock;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: selected ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        children: [
          // Photo ou icône catégorie
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: product.photoUrl != null
                  ? Image.network(product.photoUrl!,
                      width: 40, height: 40, fit: BoxFit.cover)
                  : Container(
                      width: 40,
                      height: 40,
                      color: AppColors.inputBackground,
                      child: Center(
                        child: PhosphorIcon(
                          product.category == 'ACCESSORY'
                              ? PhosphorIconsRegular.package
                              : PhosphorIconsRegular.drop,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: tt.bodyMedium?.copyWith(
                        color: outOfStock
                            ? AppColors.textSecondary
                            : AppColors.textPrimary)),
                Text(
                  '+${product.pricePerUnit.toStringAsFixed(2)} € / ${product.unit}',
                  style: tt.labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                if (outOfStock)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.cancelledBg,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text('Rupture de stock',
                        style: tt.labelSmall?.copyWith(
                            color: AppColors.cancelledText,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          Checkbox(
            value: selected,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PriceRow
// ─────────────────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final TextTheme tt;

  const _PriceRow({required this.label, required this.value, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        Text('${value.toStringAsFixed(2)} €', style: tt.bodyMedium),
      ],
    );
  }
}
