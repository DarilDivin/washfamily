import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import '../../../machines_map/domain/models/machine_model.dart';
import '../../../machines_map/data/repositories/firestore_machine_repository.dart';
import '../widgets/nearby_machines_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final FirestoreMachineRepository _machineRepository = FirestoreMachineRepository();

  Set<Marker> _markers = {};
  List<MachineModel> _machines = [];
  double? _userLat;
  double? _userLng;
  MachineModel? _selectedMachine;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  final FocusNode _searchFocus = FocusNode();
  bool _isSearchActive = false;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(48.8566, 2.3522),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLocate();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
    _searchFocus.addListener(() {
      setState(() => _isSearchActive = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndLocate() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();

    if (mounted) {
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
    }

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        ),
      ),
    );

    await _loadMachines(position.latitude, position.longitude);
  }

  // Cache pour éviter de recalculer les bitmaps identiques
  final Map<String, BitmapDescriptor> _markerCache = {};

  Future<void> _loadMachines(double lat, double lng) async {
    try {
      final machines = await _machineRepository.getAllMachines();
      if (mounted) setState(() => _machines = machines);
      await _rebuildMarkers();
    } catch (e) {
      debugPrint('Erreur chargement machines: $e');
    }
  }

  Future<BitmapDescriptor> _buildMarkerBitmap(MachineModel machine,
      {bool selected = false}) async {
    final cacheKey =
        '${machine.status}_${machine.pricePerWash}_${selected ? 's' : 'n'}';
    if (_markerCache.containsKey(cacheKey)) return _markerCache[cacheKey]!;

    const double dpr    = 3.0;
    const double pillW  = 90.0;
    const double pillH  = 38.0;
    const double triH   =  8.0;
    const double totalH = pillH + triH;
    const double radius = pillH / 2;

    final isAvailable   = machine.status == 'AVAILABLE';
    final isInUse       = machine.status == 'IN_USE';

    final bgColor = isAvailable
        ? const Color(0xFF2563EB)
        : isInUse
            ? const Color(0xFFF97316)
            : const Color(0xFF64748B);

    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder,
        Rect.fromLTWH(0, 0, pillW * dpr, totalH * dpr));
    canvas.scale(dpr);

    // ── Ombre portée ──────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 4, pillW - 6, pillH - 2),
        const Radius.circular(radius),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, pillW, pillH),
      const Radius.circular(radius),
    );

    if (selected) {
      // ── Sélectionné : fond blanc + bordure + ombre colorée ───
      canvas.drawRRect(pillRect, Paint()..color = Colors.white);
      canvas.drawRRect(
        pillRect,
        Paint()
          ..color = bgColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    } else {
      // ── Normal : fond coloré + contour blanc subtil ──────────
      canvas.drawRRect(pillRect, Paint()..color = bgColor);
      canvas.drawRRect(
        pillRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // ── Triangle pointer ──────────────────────────────────────────
    final triPath = Path()
      ..moveTo(pillW / 2 - 7, pillH - 1)
      ..lineTo(pillW / 2 + 7, pillH - 1)
      ..lineTo(pillW / 2,     pillH + triH)
      ..close();
    canvas.drawPath(triPath, Paint()..color = bgColor);

    // ── Texte ─────────────────────────────────────────────────────
    final label = isAvailable
        ? '${machine.pricePerWash.toStringAsFixed(2).replaceAll('.', ',')} €'
        : isInUse
            ? 'En cours'
            : 'Indisp.';

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: selected ? bgColor : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: pillW - 16);

    tp.paint(
      canvas,
      Offset((pillW - tp.width) / 2, (pillH - tp.height) / 2),
    );

    final image = await recorder.endRecording().toImage(
      (pillW  * dpr).round(),
      (totalH * dpr).round(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      width: pillW,
      height: totalH,
    );
    _markerCache[cacheKey] = descriptor;
    return descriptor;
  }

  double? _distanceTo(MachineModel m) {
    if (_userLat == null || _userLng == null) return null;
    const r = 6371.0;
    final dLat = (m.latitude  - _userLat!) * 3.14159265 / 180;
    final dLng = (m.longitude - _userLng!) * 3.14159265 / 180;
    return r * math.sqrt(dLat * dLat + dLng * dLng);
  }

  Future<void> _rebuildMarkers() async {
    final List<Marker> markers = [];
    for (final machine in _machines) {
      final sel = _selectedMachine?.id == machine.id;
      final icon = await _buildMarkerBitmap(machine, selected: sel);
      markers.add(Marker(
        markerId: MarkerId(machine.id),
        position: LatLng(machine.latitude, machine.longitude),
        icon: icon,
        anchor: const Offset(0.5, 1.0),
        zIndexInt: sel ? 1 : 0,
        onTap: () => _selectMachine(machine),
      ));
    }
    if (mounted) setState(() => _markers = markers.toSet());
  }

  void _selectMachine(MachineModel machine) {
    setState(() => _selectedMachine = machine);
    _rebuildMarkers();
  }

  void _deselectMachine() {
    if (_selectedMachine == null) return;
    setState(() => _selectedMachine = null);
    _rebuildMarkers();
  }

  Future<void> _searchLocation(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress(q);
      if (locations.isEmpty || !mounted) return;
      final loc = locations.first;
      final ctrl = await _controller.future;
      await ctrl.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(loc.latitude, loc.longitude), zoom: 13),
      ));
      setState(() {
        _userLat = loc.latitude;
        _userLng = loc.longitude;
      });
      await _loadMachines(loc.latitude, loc.longitude);
      _searchFocus.unfocus();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Adresse introuvable : $q'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // ── Couche 1 : Google Map ───────────────────────────────
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _defaultPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            padding: const EdgeInsets.only(bottom: 280),
            onTap: (_) {
              _searchFocus.unfocus();
              _deselectMachine();
            },
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
              _loadMachines(
                _defaultPosition.target.latitude,
                _defaultPosition.target.longitude,
              );
            },
          ),

          // ── Couche 2 : BottomSheet ancré ───────────────────────
          NearbyMachinesSheet(
            machines: _machines,
            userLat: _userLat,
            userLng: _userLng,
          ),

          // ── Couche 3 : Barre de recherche ──────────────────────
          Positioned(
            top: topPadding + 12,
            left: 16,
            right: 16,
            child: _SearchBar(
              controller: _searchController,
              focusNode: _searchFocus,
              isActive: _isSearchActive,
              isSearching: _isSearching,
              hasQuery: _searchQuery.isNotEmpty,
              onSubmitted: _searchLocation,
              onClear: () {
                _searchController.clear();
                _searchFocus.unfocus();
                _checkPermissionsAndLocate();
              },
              onDismiss: () => _searchFocus.unfocus(),
            ),
          ),

          // ── Couche 4 : Preview card machine sélectionnée ────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 300,
            child: AnimatedSlide(
              offset: _selectedMachine != null
                  ? Offset.zero
                  : const Offset(0, 1.6),
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _selectedMachine != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: IgnorePointer(
                  ignoring: _selectedMachine == null,
                  child: _selectedMachine != null
                      ? _MachinePreviewCard(
                          machine: _selectedMachine!,
                          distanceKm: _distanceTo(_selectedMachine!),
                          onClose: _deselectMachine,
                        )
                      : const SizedBox(height: 112),
                ),
              ),
            ),
          ),

          // ── Couche 5 : Bouton recentrer ──────────────────────────
          Positioned(
            bottom: 320,
            right: 20,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: theme.primaryColor,
              elevation: 4,
              onPressed: _checkPermissionsAndLocate,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview card — apparaît au tap sur un marker
// ─────────────────────────────────────────────────────────────────────────────
class _MachinePreviewCard extends StatelessWidget {
  final MachineModel machine;
  final double? distanceKm;
  final VoidCallback onClose;

  const _MachinePreviewCard({
    required this.machine,
    required this.onClose,
    this.distanceKm,
  });

  static const _blue  = Color(0xFF2563EB);
  static const _slate = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final isAvailable = machine.status == 'AVAILABLE';
    final statusColor = isAvailable
        ? const Color(0xFF16A34A)
        : machine.status == 'IN_USE'
            ? const Color(0xFFF97316)
            : _slate;

    return GestureDetector(
      onTap: () => context.push('/machine/${machine.id}', extra: machine),
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Photo / gradient ──────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(20)),
              child: SizedBox(
                width: 100,
                height: 112,
                child: machine.photoUrls.isNotEmpty
                    ? Image.network(machine.photoUrls.first,
                        fit: BoxFit.cover)
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          ),
                        ),
                        child: const Icon(
                            Icons.local_laundry_service_rounded,
                            size: 40,
                            color: Colors.white54),
                      ),
              ),
            ),

            // ── Infos ──────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne 1 : marque + bouton fermer
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            machine.brand,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF1F5F9),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: _slate),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Ligne 2 : adresse
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: _slate),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            machine.address ?? 'Adresse non précisée',
                            style: const TextStyle(
                                fontSize: 11, color: _slate),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Ligne 3 : statut · distance · prix · CTA
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isAvailable
                                ? 'Disponible'
                                : machine.status == 'IN_USE'
                                    ? 'En cours'
                                    : 'Indisp.',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                        if (distanceKm != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            distanceKm! < 1
                                ? '${(distanceKm! * 1000).toStringAsFixed(0)} m'
                                : '${distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                                fontSize: 11, color: _slate),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          '${machine.pricePerWash.toStringAsFixed(2).replaceAll('.', ',')} €',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Réserver',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barre de recherche — deux états animés : idle / actif
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final bool isSearching;
  final bool hasQuery;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onDismiss;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.isSearching,
    required this.hasQuery,
    required this.onSubmitted,
    required this.onClear,
    required this.onDismiss,
  });

  static const _radius = 16.0;
  static const _blue = Color(0xFF2563EB);
  static const _slate = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isActive ? 0.13 : 0.07),
            blurRadius: isActive ? 30 : 14,
            spreadRadius: isActive ? 1 : 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Material(
          color: Colors.white,
          child: Stack(
            children: [
              // ── Couche de base : icône gauche + TextField + bouton droit ──
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Icône gauche
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(scale: anim, child: child)),
                        child: isActive
                            ? InkWell(
                                key: const ValueKey('back'),
                                onTap: onDismiss,
                                borderRadius: BorderRadius.circular(20),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 17,
                                      color: _slate),
                                ),
                              )
                            : Container(
                                key: const ValueKey('search'),
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFEFF6FF),
                                ),
                                child: const Icon(Icons.search_rounded,
                                    size: 17, color: _blue),
                              ),
                      ),
                      const SizedBox(width: 10),
                      // TextField — toujours dans l'arbre
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          cursorColor: _blue,
                          cursorWidth: 1.5,
                          decoration: const InputDecoration(
                            hintText: 'Paris, Évry, Lyon…',
                            hintStyle: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: false,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 4),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: onSubmitted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Bouton droit : spinner / clear / filtre
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(scale: anim, child: child)),
                        child: isSearching
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _blue,
                                ),
                              )
                            : hasQuery
                            ? InkWell(
                                key: const ValueKey('clear'),
                                onTap: onClear,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFF1F5F9),
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      size: 13, color: _slate),
                                ),
                              )
                            : Container(
                                key: const ValueKey('filter'),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _border),
                                ),
                                child: const Icon(Icons.tune_rounded,
                                    size: 15, color: Color(0xFF475569)),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Overlay idle : couvre le TextField, se retire au focus ──
              AnimatedOpacity(
                opacity: isActive ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: isActive,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => focusNode.requestFocus(),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.only(left: 72, right: 16),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Où laver votre linge ?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Autour de vous · N'importe quand",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
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