import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 0), 
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF), // Fond blanc pur
          borderRadius: BorderRadius.circular(32), // Bords très arrondis (Pill-shape)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), // Ombre très fine (5% d'opacité)
              blurRadius: 20,
              offset: const Offset(0, 4), 
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(
              iconOutlined: Icons.home_outlined,
              iconFilled: Icons.home_rounded,
              label: "Accueil",
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavBarItem(
              iconOutlined: Icons.local_mall_outlined,
              iconFilled: Icons.local_mall_rounded,
              label: "Boutique",
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavBarItem(
              iconOutlined: Icons.grid_view_outlined,
              iconFilled: Icons.grid_view_rounded,
              label: "Réservations",
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavBarItem(
              iconOutlined: Icons.chat_bubble_outline_rounded,
              iconFilled: Icons.chat_bubble_rounded,
              label: "Messages",
              isActive: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavBarItem(
              iconOutlined: Icons.settings_outlined,
              iconFilled: Icons.settings_rounded,
              label: "Profil",
              isActive: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData iconOutlined;
  final IconData iconFilled;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.iconOutlined,
    required this.iconFilled,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Changement de couleur dynamique : Bleu Royal vs Gris Ardoise
    final color = isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B);
    // Changement d'icône dynamique : Pleine vs Vide
    final icon = isActive ? iconFilled : iconOutlined;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Étend la zone de clic pour le confort sans splash
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Évite que la colonne ne prenne toute la hauteur
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
