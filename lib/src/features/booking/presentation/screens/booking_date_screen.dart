import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/firestore_reservation_repository.dart';
import '../../../machines_map/domain/models/machine_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:washfamily/src/features/authentication/data/repositories/user_repository.dart';
import 'package:washfamily/src/features/authentication/domain/models/user_model.dart';
import 'package:washfamily/src/features/subscriptions/data/subscription_repository.dart';

/// Étape 1 du tunnel de réservation.
/// L'utilisateur choisit une date puis un créneau horaire disponible.
class BookingDateScreen extends StatefulWidget {
  final MachineModel machine;

  const BookingDateScreen({super.key, required this.machine});

  @override
  State<BookingDateScreen> createState() => _BookingDateScreenState();
}

class _BookingDateScreenState extends State<BookingDateScreen> {
  final _repo = FirestoreReservationRepository();

  DateTime _selectedDay = DateTime.now();
  int? _selectedHour; // Heure du début (ex: 10 = 10h00)
  int _selectedDuration = 1; // Durée en heures (max 4)
  List<DateTime> _bookedSlots = [];
  bool _loadingSlots = false;

  static const _primaryColor = Color(0xFF2563EB);

  List<int> get _hours {
    if (!widget.machine.availableDays.contains(_selectedDay.weekday)) return [];
    final length = widget.machine.endTimeHour - widget.machine.startTimeHour;
    if (length <= 0) return [];
    return List.generate(length, (i) => widget.machine.startTimeHour + i);
  }

  UserModel? _currentUser;
  bool _loadingUser = true;

  bool get _subscriptionExpired {
    if (_currentUser == null || _currentUser!.isAdmin || _currentUser!.isOwner) return false;
    final end = _currentUser!.subscriptionEndDate;
    return end != null && end.isBefore(DateTime.now());
  }

  bool get _quotaExceeded {
    if (_currentUser == null || _currentUser!.isAdmin || _currentUser!.isOwner) return false;
    return _currentUser!.remainingReservations <= 0;
  }

  bool get _isBlocked => _subscriptionExpired || _quotaExceeded;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadSlots(_selectedDay);
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await SubscriptionRepository().checkAndResetIfExpired(uid);
      final user = await UserRepository().getUser(uid);
      if (mounted) setState(() { _currentUser = user; _loadingUser = false; });
    } else {
      if (mounted) setState(() { _loadingUser = false; });
    }
  }

  Future<void> _loadSlots(DateTime date) async {
    setState(() => _loadingSlots = true);
    final booked = await _repo.getBookedSlots(widget.machine.id, date);
    setState(() {
      _bookedSlots = booked;
      _selectedHour = null;
      _loadingSlots = false;
    });
  }

  bool _isBooked(int hour) {
    return _bookedSlots.any((dt) => dt.hour == hour);
  }

  bool _isPast(int hour) {
    final now = DateTime.now();
    final slotDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, hour);
    return slotDate.isBefore(now);
  }

  bool _canBookDuration(int startHour, int duration) {
    for (int i = 0; i < duration; i++) {
       final h = startHour + i;
       if (_isBooked(h) || _isPast(h)) return false;
       if (!_hours.contains(h)) return false; // Ne pas dépasser la grille dispo
    }
    return true;
  }

  void _setDuration(int dur) {
    setState(() {
      _selectedDuration = dur;
      if (_selectedHour != null && !_canBookDuration(_selectedHour!, dur)) {
        _selectedHour = null;
      }
    });
  }

  void _onDaySelected(DateTime day) {
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) return;
    setState(() => _selectedDay = day);
    _loadSlots(day);
  }

  void _confirm() {
    if (_selectedHour == null) return;
    final start = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, _selectedHour!);
    final end = start.add(Duration(hours: _selectedDuration));
    final price = widget.machine.pricePerWash * _selectedDuration;

    context.push('/bookings/summary', extra: {
      'machine': widget.machine,
      'startTime': start,
      'endTime': end,
      'price': price,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Réserver', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // ── Bandeau machine ─────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.machine.brand, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(widget.machine.address ?? 'Adresse non précisée',
                        style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '${widget.machine.pricePerWash.toStringAsFixed(2)} €/h',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: _primaryColor, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          if (_loadingUser)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_currentUser != null && _isBlocked)
            Expanded(child: _BlockedView(
              isExpired: _subscriptionExpired,
              expiryDate: _currentUser!.subscriptionEndDate,
            ))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Sélecteur de mois ──────────────────────────────────
                  _SectionLabel('Choisissez une date'),
                const SizedBox(height: 12),
                _CalendarWidget(
                  selectedDay: _selectedDay,
                  onDaySelected: _onDaySelected,
                  availableDays: widget.machine.availableDays,
                ),
                const SizedBox(height: 24),

                Row(children: [
                  _SectionLabel('Choisissez une durée'),
                ]),
                const SizedBox(height: 12),
                Row(
                  children: [1, 2, 3, 4].map((dur) {
                    final selected = _selectedDuration == dur;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _setDuration(dur),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? _primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selected ? _primaryColor : const Color(0xFFE2E8F0)),
                            boxShadow: selected ? [BoxShadow(color: _primaryColor.withValues(alpha: 0.3), blurRadius: 8)] : null,
                          ),
                          child: Text('$dur h', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: selected ? Colors.white : const Color(0xFF374151))),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  _SectionLabel('Choisissez un créneau (${_selectedDuration}h)'),
                  const SizedBox(width: 8),
                  if (_loadingSlots)
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                ]),
                const SizedBox(height: 12),
                if (_hours.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    child: Center(
                      child: Text('Aucun créneau disponible ce jour',
                          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
                    ),
                  )
                else
                  GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _hours.length,
                  itemBuilder: (context, i) {
                    final hour = _hours[i];
                    final disabled = !_canBookDuration(hour, _selectedDuration);
                    final isSelectedSpan = _selectedHour != null && hour >= _selectedHour! && hour < _selectedHour! + _selectedDuration;
                    final isStart = _selectedHour == hour;

                    return GestureDetector(
                      onTap: disabled ? null : () => setState(() => _selectedHour = hour),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelectedSpan
                              ? _primaryColor.withValues(alpha: isStart ? 1 : 0.7)
                              : disabled
                                  ? const Color(0xFFF1F5F9)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelectedSpan
                                ? _primaryColor
                                : disabled
                                    ? const Color(0xFFE2E8F0)
                                    : const Color(0xFFCBD5E1),
                          ),
                          boxShadow: isStart
                              ? [BoxShadow(color: _primaryColor.withValues(alpha: 0.3), blurRadius: 8)]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}h00',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelectedSpan
                                ? Colors.white
                                : disabled
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF374151),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Légende
                Row(children: [
                  _LegendDot(color: Colors.white, border: const Color(0xFFCBD5E1)),
                  const SizedBox(width: 6),
                  Text('Disponible', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                  const SizedBox(width: 16),
                  _LegendDot(color: _primaryColor),
                  const SizedBox(width: 6),
                  Text('Sélectionné', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                  const SizedBox(width: 16),
                  _LegendDot(color: const Color(0xFFF1F5F9), border: const Color(0xFFE2E8F0)),
                  const SizedBox(width: 6),
                  Text('Indisponible', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                ]),
              ],
            ),
          ),
        ],
      ),

      // ── CTA Continuer ───────────────────────────────────────────────
      bottomNavigationBar: _loadingUser || (_currentUser != null && _isBlocked) ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Récapitulatif créneau sélectionné
              if (_selectedHour != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.access_time_rounded, color: _primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('EEE d MMM', 'fr').format(_selectedDay)}'
                      ' · ${_selectedHour!.toString().padLeft(2, '0')}h00 → ${(_selectedHour! + _selectedDuration).toString().padLeft(2, '0')}h00\n'
                      'Total: ${(widget.machine.pricePerWash * _selectedDuration).toStringAsFixed(2)} €',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _primaryColor, fontSize: 13),
                    ),
                  ]),
                ),
              FilledButton(
                onPressed: _selectedHour != null ? _confirm : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: _primaryColor,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: Text(
                  _selectedHour == null ? 'Choisissez un créneau' : 'Continuer',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Sous-widgets
// ─────────────────────────────────────────────────────────

class _BlockedView extends StatelessWidget {
  final bool isExpired;
  final DateTime? expiryDate;
  const _BlockedView({required this.isExpired, this.expiryDate});

  static const _primaryColor = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final icon    = isExpired ? Icons.timer_off_outlined : Icons.block_outlined;
    final color   = isExpired ? const Color(0xFFF97316) : const Color(0xFFDC2626);
    final title   = isExpired ? 'Abonnement expiré' : 'Limite atteinte';
    final subtitle = isExpired
        ? 'Votre abonnement a expiré le ${_fmt(expiryDate)}.\nRenouvelez-le pour continuer à réserver.'
        : "Vous n'avez plus de réservations disponibles ce mois-ci.";
    final cta = isExpired ? 'Renouveler mon abonnement' : 'Voir les abonnements';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 52, color: color),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A))),
            const SizedBox(height: 10),
            Text(subtitle,
                style: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFF64748B), height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => context.push('/subscriptions'),
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(cta,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A)),
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final Color? border;
  const _LegendDot({required this.color, this.border});

  @override
  Widget build(BuildContext context) => Container(
        width: 14, height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: border != null ? Border.all(color: border!) : null,
        ),
      );
}

/// Mini-calendrier personnalisé (mois courant + suivant)
class _CalendarWidget extends StatefulWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final List<int> availableDays;

  const _CalendarWidget({
    required this.selectedDay,
    required this.onDaySelected,
    required this.availableDays,
  });

  @override
  State<_CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<_CalendarWidget> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.selectedDay.year, widget.selectedDay.month);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayOffset = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          // Navigation mois
          Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => setState(() {
                _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
              }),
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy', 'fr').format(_focusedMonth),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => setState(() {
                _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
              }),
            ),
          ]),

          // Jours de la semaine
          Row(
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((d) => Expanded(
              child: Text(d, textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
            )).toList(),
          ),
          const SizedBox(height: 8),

          // Grille des jours
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.1),
            itemCount: firstDayOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) return const SizedBox();
              final day = index - firstDayOffset + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final isSelected = DateUtils.isSameDay(date, widget.selectedDay);
              final isToday = DateUtils.isSameDay(date, today);
              final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
              final isAvailableDay = widget.availableDays.contains(date.weekday);
              final isDisabled = isPast || !isAvailableDay;

              return GestureDetector(
                onTap: isDisabled ? null : () => widget.onDaySelected(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected ? Border.all(color: const Color(0xFF2563EB)) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    day.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isDisabled
                              ? const Color(0xFFCBD5E1) // Gris clair si bloqué ou passé
                              : const Color(0xFF374151),
                      decoration: (!isAvailableDay && !isPast) ? TextDecoration.lineThrough : null, // Barré si jour fermé
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
