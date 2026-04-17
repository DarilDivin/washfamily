import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../features/authentication/domain/models/user_model.dart';
import '../../../../features/subscriptions/data/subscription_repository.dart';
import '../../../../features/subscriptions/domain/models/subscription_plan_model.dart';
import '../../../../features/subscriptions/presentation/screens/subscription_plans_screen.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final snap =
      await FirebaseFirestore.instance.collection('users').get();
  return snap.docs
      .map((d) => UserModel.fromJson(d.data(), d.id))
      .toList()
    ..sort((a, b) =>
        '${a.firstName} ${a.lastName}'.compareTo('${b.firstName} ${b.lastName}'));
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminSubscriptionsScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  ConsumerState<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState
    extends ConsumerState<AdminSubscriptionsScreen> {
  String _search = '';
  _Filter _filter = _Filter.all;

  List<UserModel> _applyFilter(List<UserModel> users) {
    final now = DateTime.now();
    return users.where((u) {
      // Filtre statut
      final hasActiveSub = u.currentSubscriptionId != null &&
          u.subscriptionEndDate != null &&
          u.subscriptionEndDate!.isAfter(now);
      final hasExpiredSub = u.currentSubscriptionId != null &&
          u.subscriptionEndDate != null &&
          u.subscriptionEndDate!.isBefore(now);
      final isFree = !hasActiveSub && !hasExpiredSub;

      final matchFilter = switch (_filter) {
        _Filter.all     => true,
        _Filter.active  => hasActiveSub,
        _Filter.expired => hasExpiredSub,
        _Filter.free    => isFree,
      };

      // Filtre recherche
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          '${u.firstName} ${u.lastName}'.toLowerCase().contains(q) ||
          u.phoneNumber.contains(q);

      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(_allUsersProvider);
    final plansAsync = ref.watch(activePlansProvider);

    final plans = plansAsync.valueOrNull ?? [];
    final activeCount = usersAsync.valueOrNull
            ?.where((u) =>
                u.subscriptionEndDate?.isAfter(DateTime.now()) == true)
            .length ??
        0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Abonnements',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            if (usersAsync.hasValue)
              Text('$activeCount actif${activeCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B))),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        children: [
          // ── Recherche ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur…',
                hintStyle: const TextStyle(
                    color: Color(0xFFCBD5E1), fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF94A3B8), size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                ),
              ),
            ),
          ),

          // ── Filtres ────────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _Filter.values.map((f) {
                final active = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: active,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: const Color(0xFF0F172A),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: active
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    side: BorderSide(
                        color: active
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ── Liste ──────────────────────────────────────────────
          Expanded(
            child: usersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (users) {
                final filtered = _applyFilter(users);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Aucun utilisateur trouvé',
                        style: TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 14)),
                  );
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  itemBuilder: (context, i) => _UserTile(
                    user: filtered[i],
                    plans: plans,
                    onChanged: () => ref.invalidate(_allUsersProvider),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile utilisateur ──────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final UserModel user;
  final List<SubscriptionPlanModel> plans;
  final VoidCallback onChanged;

  const _UserTile({
    required this.user,
    required this.plans,
    required this.onChanged,
  });

  String get _initials =>
      '${user.firstName.isNotEmpty ? user.firstName[0] : '?'}'
      '${user.lastName.isNotEmpty ? user.lastName[0] : ''}';

  SubscriptionPlanModel? get _activePlan => plans
      .where((p) => p.id == user.currentSubscriptionId)
      .firstOrNull;

  bool get _isActive =>
      user.subscriptionEndDate?.isAfter(DateTime.now()) == true &&
      user.currentSubscriptionId != null;

  bool get _isExpired =>
      user.currentSubscriptionId != null &&
      user.subscriptionEndDate?.isBefore(DateTime.now()) == true;

  @override
  Widget build(BuildContext context) {
    final plan = _activePlan;

    return InkWell(
      onTap: () => _showActions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFF1F5F9),
              child: Text(_initials,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151))),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${user.firstName} ${user.lastName}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(user.phoneNumber,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ),

            // Statut abonnement
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(
                  label: _isActive
                      ? (plan?.name ?? 'Actif')
                      : _isExpired
                          ? 'Expiré'
                          : 'Gratuit',
                  isActive: _isActive,
                  isExpired: _isExpired,
                ),
                const SizedBox(height: 4),
                if (_isActive && user.subscriptionEndDate != null)
                  Text(
                    '${user.remainingReservations}/${plan?.maxReservationsPerMonth ?? '?'}'
                    ' · ${DateFormat("d MMM", "fr").format(user.subscriptionEndDate!)}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8)),
                  )
                else
                  Text(
                    '${user.remainingReservations} rés. dispo',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserActionsSheet(
        user: user,
        plans: plans,
        onChanged: () {
          Navigator.pop(context);
          onChanged();
        },
      ),
    );
  }
}

// ── Badge statut ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isExpired;

  const _StatusBadge({
    required this.label,
    required this.isActive,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    if (isActive) {
      bg = const Color(0xFF0F172A);
      fg = Colors.white;
    } else if (isExpired) {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFEF4444);
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// ── Bottom sheet actions ──────────────────────────────────────────────────────

class _UserActionsSheet extends StatefulWidget {
  final UserModel user;
  final List<SubscriptionPlanModel> plans;
  final VoidCallback onChanged;

  const _UserActionsSheet({
    required this.user,
    required this.plans,
    required this.onChanged,
  });

  @override
  State<_UserActionsSheet> createState() => _UserActionsSheetState();
}

class _UserActionsSheetState extends State<_UserActionsSheet> {
  bool _loading = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() { _loading = true; _error = null; });
    try {
      await action();
      widget.onChanged();
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _assignPlan(SubscriptionPlanModel plan) => _run(() =>
      SubscriptionRepository().subscribeUserToPlan(widget.user.uid, plan));

  Future<void> _resetQuota() async {
    final plan = widget.plans
        .where((p) => p.id == widget.user.currentSubscriptionId)
        .firstOrNull;
    if (plan == null) return;
    await _run(() => FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .update({'remainingReservations': plan.maxReservationsPerMonth}));
  }

  Future<void> _revoke() => _run(() => FirebaseFirestore.instance
      .collection('users')
      .doc(widget.user.uid)
      .update({
        'currentSubscriptionId': FieldValue.delete(),
        'subscriptionEndDate': FieldValue.delete(),
        'remainingReservations': 2,
      }));

  @override
  Widget build(BuildContext context) {
    final hasSub = widget.user.currentSubscriptionId != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // User header
          Text('${widget.user.firstName} ${widget.user.lastName}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A))),
          Text(widget.user.phoneNumber,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF94A3B8))),
          const SizedBox(height: 24),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontSize: 13)),
            ),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[

            // Assigner un plan
            const Text('Assigner un plan',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            ...widget.plans.map((plan) {
              final isCurrent = plan.id == widget.user.currentSubscriptionId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActionTile(
                  title: plan.name,
                  subtitle: plan.price == 0
                      ? 'Gratuit · ${plan.maxReservationsPerMonth} rés.'
                      : '${plan.price.toStringAsFixed(0)} € / mois · ${plan.maxReservationsPerMonth} rés.',
                  trailing: isCurrent
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Color(0xFF0F172A))
                      : null,
                  onTap: isCurrent ? null : () => _assignPlan(plan),
                ),
              );
            }),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),

            // Actions secondaires
            if (hasSub)
              _ActionTile(
                title: 'Réinitialiser le quota',
                subtitle: 'Restaure les réservations du plan actuel',
                onTap: _resetQuota,
              ),
            const SizedBox(height: 8),
            if (hasSub)
              _ActionTile(
                title: 'Révoquer l\'abonnement',
                subtitle: 'Repasse l\'utilisateur sur le tier gratuit',
                isDestructive: true,
                onTap: _revoke,
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDestructive
                                ? const Color(0xFFEF4444)
                                : onTap == null
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF0F172A))),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Enum filtre ───────────────────────────────────────────────────────────────

enum _Filter {
  all('Tous'),
  active('Actifs'),
  expired('Expirés'),
  free('Sans abonnement');

  final String label;
  const _Filter(this.label);
}
