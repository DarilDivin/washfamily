import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/repositories/firestore_reservation_repository.dart';
import '../../../machines_map/domain/models/machine_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:washfamily/src/features/authentication/data/repositories/user_repository.dart';
import 'package:washfamily/src/features/authentication/domain/models/user_model.dart';
import 'package:washfamily/src/features/subscriptions/data/subscription_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

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
  int? _selectedHour;
  int _selectedDuration = 1;
  List<DateTime> _bookedSlots = [];
  bool _loadingSlots = false;

  List<int> get _hours {
    if (!widget.machine.availableDays.contains(_selectedDay.weekday)) {
      return [];
    }
    final length =
        widget.machine.endTimeHour - widget.machine.startTimeHour;
    if (length <= 0) return [];
    return List.generate(
        length, (i) => widget.machine.startTimeHour + i);
  }

  UserModel? _currentUser;
  bool _loadingUser = true;

  bool get _subscriptionExpired {
    if (_currentUser == null ||
        _currentUser!.isAdmin ||
        _currentUser!.isOwner) { return false; }
    final end = _currentUser!.subscriptionEndDate;
    return end != null && end.isBefore(DateTime.now());
  }

  bool get _quotaExceeded {
    if (_currentUser == null ||
        _currentUser!.isAdmin ||
        _currentUser!.isOwner) { return false; }
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
      if (mounted) {
        setState(() {
          _currentUser = user;
          _loadingUser = false;
        });
      }
    } else {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _loadSlots(DateTime date) async {
    setState(() => _loadingSlots = true);
    final booked =
        await _repo.getBookedSlots(
            laundryId: widget.machine.laundryId,
            machineId: widget.machine.id,
            date: date);
    setState(() {
      _bookedSlots = booked;
      _selectedHour = null;
      _loadingSlots = false;
    });
  }

  bool _isBooked(int hour) =>
      _bookedSlots.any((dt) => dt.hour == hour);

  bool _isPast(int hour) {
    final now = DateTime.now();
    final slotDate = DateTime(_selectedDay.year, _selectedDay.month,
        _selectedDay.day, hour);
    return slotDate.isBefore(now);
  }

  bool _canBookDuration(int startHour, int duration) {
    for (int i = 0; i < duration; i++) {
      final h = startHour + i;
      if (_isBooked(h) || _isPast(h)) return false;
      if (!_hours.contains(h)) return false;
    }
    return true;
  }

  void _setDuration(int dur) {
    setState(() {
      _selectedDuration = dur;
      if (_selectedHour != null &&
          !_canBookDuration(_selectedHour!, dur)) {
        _selectedHour = null;
      }
    });
  }

  void _onDaySelected(DateTime day) {
    if (day.isBefore(
        DateTime.now().subtract(const Duration(days: 1)))) { return; }
    setState(() => _selectedDay = day);
    _loadSlots(day);
  }

  void _confirm() {
    if (_selectedHour == null) return;
    final start = DateTime(_selectedDay.year, _selectedDay.month,
        _selectedDay.day, _selectedHour!);
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
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Réserver', style: tt.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // ── Bandeau machine ─────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.completedBg,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const PhosphorIcon(
                      PhosphorIconsRegular.washingMachine,
                      color: AppColors.primary,
                      size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(widget.machine.brand, style: tt.titleSmall),
                    Text(
                        widget.machine.address ?? 'Adresse non précisée',
                        style: tt.bodySmall,
                        overflow: TextOverflow.ellipsis),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                      color: AppColors.completedBg,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd)),
                  child: Text(
                    '${widget.machine.pricePerWash.toStringAsFixed(2)} €/h',
                    style: tt.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          if (_loadingUser)
            const Expanded(
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)))
          else if (_currentUser != null && _isBlocked)
            Expanded(
                child: _BlockedView(
              isExpired: _subscriptionExpired,
              expiryDate: _currentUser!.subscriptionEndDate,
            ))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // ── Date ─────────────────────────────────────────────
                  _SectionLabel('Choisissez une date'),
                  const SizedBox(height: AppSpacing.md),
                  _CalendarWidget(
                    selectedDay: _selectedDay,
                    onDaySelected: _onDaySelected,
                    availableDays: widget.machine.availableDays,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Durée ─────────────────────────────────────────────
                  _SectionLabel('Choisissez une durée'),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [1, 2, 3, 4].map((dur) {
                      final selected = _selectedDuration == dur;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _setDuration(dur),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(
                                right: AppSpacing.sm),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd),
                              border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border),
                            ),
                            child: Text('$dur h',
                                style: tt.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? AppColors.surface
                                        : AppColors.textBody)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Créneaux ──────────────────────────────────────────
                  Row(children: [
                    _SectionLabel(
                        'Choisissez un créneau (${_selectedDuration}h)'),
                    const SizedBox(width: AppSpacing.sm),
                    if (_loadingSlots)
                      const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary)),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  if (_hours.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                            'Aucun créneau disponible ce jour',
                            style: tt.bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic)),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1.8,
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                      ),
                      itemCount: _hours.length,
                      itemBuilder: (context, i) {
                        final hour = _hours[i];
                        final disabled =
                            !_canBookDuration(hour, _selectedDuration);
                        final isSelectedSpan = _selectedHour != null &&
                            hour >= _selectedHour! &&
                            hour < _selectedHour! + _selectedDuration;
                        final isStart = _selectedHour == hour;

                        return GestureDetector(
                          onTap: disabled
                              ? null
                              : () => setState(
                                  () => _selectedHour = hour),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelectedSpan
                                  ? AppColors.primary.withValues(
                                      alpha: isStart ? 1.0 : 0.7)
                                  : disabled
                                      ? AppColors.inputBackground
                                      : AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd),
                              border: Border.all(
                                color: isSelectedSpan
                                    ? AppColors.primary
                                    : disabled
                                        ? AppColors.border
                                        : AppColors.border,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}h00',
                              style: tt.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelectedSpan
                                    ? AppColors.surface
                                    : disabled
                                        ? AppColors.border
                                        : AppColors.textBody,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Légende ───────────────────────────────────────────
                  Row(children: [
                    _LegendDot(
                        color: AppColors.surface,
                        border: AppColors.border),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Disponible', style: tt.bodySmall),
                    const SizedBox(width: AppSpacing.lg),
                    const _LegendDot(color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Sélectionné', style: tt.bodySmall),
                    const SizedBox(width: AppSpacing.lg),
                    _LegendDot(
                        color: AppColors.inputBackground,
                        border: AppColors.border),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Indisponible', style: tt.bodySmall),
                  ]),
                ],
              ),
            ),
        ],
      ),

      // ── CTA Continuer ──────────────────────────────────────────────
      bottomNavigationBar:
          _loadingUser || (_currentUser != null && _isBlocked)
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedHour != null)
                          Container(
                            margin: const EdgeInsets.only(
                                bottom: AppSpacing.md),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.completedBg,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd),
                            ),
                            child: Row(children: [
                              const PhosphorIcon(
                                  PhosphorIconsRegular.clock,
                                  color: AppColors.primary,
                                  size: 15),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  '${DateFormat('EEE d MMM', 'fr').format(_selectedDay)}'
                                  ' · ${_selectedHour!.toString().padLeft(2, '0')}h00 → ${(_selectedHour! + _selectedDuration).toString().padLeft(2, '0')}h00\n'
                                  'Total: ${(widget.machine.pricePerWash * _selectedDuration).toStringAsFixed(2)} €',
                                  style: tt.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary),
                                ),
                              ),
                            ]),
                          ),
                        FilledButton(
                          onPressed:
                              _selectedHour != null ? _confirm : null,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg),
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.border,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd)),
                            minimumSize: const Size(double.infinity, 0),
                          ),
                          child: Text(
                            _selectedHour == null
                                ? 'Choisissez un créneau'
                                : 'Continuer',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BlockedView
// ─────────────────────────────────────────────────────────────────────────────

class _BlockedView extends StatelessWidget {
  final bool isExpired;
  final DateTime? expiryDate;
  const _BlockedView({required this.isExpired, this.expiryDate});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final icon = isExpired
        ? PhosphorIconsRegular.clockCountdown
        : PhosphorIconsRegular.prohibit;
    final color = isExpired ? AppColors.warning : AppColors.error;
    final title =
        isExpired ? 'Abonnement expiré' : 'Limite atteinte';
    final subtitle = isExpired
        ? 'Votre abonnement a expiré le ${_fmt(expiryDate)}.\nRenouvelez-le pour continuer à réserver.'
        : "Vous n'avez plus de réservations disponibles ce mois-ci.";
    final cta =
        isExpired ? 'Renouveler mon abonnement' : 'Voir les abonnements';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(icon, size: 52, color: color),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: tt.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle,
                style: tt.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: () => context.push('/subscriptions'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd)),
              ),
              child: Text(cta),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sous-widgets légers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final Color? border;
  const _LegendDot({required this.color, this.border});

  @override
  Widget build(BuildContext context) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border:
              border != null ? Border.all(color: border!) : null,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _CalendarWidget
// ─────────────────────────────────────────────────────────────────────────────

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
    _focusedMonth = DateTime(
        widget.selectedDay.year, widget.selectedDay.month);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final daysInMonth = DateUtils.getDaysInMonth(
        _focusedMonth.year, _focusedMonth.month);
    final firstDayOffset =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1)
                .weekday -
            1;
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Navigation mois
          Row(children: [
            IconButton(
              icon: const PhosphorIcon(
                  PhosphorIconsRegular.caretLeft,
                  size: 18,
                  color: AppColors.textPrimary),
              onPressed: () => setState(() {
                _focusedMonth = DateTime(
                    _focusedMonth.year, _focusedMonth.month - 1);
              }),
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy', 'fr').format(_focusedMonth),
                textAlign: TextAlign.center,
                style: tt.titleSmall,
              ),
            ),
            IconButton(
              icon: const PhosphorIcon(
                  PhosphorIconsRegular.caretRight,
                  size: 18,
                  color: AppColors.textPrimary),
              onPressed: () => setState(() {
                _focusedMonth = DateTime(
                    _focusedMonth.year, _focusedMonth.month + 1);
              }),
            ),
          ]),

          // Jours de la semaine
          Row(
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                .map((d) => Expanded(
                      child: Text(d,
                          textAlign: TextAlign.center,
                          style: tt.labelSmall?.copyWith(
                              color: AppColors.textSecondary)),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Grille des jours
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, childAspectRatio: 1.1),
            itemCount: firstDayOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) return const SizedBox();
              final day = index - firstDayOffset + 1;
              final date = DateTime(
                  _focusedMonth.year, _focusedMonth.month, day);
              final isSelected =
                  DateUtils.isSameDay(date, widget.selectedDay);
              final isToday = DateUtils.isSameDay(date, today);
              final isPast = date.isBefore(
                  DateTime(today.year, today.month, today.day));
              final isAvailableDay =
                  widget.availableDays.contains(date.weekday);
              final isDisabled = isPast || !isAvailableDay;

              return GestureDetector(
                onTap: isDisabled
                    ? null
                    : () => widget.onDaySelected(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    day.toString(),
                    style: tt.bodySmall?.copyWith(
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.surface
                          : isDisabled
                              ? AppColors.border
                              : AppColors.textBody,
                      decoration: (!isAvailableDay && !isPast)
                          ? TextDecoration.lineThrough
                          : null,
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
