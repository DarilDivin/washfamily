import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:washfamily/src/features/authentication/data/repositories/user_repository.dart';
import 'package:washfamily/src/features/authentication/domain/models/user_model.dart';
import 'package:washfamily/src/features/authentication/data/services/auth_service.dart';
import 'become_owner_wizard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final user = await UserRepository().getUser(uid);
    if (mounted) setState(() { _userModel = user; _isLoading = false; });
  }

  Future<void> _openBecomeOwnerWizard() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const BecomeOwnerWizard()),
    );
    if (result == true) await _loadUser();
  }

  Future<void> _removeOwnerRole() async {
    if (_userModel == null) return;
    setState(() => _isLoading = true);
    try {
      await UserRepository().removeRole(_userModel!.uid, 'OWNER');
      await _loadUser();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de mise à jour du rôle')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userModel == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_userModel == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Utilisateur introuvable.', textAlign: TextAlign.center),
              TextButton(onPressed: _logout, child: const Text('Se déconnecter')),
            ],
          ),
        ),
      );
    }

    final isOwner = _userModel!.isOwner;
    final isAdmin = _userModel!.isAdmin;
    final contact = FirebaseAuth.instance.currentUser?.email
        ?? FirebaseAuth.instance.currentUser?.phoneNumber
        ?? '';

    final chips = <String>['Vérifié'];
    if (isOwner) chips.add('Propriétaire');
    if (isAdmin) chips.add('Admin');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: const Color(0xFFF8FAFC),
            surfaceTintColor: Colors.transparent,
            pinned: true,
            elevation: 0,
            leading: const SizedBox.shrink(),
            title: Text(
              'Profil',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            centerTitle: true,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),
          ),

          // ── Hero header ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              child: Column(
                children: [
                  _InitialsAvatar(
                    firstName: _userModel!.firstName,
                    lastName: _userModel!.lastName,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_userModel!.firstName} ${_userModel!.lastName}',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (contact.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      contact,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    children: chips
                        .map((l) => _StatusChip(label: l))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          // ── Owner banner ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: isOwner
                  ? _OwnerActiveRow(
                      onRemove: _removeOwnerRole,
                      isLoading: _isLoading,
                    )
                  : _BecomeOwnerRow(onTap: _openBecomeOwnerWizard),
            ),
          ),

          // ── Menu sections ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isAdmin) ...[
                    _SectionLabel('Administration'),
                    _MenuGroup(items: [
                      _MenuEntry(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Tableau de bord admin',
                        onTap: () => context.push('/admin/dashboard'),
                      ),
                    ]),
                    const SizedBox(height: 28),
                  ],

                  _SectionLabel('Activité'),
                  _MenuGroup(items: [
                    _MenuEntry(
                      icon: Icons.receipt_long_outlined,
                      title: 'Mes réservations',
                      onTap: () => context.go('/bookings'),
                    ),
                    _MenuEntry(
                      icon: Icons.bookmark_border_rounded,
                      title: 'Favoris',
                      onTap: () => context.push('/profile/favorites'),
                    ),
                    if (isOwner) ...[
                      _MenuEntry(
                        icon: Icons.local_laundry_service_outlined,
                        title: 'Mes machines',
                        onTap: () => context.push('/profile/my-machines'),
                      ),
                      _MenuEntry(
                        icon: Icons.inbox_outlined,
                        title: 'Demandes en attente',
                        onTap: () => context.push('/profile/owner-bookings'),
                      ),
                      _MenuEntry(
                        icon: Icons.bar_chart_rounded,
                        title: 'Revenus & Statistiques',
                        onTap: () => context.push('/profile/revenue'),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 28),
                  _SectionLabel('Mon compte'),
                  _MenuGroup(items: [
                    _MenuEntry(
                      icon: Icons.person_outline_rounded,
                      title: 'Informations personnelles',
                      onTap: () => context.push('/profile/personal-info'),
                    ),
                    _MenuEntry(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Mon abonnement',
                      onTap: () => context.push('/subscriptions'),
                    ),
                    _MenuEntry(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Paiements et réductions',
                      onTap: () => context.push('/profile/payments'),
                    ),
                    if (isOwner)
                      _MenuEntry(
                        icon: Icons.account_balance_outlined,
                        title: 'Coordonnées bancaires',
                        onTap: () => context.push('/profile/bank-details'),
                      ),
                  ]),

                  const SizedBox(height: 28),
                  _SectionLabel('Assistance'),
                  _MenuGroup(items: [
                    _MenuEntry(
                      icon: Icons.help_outline_rounded,
                      title: "Centre d'aide",
                      onTap: () => context.push('/profile/help'),
                    ),
                    _MenuEntry(
                      icon: Icons.shield_outlined,
                      title: 'Sécurité et signalement',
                      onTap: () => context.push('/profile/security'),
                    ),
                  ]),

                  const SizedBox(height: 36),
                  GestureDetector(
                    onTap: _logout,
                    child: Text(
                      'Se déconnecter',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'WashFamily · v1.0.0',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),

                  const SizedBox(height: 28),
                  _SectionLabel('Développeur'),
                  _MenuGroup(items: [
                    _MenuEntry(
                      icon: Icons.data_object_rounded,
                      title: 'Outils Dev (Seed Data)',
                      onTap: () => context.push('/dev/seed'),
                    ),
                  ]),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar initiales ───────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String firstName;
  final String lastName;
  const _InitialsAvatar({required this.firstName, required this.lastName});

  @override
  Widget build(BuildContext context) {
    final initials =
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();
    return Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Status chip ────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }
}

// ── Owner rows ─────────────────────────────────────────────────────────────────

class _BecomeOwnerRow extends StatelessWidget {
  final VoidCallback onTap;
  const _BecomeOwnerRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_home_work_outlined,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Devenir propriétaire',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Mettez votre machine en location',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 13),
          ],
        ),
      ),
    );
  }
}

class _OwnerActiveRow extends StatelessWidget {
  final VoidCallback onRemove;
  final bool isLoading;
  const _OwnerActiveRow({required this.onRemove, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Color(0xFF0F172A), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode propriétaire actif',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Vos machines sont visibles',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            GestureDetector(
              onTap: onRemove,
              child: Text(
                'Désactiver',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Menu group ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFCBD5E1),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _MenuEntry({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class _MenuGroup extends StatelessWidget {
  final List<_MenuEntry> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: List.generate(items.length * 2 - 1, (i) {
          if (i.isOdd) {
            return const Divider(
              height: 1,
              indent: 52,
              color: Color(0xFFF1F5F9),
            );
          }
          final idx = i ~/ 2;
          final item = items[idx];
          final isFirst = idx == 0;
          final isLast = idx == items.length - 1;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.vertical(
                top: isFirst ? const Radius.circular(14) : Radius.zero,
                bottom: isLast ? const Radius.circular(14) : Radius.zero,
              ),
              onTap: item.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(item.icon,
                        size: 20, color: const Color(0xFF64748B)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
