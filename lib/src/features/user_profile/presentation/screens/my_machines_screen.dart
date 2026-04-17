import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:washfamily/src/features/machines_map/domain/models/machine_model.dart';
import 'package:washfamily/src/features/machines_map/data/repositories/firestore_machine_repository.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Supprimer cette machine ?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(
          'La machine "${machine.brand}" sera retirée définitivement.',
          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Supprimer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Mes machines',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/profile/add-machine').then((_) => _loadMachines()),
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Ajouter',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _machines.isEmpty
              ? _buildEmptyState()
              : _buildMachinesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_laundry_service_outlined,
                  size: 56, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune machine enregistrée',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            Text(
              'Ajoutez votre première machine pour générer des revenus avec WashFamily.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B), height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachinesList() {
    return RefreshIndicator(
      onRefresh: _loadMachines,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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

// ─────────────────────────────────────────────
// Card — suit le design system de BookingsScreen
// ─────────────────────────────────────────────

class _MachineCard extends StatelessWidget {
  final MachineModel machine;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _MachineCard({
    required this.machine,
    required this.onDelete,
    required this.onEdit,
  });

  (String label, Color color, Color bg, IconData icon) get _status => switch (machine.status) {
        'AVAILABLE'   => ('Disponible', const Color(0xFF16A34A), const Color(0xFFDCFCE7), Icons.check_circle_rounded),
        'IN_USE'      => ('En service', const Color(0xFFD97706), const Color(0xFFFFF3CD), Icons.access_time_rounded),
        'MAINTENANCE' => ('Maintenance', const Color(0xFF64748B), const Color(0xFFF1F5F9), Icons.build_outlined),
        _             => ('Inconnu',     const Color(0xFF94A3B8), const Color(0xFFF8FAFC), Icons.help_outline_rounded),
      };

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor, statusBg, statusIcon) = _status;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── En-tête : icône + marque + badge statut ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_laundry_service_rounded,
                          color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Marque',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                        Text(machine.brand.toUpperCase(),
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: const Color(0xFF0F172A))),
                      ],
                    ),
                  ],
                ),
                // Badge statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration:
                      BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // ── Infos : capacité, adresse, prix ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        icon: Icons.water_drop_outlined,
                        text: '${machine.capacityKg} kg • ${machine.brand}',
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: machine.address ?? 'Adresse non définie',
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${machine.pricePerWash.toStringAsFixed(2)} €',
                      style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB)),
                    ),
                    Text('/ heure',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: const Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // ── Actions ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text('Modifier',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFBFDBFE))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: Text('Supprimer',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFFECACA))),
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
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}
