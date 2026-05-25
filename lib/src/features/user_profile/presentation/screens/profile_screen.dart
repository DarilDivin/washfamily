import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:washfamily/src/features/authentication/data/repositories/user_repository.dart';
import 'package:washfamily/src/features/authentication/domain/models/user_model.dart';
import 'package:washfamily/src/features/authentication/data/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

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
    if (mounted) {
      setState(() {
        _userModel = user;
        _isLoading = false;
      });
    }
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
    final tt = Theme.of(context).textTheme;

    if (_isLoading && _userModel == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_userModel == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Utilisateur introuvable.',
                  style: tt.bodyMedium, textAlign: TextAlign.center),
              TextButton(
                onPressed: _logout,
                child: const Text('Se déconnecter'),
              ),
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
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar ────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.scaffoldBackground,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            elevation: 0,
            leading: const SizedBox.shrink(),
            title: Text('Profil', style: tt.titleLarge),
            centerTitle: true,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            ),
          ),

          // ── Hero header ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
              child: Column(
                children: [
                  _InitialsAvatar(
                    firstName: _userModel!.firstName,
                    lastName: _userModel!.lastName,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '${_userModel!.firstName} ${_userModel!.lastName}',
                    style: tt.headlineLarge,
                  ),
                  if (contact.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      contact,
                      style: tt.labelLarge
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: chips
                        .map((l) => _StatusChip(label: l))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          // ── Abonnement ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
              child: _SubscriptionSection(user: _userModel!),
            ),
          ),

          // ── Owner banner ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
              child: isOwner
                  ? _OwnerActiveRow(
                      onDashboard: () => context.push('/owner-dashboard'),
                      onRemove: _removeOwnerRole,
                      isLoading: _isLoading,
                    )
                  : _BecomeOwnerRow(onTap: () => context.push('/become-owner')),
            ),
          ),

          // ── Sections menu ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isAdmin) ...[
                    _SectionLabel('Administration'),
                    _MenuGroup(items: [
                      _MenuEntry(
                        icon: PhosphorIconsRegular.shieldCheck,
                        title: 'Tableau de bord admin',
                        onTap: () => context.push('/admin/dashboard'),
                      ),
                    ]),
                    const SizedBox(height: AppSpacing.xxl),
                  ],

                  _SectionLabel('Activité'),
                  _MenuGroup(items: [
                    _MenuEntry(
                      icon: PhosphorIconsRegular.receipt,
                      title: 'Mes réservations',
                      onTap: () => context.go('/bookings'),
                    ),
                    _MenuEntry(
                      icon: PhosphorIconsRegular.bookmark,
                      title: 'Favoris',
                      onTap: () => context.push('/profile/favorites'),
                    ),
                    if (isOwner) ...[
                      _MenuEntry(
                        icon: PhosphorIconsRegular.storefront,
                        title: 'Mon tableau de bord',
                        onTap: () => context.push('/owner-dashboard'),
                      ),
                      _MenuEntry(
                        icon: PhosphorIconsRegular.tray,
                        title: 'Demandes en attente',
                        onTap: () => context.push('/profile/owner-bookings'),
                      ),
                      _MenuEntry(
                        icon: PhosphorIconsRegular.chartBar,
                        title: 'Revenus & Statistiques',
                        onTap: () => context.push('/profile/revenue'),
                      ),
                    ],
                  ]),

                  const SizedBox(height: AppSpacing.xxl),
                  _SectionLabel('Mon compte'),
                  _MenuGroup(items: [
                    _MenuEntry(
                      icon: PhosphorIconsRegular.user,
                      title: 'Informations personnelles',
                      onTap: () => context.push('/profile/personal-info'),
                    ),
                    _MenuEntry(
                      icon: PhosphorIconsRegular.crown,
                      title: 'Mon abonnement',
                      onTap: () => context.push('/subscriptions'),
                    ),
                    _MenuEntry(
                      icon: PhosphorIconsRegular.wallet,
                      title: 'Paiements et réductions',
                      onTap: () => context.push('/profile/payments'),
                    ),
                    if (isOwner)
                      _MenuEntry(
                        icon: PhosphorIconsRegular.bank,
                        title: 'Coordonnées bancaires',
                        onTap: () => context.push('/profile/bank-details'),
                      ),
                  ]),

                  const SizedBox(height: AppSpacing.xxl),
                  _SectionLabel('Assistance'),
                  _MenuGroup(items: [
                    _MenuEntry(
                      icon: PhosphorIconsRegular.question,
                      title: "Centre d'aide",
                      onTap: () => context.push('/profile/help'),
                    ),
                    _MenuEntry(
                      icon: PhosphorIconsRegular.shield,
                      title: 'Sécurité et signalement',
                      onTap: () => context.push('/profile/security'),
                    ),
                  ]),

                  const SizedBox(height: AppSpacing.xxl),
                  _SectionLabel('Développeur'),
                  _MenuGroup(items: [
                    _MenuEntry(
                      icon: PhosphorIconsRegular.code,
                      title: 'Outils Dev (Seed Data)',
                      onTap: () => context.push('/dev/seed'),
                    ),
                  ]),

                  const SizedBox(height: AppSpacing.xxl),

                  // Déconnexion
                  TextButton(
                    onPressed: _logout,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                    ),
                    child: Text(
                      'Se déconnecter',
                      style: tt.bodyMedium?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'WashFamily · v1.0.0',
                    textAlign: TextAlign.center,
                    style: tt.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar initiales ──────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String firstName;
  final String lastName;
  const _InitialsAvatar({required this.firstName, required this.lastName});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final initials =
        '${firstName.isNotEmpty ? firstName[0] : ''}'
        '${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();
    return Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: tt.titleLarge?.copyWith(
            color: AppColors.surface, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + AppSpacing.xs,
          vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Owner banner rows ─────────────────────────────────────────────────────────

class _BecomeOwnerRow extends StatelessWidget {
  final VoidCallback onTap;
  const _BecomeOwnerRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Material(
      color: AppColors.textPrimary,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        splashColor: AppColors.surface.withValues(alpha: 0.08),
        highlightColor: AppColors.surface.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              PhosphorIcon(PhosphorIconsRegular.houseLine,
                  size: 20, color: AppColors.surface),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Devenir propriétaire',
                      style: tt.titleSmall
                          ?.copyWith(color: AppColors.surface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mettez votre machine en location',
                      style: tt.labelSmall?.copyWith(
                          color: AppColors.surface.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              PhosphorIcon(PhosphorIconsRegular.arrowRight,
                  size: 14, color: AppColors.surface),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerActiveRow extends StatelessWidget {
  final VoidCallback onDashboard;
  final VoidCallback onRemove;
  final bool isLoading;
  const _OwnerActiveRow({
    required this.onDashboard,
    required this.onRemove,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bouton principal "Mon tableau de bord"
        Material(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            onTap: onDashboard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            splashColor: AppColors.surface.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(children: [
                PhosphorIcon(PhosphorIconsRegular.storefront,
                    size: 20, color: AppColors.surface),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Mon tableau de bord',
                        style: tt.titleSmall?.copyWith(color: AppColors.surface)),
                    const SizedBox(height: 2),
                    Text('Gérez votre laverie et vos machines',
                        style: tt.labelSmall
                            ?.copyWith(color: AppColors.surface.withValues(alpha: 0.6))),
                  ]),
                ),
                PhosphorIcon(PhosphorIconsRegular.arrowRight,
                    size: 14, color: AppColors.surface),
              ]),
            ),
          ),
        ),
        // Lien discret "Désactiver le mode propriétaire"
        if (!isLoading)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRemove,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Désactiver le mode propriétaire',
                  style: tt.labelSmall?.copyWith(color: AppColors.textSecondary)),
            ),
          ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Center(
              child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Menu group ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(
          bottom: AppSpacing.sm + AppSpacing.xs, left: 2),
      child: Text(
        text.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          fontSize: 10,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _MenuEntry {
  final PhosphorIconData icon;
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
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(items.length * 2 - 1, (i) {
          if (i.isOdd) {
            return const Divider(
                height: 1, indent: 52, color: AppColors.inputBackground);
          }
          final idx = i ~/ 2;
          final item = items[idx];
          final isFirst = idx == 0;
          final isLast = idx == items.length - 1;
          return InkWell(
            borderRadius: BorderRadius.vertical(
              top: isFirst
                  ? const Radius.circular(AppSpacing.radiusMd)
                  : Radius.zero,
              bottom: isLast
                  ? const Radius.circular(AppSpacing.radiusMd)
                  : Radius.zero,
            ),
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  PhosphorIcon(item.icon,
                      size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(item.title, style: tt.titleSmall),
                  ),
                  PhosphorIcon(PhosphorIconsRegular.caretRight,
                      size: 16, color: AppColors.border),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Section abonnement ────────────────────────────────────────────────────────

class _SubscriptionSection extends StatelessWidget {
  final UserModel user;
  const _SubscriptionSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final active = user.hasActiveSubscription;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: active ? AppColors.primary : AppColors.border),
      ),
      child: active ? _ActiveContent(user: user, tt: tt) : _InactiveContent(tt: tt),
    );
  }
}

class _ActiveContent extends StatelessWidget {
  final UserModel user;
  final TextTheme tt;
  const _ActiveContent({required this.user, required this.tt});

  @override
  Widget build(BuildContext context) {
    final remaining = user.remainingReservations;
    final expiry = user.subscriptionEndDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const PhosphorIcon(PhosphorIconsFill.crown,
              size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(user.currentSubscriptionId ?? 'Plan actif',
              style: tt.titleSmall?.copyWith(color: AppColors.primary)),
        ]),
        if (expiry != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Expire le ${DateFormat("d MMMM yyyy", "fr").format(expiry)}',
            style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          remaining == -1
              ? 'Réservations illimitées'
              : '$remaining réservation${remaining > 1 ? 's' : ''} restante${remaining > 1 ? 's' : ''}',
          style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () => context.push('/subscriptions'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            minimumSize: const Size(double.infinity, 0),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          ),
          child: const Text('Changer de plan'),
        ),
      ],
    );
  }
}

class _InactiveContent extends StatelessWidget {
  final TextTheme tt;
  const _InactiveContent({required this.tt});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aucun abonnement actif',
            style: tt.titleSmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: () => context.push('/subscriptions'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 0),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          ),
          child: const Text('Voir les plans'),
        ),
      ],
    );
  }
}
