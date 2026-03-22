import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../machines_map/domain/models/machine_model.dart';

class MachineDetailScreen extends StatelessWidget {
  final MachineModel machine;

  const MachineDetailScreen({super.key, required this.machine});

  @override
  Widget build(BuildContext context) {
    final isAvailable = machine.status == 'AVAILABLE';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar avec image ───────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo ou gradient
                  if (machine.photoUrls.isNotEmpty)
                    Image.network(machine.photoUrls.first, fit: BoxFit.cover)
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        ),
                      ),
                      child: Stack(children: [
                        Positioned(right: -30, top: -30, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
                        Positioned(left: -20, bottom: -40, child: Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)))),
                        Center(child: Icon(Icons.local_laundry_service_rounded, size: 96, color: Colors.white.withValues(alpha: 0.3))),
                      ]),
                    ),
                  // Dégradé sombre en bas pour lire le texte
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC000000)],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Texte en bas de l'image
                  Positioned(
                    left: 20, right: 20, bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isAvailable ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isAvailable ? 'Disponible maintenant' : 'Actuellement occupée',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          machine.brand,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        if (machine.address != null)
                          Row(children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 13),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                machine.address!,
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Corps ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prix + Note
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          Text(
                            '${machine.pricePerWash.toStringAsFixed(2)} €',
                            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF2563EB)),
                          ),
                          Text(
                            ' / lavage',
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                          ),
                        ]),
                      ),
                      const Spacer(),
                      if (machine.reviewCount > 0)
                        Row(children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 20),
                          const SizedBox(width: 4),
                          Text(
                            machine.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          Text(
                            ' (${machine.reviewCount} avis)',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                        ]),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Caractéristiques
                  _SectionTitle('Caractéristiques'),
                  const SizedBox(height: 12),
                  Row(children: [
                    _StatCard(icon: Icons.water_drop_outlined, value: '${machine.capacityKg} kg', label: 'Capacité'),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: machine.description.contains('[Sèche-linge]')
                          ? Icons.air_outlined
                          : machine.description.contains('[Combiné]')
                              ? Icons.loop_rounded
                              : Icons.local_laundry_service_outlined,
                      value: machine.description.contains('[Sèche-linge]')
                          ? 'Sèche-linge'
                          : machine.description.contains('[Combiné]')
                              ? 'Combiné'
                              : 'Lave-linge',
                      label: 'Type',
                    ),
                    if (machine.description.contains('Lessive fournie')) ...[
                      const SizedBox(width: 12),
                      _StatCard(icon: Icons.soap_outlined, value: 'Fournie', label: 'Lessive'),
                    ],
                  ]),

                  const SizedBox(height: 24),

                  // Description
                  _SectionTitle('Description'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                    ),
                    child: Text(
                      machine.description
                          .replaceAll(RegExp(r'\[.*?\]\s*'), '')
                          .replaceAll(' — Lessive fournie.', ''),
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF374151), height: 1.6),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── CTA Réserver ────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: isAvailable
                ? () => context.push('/bookings/new', extra: machine)
                : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: const Color(0xFF2563EB),
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              isAvailable ? 'Réserver maintenant' : 'Machine indisponible',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF2563EB)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
