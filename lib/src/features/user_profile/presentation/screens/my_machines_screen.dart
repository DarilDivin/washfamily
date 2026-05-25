import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:washfamily/src/features/machines_map/domain/models/machine_model.dart';
import 'package:washfamily/src/features/machines_map/data/repositories/firestore_machine_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class MyMachinesScreen extends StatefulWidget {
  const MyMachinesScreen({super.key});

  @override
  State<MyMachinesScreen> createState() => _MyMachinesScreenState();
}

class _MyMachinesScreenState extends State<MyMachinesScreen> {
  bool _isLoading = true;
  List<MachineModel> _machines = [];
  final _repo = FirestoreMachineRepository();

  @override
  void initState() {
    super.initState();
    _loadMachines();
  }

  Future<void> _loadMachines() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }
    final machines = await _repo.getMachinesByOwner(uid);
    if (mounted) {
      setState(() {
        _machines = machines;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMachine(MachineModel machine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        title: Text('Supprimer cette machine ?'),
        content: Text(
            'La machine "${machine.brand}" sera retirée définitivement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repo.deleteMachine(machine.id);
      _loadMachines();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Mes machines', style: tt.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/profile/add-machine').then((_) => _loadMachines()),
        elevation: 0,
        backgroundColor: AppColors.primary,
        icon: const PhosphorIcon(PhosphorIconsRegular.plus,
            color: AppColors.surface, size: 20),
        label: Text('Ajouter',
            style: tt.labelLarge?.copyWith(color: AppColors.surface)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _machines.isEmpty
              ? _buildEmptyState(tt)
              : _buildMachinesList(),
    );
  }

  Widget _buildEmptyState(TextTheme tt) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.completedBg,
                shape: BoxShape.circle,
              ),
              child: const PhosphorIcon(
                PhosphorIconsRegular.washingMachine,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Aucune machine enregistrée',
              textAlign: TextAlign.center,
              style: tt.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ajoutez votre première machine pour générer des revenus avec WashFamily.',
              textAlign: TextAlign.center,
              style: tt.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachinesList() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadMachines,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
        itemCount: _machines.length,
        itemBuilder: (context, index) {
          final machine = _machines[index];
          return _MachineCard(
            machine: machine,
            onDelete: () => _deleteMachine(machine),
            onEdit: () => context
                .push('/profile/edit-machine', extra: machine)
                .then((_) => _loadMachines()),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MachineCard
// ─────────────────────────────────────────────────────────────────────────────

class _MachineCard extends StatelessWidget {
  final MachineModel machine;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _MachineCard({
    required this.machine,
    required this.onDelete,
    required this.onEdit,
  });

  (String label, Color color, Color bg, PhosphorIconData icon) get _status =>
      switch (machine.status) {
        'AVAILABLE' => (
            'Disponible',
            AppColors.confirmedText,
            AppColors.confirmedBg,
            PhosphorIconsFill.checkCircle,
          ),
        'IN_USE' => (
            'En service',
            AppColors.pendingText,
            AppColors.pendingBg,
            PhosphorIconsRegular.clock,
          ),
        'MAINTENANCE' => (
            'Maintenance',
            AppColors.textSecondary,
            AppColors.inputBackground,
            PhosphorIconsRegular.wrench,
          ),
        _ => (
            'Inconnu',
            AppColors.textSecondary,
            AppColors.inputBackground,
            PhosphorIconsRegular.question,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final (statusLabel, statusColor, statusBg, statusIcon) = _status;

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
          // ── En-tête : icône + marque + badge statut ──
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
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Marque',
                          style: tt.labelSmall?.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5)),
                      Text(
                        machine.brand.toUpperCase(),
                        style: tt.titleSmall
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                // Badge statut
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

          // ── Infos : capacité, adresse, prix ──
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        icon: PhosphorIconsRegular.drop,
                        text: '${machine.capacityKg} kg • ${machine.brand}',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: PhosphorIconsRegular.mapPin,
                        text: machine.address ?? 'Adresse non définie',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${machine.pricePerWash.toStringAsFixed(2)} €',
                      style: tt.titleLarge
                          ?.copyWith(color: AppColors.primary),
                    ),
                    Text('/ lavage',
                        style: tt.bodySmall),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border),

          // ── Actions ──
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const PhosphorIcon(
                        PhosphorIconsRegular.pencilSimple,
                        size: 15),
                    label: const Text('Modifier'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const PhosphorIcon(PhosphorIconsRegular.trash,
                      size: 15),
                  label: const Text('Supprimer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                        horizontal: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final PhosphorIconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PhosphorIcon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall,
          ),
        ),
      ],
    );
  }
}
