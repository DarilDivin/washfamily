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

  @override
  void initState() {
    super.initState();
    _loadMachines();
  }

  Future<void> _loadMachines() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final repo = FirestoreMachineRepository();
    final machines = await repo.getMachinesByOwner(uid);

    if (mounted) {
      setState(() {
        _machines = machines;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Mes machines", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Naviguer vers l'ajout de machine, puis recharger au retour
          context.push('/profile/add-machine').then((_) => _loadMachines());
        },
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("Ajouter", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
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
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_laundry_service_outlined, size: 64, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 24),
            Text(
              "Aucune machine enregistrée",
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            Text(
              "Vous n'avez pas encore ajouté de machine à laver. Ajoutez votre première machine pour commencer à générer des revenus sur WashFamily.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B), height: 1.5),
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
        padding: const EdgeInsets.all(16),
        itemCount: _machines.length,
        itemBuilder: (context, index) {
          final machine = _machines[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                   Container(
                     width: 64,
                     height: 64,
                     decoration: BoxDecoration(
                       color: const Color(0xFFF1F5F9),
                       borderRadius: BorderRadius.circular(12),
                       image: machine.photoUrls.isNotEmpty
                           ? DecorationImage(image: NetworkImage(machine.photoUrls.first), fit: BoxFit.cover)
                           : null,
                     ),
                     child: machine.photoUrls.isEmpty ? const Icon(Icons.local_laundry_service, color: Color(0xFF94A3B8)) : null,
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           machine.brand,
                           style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           "${machine.capacityKg}kg • ${machine.status.toUpperCase()}",
                           style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           "${machine.pricePerWash} € / cycle",
                           style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                         ),
                       ],
                     ),
                   ),
                   IconButton(
                     icon: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
                     onPressed: () {
                        // TODO: Profil de la machine / Edition
                     },
                   )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
