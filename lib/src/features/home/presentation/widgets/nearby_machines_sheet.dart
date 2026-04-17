import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../machines_map/domain/models/machine_model.dart';
import 'machine_card.dart';

/// Feuille persistante (DraggableScrollableSheet) superposée à la carte.
/// 3 états :
///   • Réduit  (minChildSize = 0.12) → juste la poignée visible
///   • Mi-hauteur (initialChildSize = 0.45) → quelques cartes visibles
///   • Plein écran (maxChildSize = 0.92) → liste complète
class NearbyMachinesSheet extends StatefulWidget {
  final List<MachineModel> machines;
  final double? userLat;
  final double? userLng;
  final VoidCallback? onFocusMachine;

  const NearbyMachinesSheet({
    super.key,
    required this.machines,
    this.userLat,
    this.userLng,
    this.onFocusMachine,
  });

  @override
  State<NearbyMachinesSheet> createState() => _NearbyMachinesSheetState();
}

class _NearbyMachinesSheetState extends State<NearbyMachinesSheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(() {
      final isExpanded = _sheetController.isAttached &&
          _sheetController.size > 0.6;
      if (isExpanded != _isExpanded) {
        setState(() => _isExpanded = isExpanded);
      }
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  /// Calcule la distance en km entre deux points GPS (approximation)
  double? _distanceTo(MachineModel machine) {
    if (widget.userLat == null || widget.userLng == null) return null;
    const double earthRadius = 6371;
    final dLat = _toRad(machine.latitude - widget.userLat!);
    final dLng = _toRad(machine.longitude - widget.userLng!);
    final a = dLat * dLat + dLng * dLng;
    return earthRadius * a.abs().sqrt();
  }

  double _toRad(double deg) => deg * 3.14159265358979 / 180;

  /// Trie les machines par distance croissante
  List<MachineModel> get _sortedMachines {
    final list = [...widget.machines];
    if (widget.userLat != null) {
      list.sort((a, b) {
        final dA = _distanceTo(a) ?? 9999;
        final dB = _distanceTo(b) ?? 9999;
        return dA.compareTo(dB);
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedMachines;
    final availableCount = sorted.where((m) => m.status == 'AVAILABLE').length;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.40,
      minChildSize: 0.12,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.12, 0.40, 0.92],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Poignée ─────────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  // Toggle entre réduit et mi-hauteur au tap sur la poignée
                  final target = _sheetController.size > 0.3 ? 0.12 : 0.40;
                  _sheetController.animateTo(
                    target,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── En-tête du sheet ─────────────────────────────────────────
              AnimatedOpacity(
                opacity: _sheetController.isAttached &&
                        _sheetController.size > 0.18
                    ? 1.0
                    : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Machines à proximité',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '$availableCount disponible${availableCount > 1 ? 's' : ''} · ${sorted.length} au total',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Filtre (placeholder)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.tune_rounded,
                            size: 18, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Liste scrollable ──────────────────────────────────────────
              Expanded(
                child: sorted.isEmpty
                    ? _EmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding:
                            const EdgeInsets.only(bottom: 120, top: 4),
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final machine = sorted[index];
                          return MachineCard(
                            machine: machine,
                            distanceKm: _distanceTo(machine),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 200;
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCompact) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEFF6FF),
                        ),
                        child: const Icon(Icons.local_laundry_service_outlined,
                            size: 40, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Aucune machine à proximité',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!isCompact) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Aucune machine n\'est enregistrée\nprès de votre position actuelle.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

extension on double {
  double sqrt() => _sqrt(this);
  double _sqrt(double x) {
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
