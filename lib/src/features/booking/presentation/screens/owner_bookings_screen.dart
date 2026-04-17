import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../domain/models/reservation_model.dart';
import '../../data/repositories/firestore_reservation_repository.dart';

/// Tableau de bord du propriétaire : liste des demandes de réservation
/// reçues sur ses machines, avec actions Confirmer / Refuser.
class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = FirestoreReservationRepository();

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Demandes reçues', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                labelColor: const Color(0xFF0F172A),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'En attente'),
                  Tab(text: 'Confirmées'),
                  Tab(text: 'Historique'),
                ],
              ),
            ),
          ),
        ),
      ),
      // StreamBuilder sur authStateChanges pour garantir que l'UID
      // est disponible même si la session Firebase ne s'est pas encore restaurée
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          final uid = authSnapshot.data?.uid;

          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (uid == null) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 16),
                Text('Vous devez être connecté.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
              ]),
            );
          }

          // Lance l'auto-cancel ghostings une seule fois (via Future, pas de setState)
          Future.microtask(() => _repo.autoCancelGhostings(uid, isOwner: true));

          return StreamBuilder<List<ReservationModel>>(
            stream: _repo.streamReservationsByOwner(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Gestion des erreurs Firestore (index manquant, rules, etc.)
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
                      const SizedBox(height: 16),
                      Text('Erreur de chargement',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      ),
                    ]),
                  ),
                );
              }

              final all = snapshot.data ?? [];
              final pending   = all.where((r) => r.status == 'PENDING').toList();
              final confirmed = all.where((r) => r.status == 'CONFIRMED').toList();
              final history   = all.where((r) => r.status == 'CANCELLED' || r.status == 'COMPLETED').toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _OwnerList(reservations: pending,   emptyMessage: 'Aucune demande en attente',   showActions: true,  repo: _repo),
                  _OwnerList(reservations: confirmed, emptyMessage: 'Aucune réservation confirmée', showActions: false, repo: _repo),
                  _OwnerList(reservations: history,   emptyMessage: 'Aucun historique',            showActions: false, repo: _repo),
                ],
              );
            },
          );
        },
      ),
    );
  }

}

class _OwnerList extends StatelessWidget {
  final List<ReservationModel> reservations;
  final String emptyMessage;
  final bool showActions;
  final FirestoreReservationRepository repo;

  const _OwnerList({
    required this.reservations,
    required this.emptyMessage,
    required this.showActions,
    required this.repo,
  });

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEFF6FF)),
          child: const Icon(Icons.inbox_outlined, size: 44, color: Color(0xFF2563EB)),
        ),
        const SizedBox(height: 16),
        Text(emptyMessage, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A))),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: reservations.length,
      itemBuilder: (context, i) => _OwnerReservationCard(
        reservation: reservations[i],
        showActions: showActions,
        repo: repo,
      ),
    );
  }
}

class _OwnerReservationCard extends StatefulWidget {
  final ReservationModel reservation;
  final bool showActions;
  final FirestoreReservationRepository repo;

  const _OwnerReservationCard({required this.reservation, required this.showActions, required this.repo});

  @override
  State<_OwnerReservationCard> createState() => _OwnerReservationCardState();
}

class _OwnerReservationCardState extends State<_OwnerReservationCard> {
  bool _loading = false;

  Future<void> _updateStatus(String status) async {
    String? reason;

    if (status == 'CANCELLED') {
      reason = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final controller = TextEditingController();
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
              const SizedBox(width: 8),
              Text('Refuser la demande', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Indiquez une raison (optionnel) :', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ex : Machine en maintenance ce jour-là…',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626))),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Annuler', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: Text('Confirmer le refus', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
      if (reason == null) return; // dialog annulé
    }

    setState(() => _loading = true);
    await widget.repo.updateStatus(widget.reservation.id, status, cancelReason: reason);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;

    final (statusLabel, statusColor, statusBg) = switch (r.status) {
      'CONFIRMED' => ('Confirmée', const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
      'CANCELLED' => ('Refusée', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
      _ => ('En attente', const Color(0xFFD97706), const Color(0xFFFFF3CD)),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Machine + status
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(r.machineBrand, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
              child: Text(statusLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: statusColor)),
            ),
          ]),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Locataire (UID tronqué, à remplacer par firstName si disponible)
          Row(children: [
            const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Text('Locataire : ', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
            Text(r.renterId.length > 12 ? '${r.renterId.substring(0, 12)}…' : r.renterId,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),

          // Date
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Text(DateFormat('EEE d MMM yyyy', 'fr').format(r.startTime),
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
            const SizedBox(width: 12),
            const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text('${DateFormat('HH:mm').format(r.startTime)} → ${DateFormat('HH:mm').format(r.endTime)}',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
            const Spacer(),
            Text('${r.totalPrice.toStringAsFixed(2)} €',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF2563EB))),
          ]),

          if (r.renterNote != null && r.renterNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(child: Text(r.renterNote!, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151), fontStyle: FontStyle.italic))),
              ]),
            ),
          ],

          // Actions
          if (widget.showActions) ...[
            const SizedBox(height: 14),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateStatus('CANCELLED'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFDC2626)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Refuser', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFDC2626))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _updateStatus('CONFIRMED'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Confirmer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
          ],
        ]),
      ),
    );
  }
}
