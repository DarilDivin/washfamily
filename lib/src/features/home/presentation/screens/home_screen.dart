import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(48.8566, 2.3522),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLocate();
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

  Future<void> _loadMachines(double lat, double lng) async {
    try {
      final machines = await _machineRepository.getAllMachines();

      final newMarkers = machines.map((machine) {
        return Marker(
          markerId: MarkerId(machine.id),
          position: LatLng(machine.latitude, machine.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            machine.status == 'AVAILABLE'
                ? BitmapDescriptor.hueBlue
                : BitmapDescriptor.hueRed,
          ),
        );
      }).toSet();

      if (mounted) {
        setState(() {
          _machines = machines;
          _markers = newMarkers;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement machines: $e');
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
            padding: const EdgeInsets.only(bottom: 280), // Espace pour le sheet
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

          // ── Couche 3 : Barre de recherche (au-dessus du sheet) ──
          Positioned(
            top: topPadding + 16,
            left: 20,
            right: 20,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: theme.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Où laver votre linge ?",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "Autour de vous · N'importe quand",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: const Icon(Icons.tune, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Couche 4 : Bouton recentrer ─────────────────────────
          Positioned(
            bottom: 320, // Au-dessus du sheet mi-hauteur
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