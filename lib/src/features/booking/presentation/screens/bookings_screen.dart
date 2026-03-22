import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../domain/models/reservation_model.dart';
import '../../data/repositories/firestore_reservation_repository.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = FirestoreReservationRepository();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
        automaticallyImplyLeading: false,
        title: Text('Mes Réservations', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
          tabs: const [
            Tab(text: 'À venir'),
            Tab(text: 'Passées'),
            Tab(text: 'Annulées'),
          ],
        ),
      ),
      body: StreamBuilder<List<ReservationModel>>(
        stream: _uid.isNotEmpty ? _repo.streamReservationsByRenter(_uid) : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorWidget(message: snapshot.error.toString());
          }

          final all = snapshot.data ?? [];
          final now = DateTime.now();
          final upcoming = all.where((r) => r.startTime.isAfter(now) && r.status != 'CANCELLED').toList();
          final past = all.where((r) => r.startTime.isBefore(now) && r.status != 'CANCELLED').toList();
          final cancelled = all.where((r) => r.status == 'CANCELLED').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _ReservationList(reservations: upcoming, emptyMessage: 'Aucune réservation à venir', emptyIcon: Icons.calendar_today_outlined),
              _ReservationList(reservations: past, emptyMessage: 'Aucune réservation passée', emptyIcon: Icons.history_rounded),
              _ReservationList(reservations: cancelled, emptyMessage: 'Aucune réservation annulée', emptyIcon: Icons.cancel_outlined),
            ],
          );
        },
      ),
    );
  }
}

class _ReservationList extends StatelessWidget {
  final List<ReservationModel> reservations;
  final String emptyMessage;
  final IconData emptyIcon;

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
      padding: const EdgeInsets.all(20),
      itemCount: reservations.length,
      itemBuilder: (context, i) => _ReservationCard(reservation: reservations[i]),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final isPast = r.startTime.isBefore(DateTime.now());

    final (statusLabel, statusColor, statusBg) = switch (r.status) {
      'CONFIRMED' => ('Confirmée', const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
      'CANCELLED' => ('Annulée', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
      'COMPLETED' => ('Terminée', const Color(0xFF6366F1), const Color(0xFFEDE9FE)),
      _ => ('En attente', const Color(0xFFD97706), const Color(0xFFFFF3CD)),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // ── Header coloré ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(r.machineBrand, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                child: Text(statusLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: statusColor)),
              ),
            ]),
          ),

          // ── Corps ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE d MMMM yyyy', 'fr').format(r.startTime),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('HH:mm').format(r.startTime)} → ${DateFormat('HH:mm').format(r.endTime)}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                ),
                const Spacer(),
                Text(
                  '${r.totalPrice.toStringAsFixed(2)} €',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF2563EB)),
                ),
              ]),
              if (r.machineAddress != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.machineAddress!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
                ]),
              ],

              // Bouton annuler uniquement sur les réservations à venir PENDING
              if (!isPast && r.status == 'PENDING') ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _cancel(context, r),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Annuler', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFDC2626))),
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, ReservationModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Annuler la réservation', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Voulez-vous vraiment annuler cette réservation ?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirestoreReservationRepository().cancelReservation(r.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEFF6FF)),
        child: Icon(icon, size: 48, color: const Color(0xFF2563EB)),
      ),
      const SizedBox(height: 16),
      Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A))),
      const SizedBox(height: 8),
      Text('Découvrez les machines près de chez vous !',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
    ]),
  );
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24),
      child: Text('Une erreur est survenue.\n$message', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.red))),
  );
}
