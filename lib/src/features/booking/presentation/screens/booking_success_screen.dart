import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/models/reservation_model.dart';

/// Étape 3 du tunnel : Confirmation avec animation de succès.
class BookingSuccessScreen extends StatefulWidget {
  final ReservationModel reservation;

  const BookingSuccessScreen({super.key, required this.reservation});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // ── Animation checkmark ──────────────────────────────
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, size: 60, color: Colors.white),
                ),
              ),

              const SizedBox(height: 28),

              FadeTransition(
                opacity: _fadeAnim,
                child: Column(children: [
                  Text(
                    'Demande envoyée !',
                    style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Le propriétaire a reçu votre demande. Vous serez notifié dès confirmation.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B), height: 1.5),
                  ),
                ]),
              ),

              const SizedBox(height: 32),

              // ── Récapitulatif réservation ────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16)],
                  ),
                  child: Column(
                    children: [
                      _SuccessRow(icon: Icons.local_laundry_service_rounded, label: 'Machine', value: r.machineBrand),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      _SuccessRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: DateFormat('EEE d MMM yyyy', 'fr').format(r.startTime),
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      _SuccessRow(
                        icon: Icons.access_time_rounded,
                        label: 'Créneau',
                        value: '${DateFormat('HH:mm').format(r.startTime)} → ${DateFormat('HH:mm').format(r.endTime)}',
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      _SuccessRow(
                        icon: Icons.pending_rounded,
                        label: 'Statut',
                        value: 'En attente',
                        valueColor: const Color(0xFFD97706),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // ── Actions ──────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(children: [
                  FilledButton(
                    onPressed: () => context.go('/reservations'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: Text('Voir mes réservations',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: Text('Retour à l\'accueil',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SuccessRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
    const SizedBox(width: 10),
    Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
    const Spacer(),
    Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: valueColor ?? const Color(0xFF0F172A))),
  ]);
}
