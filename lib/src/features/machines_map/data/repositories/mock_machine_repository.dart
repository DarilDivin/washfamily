import 'package:flutter/foundation.dart';
import '../../domain/models/machine_model.dart';
import 'dart:math';

/// Repository fictif (bouchon) pour simuler des données Firestore.
/// Quand Firestore sera prêt, on crée un FirestoreMachineRepository
/// avec la même interface → HomeScreen n'aura rien à changer !
class MockMachineRepository {
  Future<List<MachineModel>> getMachinesAroundCurrentLocation(
    double lat,
    double lng, {
    double radiusKm = 5.0,
  }) async {
    debugPrint('🐾 MockRepo: chargement pour lat=$lat, lng=$lng');
    final random = Random();

    // Génère 10 fausses machines autour du point lat/lng
    final machines = List.generate(10, (index) {
      // Décalage aléatoire ≈ ±2km
      final latOffset = (random.nextDouble() - 0.5) * 0.04;
      final lngOffset = (random.nextDouble() - 0.5) * 0.04;

      return MachineModel(
        id: 'machine_mock_$index',
        ownerId: 'owner_$index',
        latitude: lat + latOffset,
        longitude: lng + lngOffset,
        address: 'Adresse fictive n°$index',
        capacityKg: [5, 7, 9, 10, 12][random.nextInt(5)],
        brand: ['Samsung', 'LG', 'Bosch', 'Whirlpool', 'Beko'][random.nextInt(5)],
        description:
            'Machine récente, très silencieuse. Idéal pour votre linge quotidien.',
        pricePerWash: 3.0 + random.nextInt(6) * 0.5,
        photoUrls: [
          'https://images.unsplash.com/photo-1626806787461-102c1bfaaea1?auto=format&fit=crop&q=80&w=400',
        ],
        status: random.nextDouble() > 0.8 ? 'IN_USE' : 'AVAILABLE',
        rating: double.parse((4.0 + random.nextDouble()).toStringAsFixed(1)),
        reviewCount: random.nextInt(50) + 1,
      );
    });

    debugPrint('✅ MockRepo: ${machines.length} machines générées');
    return machines;
  }
}
