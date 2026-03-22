import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ------------------------------------------------------------------
// AnimatedBottomNavBar — Effet "Sliding Glow"
// Architecture : Stack { GlowIndicator (AnimatedPositioned) + Row d'icônes }
// Barre fixée en bas (pas flottante), fond blanc, bordure top fine.
// ------------------------------------------------------------------

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
    return Container(
      // ── Barre fixe en bas, bord à bord ───────────────────────────
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      // LayoutBuilder pour connaître la largeur réelle → calcul du Glow
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // ── 📐 MATHS DU GLOW ──────────────────────────────────────
            // totalWidth = largeur réelle de la barre (sans padding)
            // itemWidth  = totalWidth / 5  (une part par onglet)
            // glowLeft   = currentIndex * itemWidth  (position X de l'indicateur)
            const int itemCount = 5;
            final double totalWidth = constraints.maxWidth;
            final double itemWidth = totalWidth / itemCount;
            final double glowLeft = currentIndex * itemWidth;
            // ──────────────────────────────────────────────────────────

            return SizedBox(
              height: 66,
              child: Stack(
                children: [
                  // ── ✨ COUCHE 1 : Indicateur "Sliding Glow" ──────────
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: glowLeft,
                    top: 0,
                    width: itemWidth,
                    height: 66,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Barre "source de lumière" (2px de haut, 30px de large)
                        Center(
                          child: Container(
                            width: 30,
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        // Dégradé bleu → transparent sur toute la hauteur restante
                        Expanded(
                          child: Container(
                            width: itemWidth,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x1A2563EB), // bleu @ 10%
                                  Color(0x002563EB), // bleu @ 0% (vrai transparent)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 🎛️ COUCHE 2 : Row des 5 onglets ─────────────────
                  Row(
                    children: [
                      _NavItem(
                        iconOutlined: Icons.home_outlined,
                        iconFilled: Icons.home_rounded,
                        label: "Accueil",
                        isActive: currentIndex == 0,
                        onTap: () => onTap(0),
                      ),
                      _NavItem(
                        iconOutlined: Icons.local_mall_outlined,
                        iconFilled: Icons.local_mall_rounded,
                        label: "Boutique",
                        isActive: currentIndex == 1,
                        onTap: () => onTap(1),
                      ),
                      _NavItem(
                        iconOutlined: Icons.calendar_month_outlined,
                        iconFilled: Icons.calendar_month_rounded,
                        label: "Réservations",
                        isActive: currentIndex == 2,
                        onTap: () => onTap(2),
                      ),
                      _NavItem(
                        iconOutlined: Icons.chat_bubble_outline_rounded,
                        iconFilled: Icons.chat_bubble_rounded,
                        label: "Messages",
                        isActive: currentIndex == 3,
                        onTap: () => onTap(3),
                      ),
                      _NavItem(
                        iconOutlined: Icons.person_outline_rounded,
                        iconFilled: Icons.person_rounded,
                        label: "Profil",
                        isActive: currentIndex == 4,
                        onTap: () => onTap(4),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// _NavItem — Élément individuel avec changement de couleur animé
// ------------------------------------------------------------------
class _NavItem extends StatelessWidget {
  final IconData iconOutlined;
  final IconData iconFilled;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconOutlined,
    required this.iconFilled,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Actif → Royal Blue | Inactif → Gris Ardoise
    final targetColor = isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B);
    final targetIcon  = isActive ? iconFilled : iconOutlined;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 66,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône avec crossfade fluide entre Outlined et Filled
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  targetIcon,
                  key: ValueKey(isActive),
                  color: targetColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              // Texte avec interpolation de couleur fluide
              TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 200),
                tween: ColorTween(
                  begin: isActive ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                  end: targetColor,
                ),
                builder: (context, color, _) => Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: color,
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
