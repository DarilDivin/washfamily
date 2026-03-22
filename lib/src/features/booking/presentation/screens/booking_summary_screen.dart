import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../domain/models/reservation_model.dart';
import '../../data/repositories/firestore_reservation_repository.dart';
import '../../../machines_map/domain/models/machine_model.dart';

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
  final _noteCtrl = TextEditingController();
  bool _isLoading = false;

  static const _primaryColor = Color(0xFF2563EB);

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour réserver.')),
      );
      return;
    }

    // Vérification de disponibilité (avant de créer)
    setState(() => _isLoading = true);
    final isAvailable = await _repo.checkAvailability(
      machineId: widget.machine.id,
      start: widget.startTime,
      end: widget.endTime,
    );

    if (!isAvailable) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Ce créneau vient d\'être réservé. Choisissez-en un autre.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final reservation = ReservationModel(
        id: '',
        machineId: widget.machine.id,
        machineBrand: widget.machine.brand,
        machineAddress: widget.machine.address,
        ownerId: widget.machine.ownerId,
        renterId: user.uid,
        startTime: widget.startTime,
        endTime: widget.endTime,
        totalPrice: widget.price,
        status: 'PENDING',
        renterNote: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
      );

      await _repo.createReservation(reservation);

      if (mounted) {
        setState(() => _isLoading = false);
        context.pushReplacement('/bookings/success', extra: reservation.copyWith());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.endTime.difference(widget.startTime);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Récapitulatif', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Étapes visuelles ──────────────────────────────────────
          _StepIndicator(currentStep: 1),
          const SizedBox(height: 24),

          // ── Carte Machine ─────────────────────────────────────────
          _InfoCard(
            title: 'MACHINE',
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.machine.brand, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                if (widget.machine.address != null)
                  Text(widget.machine.address!, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12)),
                Row(children: [
                  const Icon(Icons.water_drop_outlined, size: 12, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text('${widget.machine.capacityKg} kg', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                ]),
              ])),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Carte Créneau ─────────────────────────────────────────
          _InfoCard(
            title: 'CRÉNEAU',
            child: Column(children: [
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: DateFormat('EEEE d MMMM yyyy', 'fr').format(widget.startTime),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.access_time_rounded,
                label: 'Horaire',
                value: '${DateFormat('HH:mm').format(widget.startTime)} → ${DateFormat('HH:mm').format(widget.endTime)}',
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.timelapse_rounded,
                label: 'Durée',
                value: '${duration.inHours}h${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}',
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Carte Prix ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(children: [
              const Icon(Icons.euro_rounded, color: _primaryColor, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Prix total', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _primaryColor))),
              Text(
                '${widget.price.toStringAsFixed(2)} €',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: _primaryColor),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Note pour le propriétaire ─────────────────────────────
          Text('Note pour le propriétaire (optionnel)',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: TextField(
              controller: _noteCtrl,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Ex : J\'arriverai à 10h pile, code de la porte ?',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),

      // ── CTA Confirmer ─────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _isLoading ? null : _confirm,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.check_rounded),
                    const SizedBox(width: 8),
                    Text('Confirmer la réservation',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
          ),
        ),
      ),
    );
  }
}

// ── Sous-widgets ──────────────────────────────────────────

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
  const _Step({required this.n, required this.label, this.active = false, this.done = false});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: (active || done) ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text('$n', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: (active || done) ? Colors.white : const Color(0xFF94A3B8))),
      ),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: (active || done) ? const Color(0xFF2563EB) : const Color(0xFF94A3B8))),
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
      color: active ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.5)),
      const SizedBox(height: 12),
      child,
    ]),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
    ),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
      Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF0F172A))),
    ])),
  ]);
}
