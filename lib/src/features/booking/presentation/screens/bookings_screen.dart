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
        title: Text('Mes Réservations', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.white,
        elevation: 0,
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
                  Tab(text: 'À venir'),
                  Tab(text: 'Passées'),
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

          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (uid == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Lance l'auto-cancel ghostings et les rappels une seule fois
          Future.microtask(() async {
            await _repo.autoCancelGhostings(uid, isOwner: false);
            await _repo.checkAndSendReminders(uid);
          });

          return StreamBuilder<List<ReservationModel>>(
            stream: _repo.streamReservationsByRenter(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorWidget(message: snapshot.error.toString());
              }

              final all = snapshot.data ?? [];
              final now = DateTime.now();
              final upcoming  = all.where((r) => r.startTime.isAfter(now) && r.status != 'CANCELLED').toList();
              final past      = all.where((r) => r.startTime.isBefore(now) && r.status != 'CANCELLED').toList();
              final cancelled = all.where((r) => r.status == 'CANCELLED').toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _ReservationList(reservations: upcoming,  emptyMessage: 'Aucune réservation à venir',   emptyIcon: Icons.calendar_today_rounded),
                  _ReservationList(reservations: past,      emptyMessage: 'Aucune réservation passée',    emptyIcon: Icons.history_rounded),
                  _ReservationList(reservations: cancelled, emptyMessage: 'Aucune réservation annulée',   emptyIcon: Icons.cancel_outlined),
                ],
              );
            },
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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

    final (statusLabel, statusColor, statusBg, statusIcon) = switch (r.status) {
      'CONFIRMED' => ('Confirmée', const Color(0xFF16A34A), const Color(0xFFDCFCE7), Icons.check_circle_rounded),
      'CANCELLED' => ('Annulée', const Color(0xFFDC2626), const Color(0xFFFEE2E2), Icons.cancel_rounded),
      'COMPLETED' => ('Terminée', const Color(0xFF6366F1), const Color(0xFFEDE9FE), Icons.verified_rounded),
      _ => ('En attente', const Color(0xFFD97706), const Color(0xFFFFF3CD), Icons.hourglass_top_rounded),
    };

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
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── En-tête (Badge & Marque) ─────────
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
                      child: const Icon(Icons.local_laundry_service_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Machine', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        Text(r.machineBrand.toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF0F172A))),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(statusLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          
          // ── Détails Date & Prix ─────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('EEEE d MMM yyyy', 'fr').format(r.startTime),
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            '${DateFormat('HH:mm').format(r.startTime)} - ${DateFormat('HH:mm').format(r.endTime)}',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                          ),
                        ],
                      ),
                      if (r.machineAddress != null && r.machineAddress!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(r.machineAddress!, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: const Color(0xFFF1F5F9),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Column(
                  children: [
                    Text('Total', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${r.totalPrice.toStringAsFixed(2)} €',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20, color: const Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Actions ─────────
          if (!isPast && r.status == 'PENDING') ...[
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: OutlinedButton(
                onPressed: () => _cancel(context, r),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Annuler la réservation', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFFDC2626))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, ReservationModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text('Annulation', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: Text('Voulez-vous vraiment annuler cette réservation ? Cette action est irréversible.', style: GoogleFonts.inter(color: const Color(0xFF475569))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Retour', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.bold))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirmer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: Icon(icon, size: 56, color: const Color(0xFF2563EB)),
      ),
      const SizedBox(height: 24),
      Text(message, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A))),
      const SizedBox(height: 8),
      Text('Découvrez les machines près de chez vous !', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
    ]),
  );
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFECACA))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 40),
            const SizedBox(height: 12),
            Text('Erreur de chargement', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF991B1B))),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFFB91C1C), fontSize: 12)),
          ],
        ),
      ),
    ),
  );
}

