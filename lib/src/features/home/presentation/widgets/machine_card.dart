import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../machines_map/domain/models/machine_model.dart';

/// Carte machine premium pour la liste des machines proches.
/// Affiche toutes les informations clés et navigue vers le détail au tap.
class MachineCard extends StatelessWidget {
  final MachineModel machine;
  final double? distanceKm;

  const MachineCard({super.key, required this.machine, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final isAvailable = machine.status == 'AVAILABLE';

    return GestureDetector(
      onTap: () {
        // Navigation vers la page détail de la machine
        context.push('/machine/${machine.id}', extra: machine);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image / Header ────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  // Photo ou gradient placeholder
                  if (machine.photoUrls.isNotEmpty)
                    Image.network(
                      machine.photoUrls.first,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Cercles décoratifs en arrière-plan
                          Positioned(
                            right: -20, top: -20,
                            child: Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -10, bottom: -30,
                            child: Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          // Icône centrale
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.local_laundry_service_rounded,
                                  size: 56,
                                  color: Colors.white70,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  machine.brand,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Badge Statut (haut gauche)
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isAvailable ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isAvailable ? 'Disponible' : 'Occupée',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Distance (haut droit)
                  if (distanceKm != null)
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              distanceKm! < 1
                                  ? '${(distanceKm! * 1000).toStringAsFixed(0)} m'
                                  : '${distanceKm!.toStringAsFixed(1)} km',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Corps de la carte ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne 1 : Brand + Prix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        machine.brand,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${machine.pricePerWash.toStringAsFixed(2)} €',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Ligne 2 : Icônes info (capacité, type, lessive)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _InfoChip(icon: Icons.water_drop_outlined, label: '${machine.capacityKg} kg'),
                      if (machine.description.contains('[Sèche-linge]'))
                        _InfoChip(icon: Icons.air_outlined, label: 'Sèche-linge')
                      else if (machine.description.contains('[Combiné]'))
                        _InfoChip(icon: Icons.loop_rounded, label: 'Combiné')
                      else
                        _InfoChip(icon: Icons.local_laundry_service_outlined, label: 'Lave-linge'),
                      if (machine.description.contains('Lessive fournie'))
                        _InfoChip(icon: Icons.soap_outlined, label: 'Lessive fournie', highlight: true),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Ligne 3 : Adresse + Note
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          machine.address ?? 'Adresse non précisée',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (machine.reviewCount > 0) ...[
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                        const SizedBox(width: 2),
                        Text(
                          '${machine.rating.toStringAsFixed(1)} (${machine.reviewCount})',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit badge d'information réutilisable
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _InfoChip({required this.icon, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12,
            color: highlight ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: highlight ? const Color(0xFF2563EB) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
