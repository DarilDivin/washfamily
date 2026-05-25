import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../laundries/data/providers/laundry_providers.dart';
import '../../../laundries/domain/models/laundry_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/nearby_machines_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  Set<Marker> _markers = {};
  List<LaundryModel> _laundries = [];
  double? _userLat;
  double? _userLng;
  LaundryModel? _selectedLaundry;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  final FocusNode _searchFocus = FocusNode();
  bool _isSearchActive = false;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(48.8566, 2.3522),
    zoom: 14.4746,
  );

  StreamSubscription? _laundrySub;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLocate();
    _searchController.addListener(
        () => setState(() => _searchQuery = _searchController.text.trim()));
    _searchFocus.addListener(
        () => setState(() => _isSearchActive = _searchFocus.hasFocus));
  }

  @override
  void dispose() {
    _laundrySub?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndLocate() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });
    }

    final ctrl = await _controller.future;
    ctrl.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 15)));
  }

  void _onLaundriesLoaded(List<LaundryModel> laundries) {
    if (!mounted) return;
    setState(() => _laundries = laundries);
    _rebuildMarkers();
  }

  final Map<String, BitmapDescriptor> _markerCache = {};

  Future<BitmapDescriptor> _buildMarkerBitmap(LaundryModel laundry,
      {bool selected = false}) async {
    final key = '${laundry.id}_${selected ? 's' : 'n'}';
    if (_markerCache.containsKey(key)) return _markerCache[key]!;

    const double dpr = 3.0;
    const double size = 48.0;
    const double iconSize = 16.0;

    final bgColor = selected ? AppColors.surface : AppColors.primary;
    final iconColor = selected ? AppColors.primary : Colors.white;

    final recorder = ui.PictureRecorder();
    final canvas =
        Canvas(recorder, Rect.fromLTWH(0, 0, size * dpr, size * dpr));
    canvas.scale(dpr);

    const cx = size / 2;
    const cy = size / 2;
    const radius = size / 2;

    canvas.drawCircle(const Offset(cx, cy), radius, Paint()..color = bgColor);
    canvas.drawCircle(
      const Offset(cx, cy),
      radius - 1,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.0 : 1.0,
    );

    final icon = PhosphorIconsRegular.washingMachine;
    final fontFamily = icon.fontPackage != null
        ? 'packages/${icon.fontPackage}/${icon.fontFamily}'
        : icon.fontFamily;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          inherit: false,
          fontSize: iconSize,
          fontFamily: fontFamily,
          color: iconColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    final img = await recorder
        .endRecording()
        .toImage((size * dpr).round(), (size * dpr).round());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final desc = BitmapDescriptor.bytes(bytes!.buffer.asUint8List(),
        width: size, height: size);
    _markerCache[key] = desc;
    return desc;
  }

  double? _distanceTo(LaundryModel l) {
    if (_userLat == null || _userLng == null) return null;
    const r = 6371.0;
    final dLat = (l.latitude - _userLat!) * math.pi / 180;
    final dLng = (l.longitude - _userLng!) * math.pi / 180;
    return r * math.sqrt(dLat * dLat + dLng * dLng);
  }

  Future<void> _rebuildMarkers() async {
    final markers = <Marker>[];
    for (final l in _laundries) {
      final sel = _selectedLaundry?.id == l.id;
      final icon = await _buildMarkerBitmap(l, selected: sel);
      markers.add(Marker(
        markerId: MarkerId(l.id),
        position: LatLng(l.latitude, l.longitude),
        icon: icon,
        anchor: const Offset(0.5, 1.0),
        zIndexInt: sel ? 1 : 0,
        onTap: () => _selectLaundry(l),
      ));
    }
    if (mounted) setState(() => _markers = markers.toSet());
  }

  void _selectLaundry(LaundryModel l) {
    setState(() => _selectedLaundry = l);
    _markerCache.clear();
    _rebuildMarkers();
  }

  void _deselectLaundry() {
    if (_selectedLaundry == null) return;
    setState(() => _selectedLaundry = null);
    _markerCache.clear();
    _rebuildMarkers();
  }

  Future<void> _searchLocation(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final locs = await locationFromAddress(q);
      if (locs.isEmpty || !mounted) return;
      final loc = locs.first;
      final ctrl = await _controller.future;
      await ctrl.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(loc.latitude, loc.longitude), zoom: 13)));
      setState(() {
        _userLat = loc.latitude;
        _userLng = loc.longitude;
      });
      _searchFocus.unfocus();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Adresse introuvable : $q'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    // Écoute du provider de laveries
    ref.listen<AsyncValue<List<LaundryModel>>>(
      activeLaundriesProvider,
      (_, next) {
        if (next.hasValue) _onLaundriesLoaded(next.value!);
      },
    );

    return Scaffold(
      body: Stack(
        children: [
          // ── Couche 1 : Google Map ─────────────────────────────────
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
              _deselectLaundry();
            },
            onMapCreated: (ctrl) {
              if (!_controller.isCompleted) _controller.complete(ctrl);
            },
          ),

          // ── Couche 2 : BottomSheet ancré ─────────────────────────
          NearbyMachinesSheet(
            laundries: _laundries,
            userLat: _userLat,
            userLng: _userLng,
          ),

          // ── Couche 3 : Barre de recherche + cloche notifications ──
          Positioned(
            top: topPadding + AppSpacing.md,
            left: AppSpacing.lg,
            right: AppSpacing.lg + 56,
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

          // ── Cloche notifications ──────────────────────────────────
          Positioned(
            top: topPadding + AppSpacing.md + 8,
            right: AppSpacing.lg,
            child: const _NotifBell(),
          ),

          // ── Couche 4 : Preview card laverie sélectionnée ──────────
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: 300,
            child: AnimatedSlide(
              offset: _selectedLaundry != null
                  ? Offset.zero
                  : const Offset(0, 1.6),
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _selectedLaundry != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: IgnorePointer(
                  ignoring: _selectedLaundry == null,
                  child: _selectedLaundry != null
                      ? _LaundryPreviewCard(
                          laundry: _selectedLaundry!,
                          distanceKm: _distanceTo(_selectedLaundry!),
                          onClose: _deselectLaundry,
                        )
                      : const SizedBox(height: 100),
                ),
              ),
            ),
          ),

          // ── Couche 5 : Bouton recentrer ───────────────────────────
          Positioned(
            bottom: 320,
            right: AppSpacing.xl,
            child: _LocationButton(onTap: _checkPermissionsAndLocate),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LocationButton
// ─────────────────────────────────────────────────────────────────────────────

class _LocationButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LocationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: PhosphorIcon(PhosphorIconsRegular.crosshair,
                size: 20, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LaundryPreviewCard — preview au tap d'un marqueur
// ─────────────────────────────────────────────────────────────────────────────

class _LaundryPreviewCard extends StatelessWidget {
  final LaundryModel laundry;
  final double? distanceKm;
  final VoidCallback onClose;

  const _LaundryPreviewCard(
      {required this.laundry, required this.onClose, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => context.push('/laundry/${laundry.id}'),
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Photo / placeholder
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSpacing.radiusXl)),
              child: SizedBox(
                width: 96,
                height: 104,
                child: laundry.photoUrls.isNotEmpty
                    ? Image.network(laundry.photoUrls.first,
                        fit: BoxFit.cover)
                    : Container(
                        color: AppColors.inputBackground,
                        child: const Center(
                          child: PhosphorIcon(
                              PhosphorIconsRegular.washingMachine,
                              size: 36,
                              color: AppColors.textSecondary),
                        ),
                      ),
              ),
            ),

            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(laundry.name,
                              style: tt.titleSmall,
                              overflow: TextOverflow.ellipsis),
                        ),
                        InkWell(
                          onTap: onClose,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.inputBackground,
                            ),
                            child: const PhosphorIcon(PhosphorIconsRegular.x,
                                size: 14, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(children: [
                      const PhosphorIcon(PhosphorIconsRegular.mapPin,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          laundry.address,
                          style: tt.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    const Spacer(),
                    Row(
                      children: [
                        if (laundry.reviewCount > 0) ...[
                          const PhosphorIcon(PhosphorIconsFill.star,
                              size: 12, color: AppColors.starActive),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${laundry.rating.toStringAsFixed(1)} (${laundry.reviewCount})',
                            style: tt.labelSmall
                                ?.copyWith(color: AppColors.textPrimary),
                          ),
                          if (distanceKm != null)
                            Text(' · ',
                                style: tt.labelSmall?.copyWith(
                                    color: AppColors.textSecondary)),
                        ],
                        if (distanceKm != null)
                          Text(
                            distanceKm! < 1
                                ? '${(distanceKm! * 1000).toStringAsFixed(0)} m'
                                : '${distanceKm!.toStringAsFixed(1)} km',
                            style: tt.bodySmall,
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull),
                          ),
                          child: Text('Voir',
                              style: tt.labelSmall?.copyWith(
                                  color: AppColors.surface,
                                  fontWeight: FontWeight.w700)),
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
// _SearchBar — identique à l'originale
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

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Material(
          color: AppColors.surface,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(scale: anim, child: child)),
                        child: isActive
                            ? InkWell(
                                key: const ValueKey('back'),
                                onTap: onDismiss,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(AppSpacing.sm),
                                  child: const PhosphorIcon(
                                      PhosphorIconsRegular.arrowLeft,
                                      size: 18,
                                      color: AppColors.textSecondary),
                                ),
                              )
                            : Container(
                                key: const ValueKey('search'),
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.completedBg,
                                ),
                                child: const Center(
                                  child: PhosphorIcon(
                                      PhosphorIconsRegular.magnifyingGlass,
                                      size: 17,
                                      color: AppColors.primary),
                                ),
                              ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          cursorColor: AppColors.primary,
                          cursorWidth: 1.5,
                          decoration: InputDecoration(
                            hintText: 'Paris, Évry, Lyon…',
                            hintStyle: tt.bodyLarge
                                ?.copyWith(color: AppColors.border),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: false,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 4),
                          ),
                          style: tt.bodyLarge
                              ?.copyWith(color: AppColors.textPrimary),
                          textInputAction: TextInputAction.search,
                          onSubmitted: onSubmitted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
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
                                    color: AppColors.primary),
                              )
                            : hasQuery
                                ? InkWell(
                                    key: const ValueKey('clear'),
                                    onTap: onClear,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusFull),
                                    child: Container(
                                      padding:
                                          const EdgeInsets.all(AppSpacing.sm),
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.inputBackground),
                                      child: const PhosphorIcon(
                                          PhosphorIconsRegular.x,
                                          size: 13,
                                          color: AppColors.textSecondary),
                                    ),
                                  )
                                : Container(
                                    key: const ValueKey('filter'),
                                    padding:
                                        const EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: const PhosphorIcon(
                                        PhosphorIconsRegular.slidersHorizontal,
                                        size: 15,
                                        color: AppColors.textSecondary),
                                  ),
                      ),
                    ],
                  ),
                ),
              ),

              // Overlay idle
              AnimatedOpacity(
                opacity: isActive ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: isActive,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => focusNode.requestFocus(),
                    child: Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.only(left: 72, right: 16),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Où laver votre linge ?',
                              style: tt.titleSmall),
                          const SizedBox(height: 2),
                          Text("Autour de vous · N'importe quand",
                              style: tt.bodySmall),
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

// ─────────────────────────────────────────────────────────────────────────────
// _NotifBell
// ─────────────────────────────────────────────────────────────────────────────

class _NotifBell extends StatelessWidget {
  const _NotifBell();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
        if (user == null) return const Stream.empty();
        return FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .where('isRead', isEqualTo: false)
            .snapshots()
            .map((snap) {
          if (snap.docs.isEmpty) return null;
          return snap.docs.length > 9 ? '9+' : '${snap.docs.length}';
        });
      }),
      builder: (context, snapshot) {
        final badge = snapshot.data;
        final tt = Theme.of(context).textTheme;
        return GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: PhosphorIcon(
                    badge != null
                        ? PhosphorIconsFill.bell
                        : PhosphorIconsRegular.bell,
                    size: 22,
                    color: badge != null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (badge != null)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badge,
                      style: tt.labelSmall
                          ?.copyWith(color: Colors.white, height: 1),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
