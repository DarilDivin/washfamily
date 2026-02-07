import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  // Position par défaut (Paris) au cas où le GPS est coupé
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(48.8566, 2.3522),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    // On peut lancer la demande ici, ou après le chargement de la map
    _checkPermissionsAndLocate();
  }

  // --- 📍 LOGIQUE GPS ---
  Future<void> _checkPermissionsAndLocate() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Vérifie si le GPS est allumé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Le GPS est éteint.");
      return;
    }

    // 2. Vérifie la permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Demande la permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Permission refusée");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Permission refusée définitivement");
      return;
    }

    // 3. On a la permission ! On récupère la position
    final position = await Geolocator.getCurrentPosition();
    print("📍 Position trouvée : ${position.latitude}, ${position.longitude}");

    // 4. On déplace la caméra
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15, // Zoom assez proche pour voir les rues
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _defaultPosition,
            // 👇 C'est ça qui affiche le point bleu natif
            myLocationEnabled: true, 
            myLocationButtonEnabled: false, // On cache le bouton moche par défaut
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),

          // BARRE DE RECHERCHE (Code inchangé)
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
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: () { print("Recherche"); },
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
          
          // BOUTON RECENTRER (Optionnel mais pratique)
          Positioned(
            bottom: 100, // Au-dessus de la barre de nav
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: theme.primaryColor,
              onPressed: _checkPermissionsAndLocate, // Relance la localisation
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
      
      // BOTTOM NAV (Code inchangé, purement visuel pour l'instant)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: theme.primaryColor.withOpacity(0.1),
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Explorer',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Réservations',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}