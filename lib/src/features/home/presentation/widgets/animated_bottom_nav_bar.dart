import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedBottomNavBar — Barre plate style Airbnb avec Sliding Glow Indicator
// DS §6.1 : border-top 1px, elevation 0, Phosphor icons
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const int itemCount = 5;
            final double itemWidth = constraints.maxWidth / itemCount;
            final double glowLeft = currentIndex * itemWidth;

            return Stack(
              children: [
                // ── Sliding Glow Indicator ───────────────────────
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: glowLeft,
                  top: 0,
                  width: itemWidth,
                  height: 64,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Barre indicatrice (2px)
                      Center(
                        child: Container(
                          width: 28,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull),
                          ),
                        ),
                      ),
                      // Halo dégradé bleu → transparent
                      Expanded(
                        child: Container(
                          width: itemWidth,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.10),
                                AppColors.primary.withValues(alpha: 0.00),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Onglets ──────────────────────────────────────
                Row(
                  children: [
                    _NavItem(
                      iconRegular: PhosphorIconsRegular.house,
                      iconFill: PhosphorIconsFill.house,
                      label: 'Accueil',
                      isActive: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                    _NavItem(
                      iconRegular: PhosphorIconsRegular.shoppingBag,
                      iconFill: PhosphorIconsFill.shoppingBag,
                      label: 'Boutique',
                      isActive: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                    _NavItem(
                      iconRegular: PhosphorIconsRegular.calendarBlank,
                      iconFill: PhosphorIconsFill.calendarBlank,
                      label: 'Réservations',
                      isActive: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                    _MessagesNavItem(
                      isActive: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),
                    _NavItem(
                      iconRegular: PhosphorIconsRegular.user,
                      iconFill: PhosphorIconsFill.user,
                      label: 'Profil',
                      isActive: currentIndex == 4,
                      onTap: () => onTap(4),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavItem — Onglet standard avec crossfade icône + interpolation couleur texte
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final PhosphorIconData iconRegular;
  final PhosphorIconData iconFill;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconRegular,
    required this.iconFill,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: PhosphorIcon(
                  isActive ? iconFill : iconRegular,
                  key: ValueKey(isActive),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 200),
                tween: ColorTween(
                  begin: isActive ? AppColors.textSecondary : AppColors.primary,
                  end: color,
                ),
                builder: (context, animColor, _) => Text(
                  label,
                  style: tt.labelSmall?.copyWith(
                    color: animColor,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 10,
                  ),
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
// _MessagesNavItem — Onglet Messages avec badge temps réel Firestore
// ─────────────────────────────────────────────────────────────────────────────
class _MessagesNavItem extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _MessagesNavItem({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder<int>(
                stream: FirebaseAuth.instance
                    .authStateChanges()
                    .asyncExpand((user) {
                  if (user == null) return Stream.value(0);
                  return FirebaseFirestore.instance
                      .collection('conversations')
                      .where('participantIds', arrayContains: user.uid)
                      .snapshots()
                      .map((snap) {
                    int total = 0;
                    for (final doc in snap.docs) {
                      final data = doc.data();
                      final unread = (data['unreadCount']
                          as Map<String, dynamic>?)?[user.uid];
                      if (unread is int) total += unread;
                    }
                    return total;
                  });
                }),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  final badge = count > 9
                      ? '9+'
                      : count > 0
                          ? '$count'
                          : null;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: PhosphorIcon(
                          isActive
                              ? PhosphorIconsFill.chatCircle
                              : PhosphorIconsRegular.chatCircle,
                          key: ValueKey(isActive),
                          color: color,
                          size: 22,
                        ),
                      ),
                      if (badge != null)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: AppSpacing.xs / 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull),
                            ),
                            child: Text(
                              badge,
                              style: tt.labelSmall?.copyWith(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w700,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 200),
                tween: ColorTween(
                  begin:
                      isActive ? AppColors.textSecondary : AppColors.primary,
                  end: color,
                ),
                builder: (context, animColor, _) => Text(
                  'Messages',
                  style: tt.labelSmall?.copyWith(
                    color: animColor,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

