import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran de développement pour insérer des données de test dans Firestore.
/// ⚠️ À RETIRER AVANT LA MISE EN PRODUCTION
class DevSeedScreen extends StatefulWidget {
  const DevSeedScreen({super.key});

  @override
  State<DevSeedScreen> createState() => _DevSeedScreenState();
}

class _DevSeedScreenState extends State<DevSeedScreen> {
  bool _isSeeding = false;
  String _log = '';

  final _db = FirebaseFirestore.instance;

  // ── Helpers programmes ────────────────────────────────────────────────────
  static Map<String, dynamic> _prog(
    String id,
    String name,
    int temp,
    int duration, {
    bool hasSpin = true,
    int? rpm = 1200,
    bool delicate = false,
  }) =>
      {
        'id': id,
        'name': name,
        'temperatureCelsius': temp,
        'durationMinutes': duration,
        'hasSpin': hasSpin,
        'spinSpeedRpm': hasSpin ? rpm : null,
        'isDelicate': delicate,
      };

  static final _cotton   = _prog('cotton',   'Coton',              40, 90,  rpm: 1200);
  static final _cotton60 = _prog('cotton60', 'Coton 60°',          60, 105, rpm: 1400);
  static final _synth    = _prog('synth',    'Synthétiques',       30, 60,  rpm: 1000);
  static final _delicate = _prog('delicate', 'Délicat',            30, 45,  rpm: 800,  delicate: true);
  static final _quick    = _prog('quick',    'Rapide 30°',         30, 30,  rpm: 800);
  static final _wool     = _prog('wool',     'Laine',              20, 50,  rpm: 800,  delicate: true);
  static final _rinse    = _prog('rinse',    'Rinçage + Essorage', 20, 20,  rpm: 1000);

  // ── Data de test : 4 laveries, chacune avec des machines ─────────────────
  // Structure : { laundry: {...}, machines: [{...}, ...] }
  static List<Map<String, dynamic>> get _seedData => [
    // ─── 1. Laverie du Marché ────────────────────────────────────────────
    {
      'laundry': {
        'name': 'Laverie du Marché',
        'description': 'Laverie conviviale en plein cœur du marché d\'Évry. Accueil chaleureux, machines récentes.',
        'address': 'Place du Marché, 91000 Évry-Courcouronnes',
        'latitude': 48.6290,
        'longitude': 2.4400,
        'openingHours': {
          'lundi': '8h00-20h00', 'mardi': '8h00-20h00', 'mercredi': '8h00-20h00',
          'jeudi': '8h00-20h00', 'vendredi': '8h00-20h00', 'samedi': '9h00-18h00',
        },
        'rating': 4.8,
        'reviewCount': 24,
        'photoUrls': [],
        'isActive': true,
        'service': {
          'offersFolding': true,
          'offersPickup': true,
          'offersDelivery': true,
          'deliveryFee': 3.0,
          'deliveryZoneKm': 5,
        },
      },
      'machines': [
        {
          'nickname': 'Bosch Principale',
          'brand': 'Bosch',
          'model': 'WAN28040',
          'capacityKg': 8,
          'manufactureYear': 2022,
          'isAvailable': true,
          'status': 'AVAILABLE',
          'location': {'lat': 48.6290, 'lng': 2.4400, 'address': 'Place du Marché, 91000 Évry', 'geohash': null},
          'characteristics': {'capacityKg': 8, 'brand': 'Bosch', 'description': '[Lave-linge] Très silencieuse, classe A. — Lessive fournie.'},
          'pricing': {'pricePerWash': 4.5, 'currency': 'EUR'},
          'media': {'photoUrls': []},
          'stats': {'rating': 4.8, 'reviewCount': 24},
          'availability': {'availableDays': [1,2,3,4,5,6], 'startTimeHour': 8, 'endTimeHour': 20},
          'service': {'programs': [_cotton, _synth, _delicate, _quick, _wool]},
        },
        {
          'nickname': 'LG Secondaire',
          'brand': 'LG',
          'model': 'F4WV510S0E',
          'capacityKg': 10,
          'manufactureYear': 2021,
          'isAvailable': true,
          'status': 'AVAILABLE',
          'location': {'lat': 48.6290, 'lng': 2.4400, 'address': 'Place du Marché, 91000 Évry', 'geohash': null},
          'characteristics': {'capacityKg': 10, 'brand': 'LG', 'description': '[Lave-linge] Grande capacité, parfaite pour les couettes.'},
          'pricing': {'pricePerWash': 5.0, 'currency': 'EUR'},
          'media': {'photoUrls': []},
          'stats': {'rating': 4.6, 'reviewCount': 12},
          'availability': {'availableDays': [1,2,3,4,5,6], 'startTimeHour': 8, 'endTimeHour': 20},
          'service': {'programs': [_cotton, _cotton60, _synth, _quick, _rinse]},
        },
      ],
    },

    // ─── 2. WashFamily Centre ────────────────────────────────────────────
    {
      'laundry': {
        'name': 'WashFamily Centre',
        'description': 'Laverie premium au cœur d\'Évry 2. Service collecte et livraison disponible sur toute la zone.',
        'address': 'Centre Commercial Évry 2, 91000 Évry',
        'latitude': 48.6310,
        'longitude': 2.4420,
        'openingHours': {
          'lundi': '9h00-20h00', 'mardi': '9h00-20h00', 'mercredi': '9h00-20h00',
          'jeudi': '9h00-20h00', 'vendredi': '9h00-20h00',
          'samedi': '10h00-19h00', 'dimanche': '10h00-17h00',
        },
        'rating': 4.9,
        'reviewCount': 31,
        'photoUrls': [],
        'isActive': true,
        'service': {
          'offersFolding': true,
          'offersPickup': true,
          'offersDelivery': true,
          'deliveryFee': 5.0,
          'deliveryZoneKm': 10,
        },
      },
      'machines': [
        {
          'nickname': 'Miele Prestige',
          'brand': 'Miele',
          'model': 'W1 WCG 370 WPS',
          'capacityKg': 8,
          'manufactureYear': 2023,
          'isAvailable': true,
          'status': 'AVAILABLE',
          'location': {'lat': 48.6310, 'lng': 2.4420, 'address': 'CC Évry 2, 91000 Évry', 'geohash': null},
          'characteristics': {'capacityKg': 8, 'brand': 'Miele', 'description': '[Lave-linge] Miele W1, très doux pour les vêtements. — Lessive fournie.'},
          'pricing': {'pricePerWash': 6.0, 'currency': 'EUR'},
          'media': {'photoUrls': []},
          'stats': {'rating': 4.9, 'reviewCount': 31},
          'availability': {'availableDays': [1,2,3,4,5,6,7], 'startTimeHour': 9, 'endTimeHour': 20},
          'service': {'programs': [_cotton, _cotton60, _synth, _delicate, _wool, _quick, _rinse]},
        },
        {
          'nickname': 'AEG ProSteam',
          'brand': 'AEG',
          'model': 'L7FBE48SC',
          'capacityKg': 8,
          'manufactureYear': 2022,
          'isAvailable': false,
          'status': 'IN_USE',
          'location': {'lat': 48.6310, 'lng': 2.4420, 'address': 'CC Évry 2, 91000 Évry', 'geohash': null},
          'characteristics': {'capacityKg': 8, 'brand': 'AEG', 'description': '[Lave-linge] AEG ProSteam, élimine 99,9% des bactéries.'},
          'pricing': {'pricePerWash': 4.8, 'currency': 'EUR'},
          'media': {'photoUrls': []},
          'stats': {'rating': 4.7, 'reviewCount': 14},
          'availability': {'availableDays': [1,3,5,6,7], 'startTimeHour': 8, 'endTimeHour': 22},
          'service': {'programs': [_cotton, _cotton60, _synth, _delicate, _wool, _quick]},
        },
        {
          'nickname': 'Siemens Éco',
          'brand': 'Siemens',
          'model': 'iQ500',
          'capacityKg': 9,
          'manufactureYear': 2021,
          'isAvailable': true,
          'status': 'AVAILABLE',
          'location': {'lat': 48.6310, 'lng': 2.4420, 'address': 'CC Évry 2, 91000 Évry', 'geohash': null},
          'characteristics': {'capacityKg': 9, 'brand': 'Siemens', 'description': '[Lave-linge] Classe A, économique en eau et en énergie.'},
          'pricing': {'pricePerWash': 4.2, 'currency': 'EUR'},
          'media': {'photoUrls': []},
          'stats': {'rating': 4.3, 'reviewCount': 19},
          'availability': {'availableDays': [1,2,3,4,5], 'startTimeHour': 8, 'endTimeHour': 20},
          'service': {'programs': [_cotton, _synth, _delicate, _quick, _rinse]},
        },
      ],
    },

    // ─── 3. EcoWash Gare ─────────────────────────────────────────────────
    {
      'laundry': {
        'name': 'EcoWash Gare',
        'description': 'Laverie proche de la gare d\'Évry. Tarifs attractifs, horaires étendus.',
        'address': 'Gare d\'Évry-Courcouronnes, 91000 Évry',
        'latitude': 48.6280,
        'longitude': 2.4380,
        'openingHours': {
          'lundi': '7h00-22h00', 'mardi': '7h00-22h00', 'mercredi': '7h00-22h00',
          'jeudi': '7h00-22h00', 'vendredi': '7h00-22h00', 'samedi': '7h00-22h00',
        },
        'rating': 4.2,
        'reviewCount': 8,
        'photoUrls': [],
        'isActive': true,
        'service': {
          'offersFolding': false,
          'offersPickup': false,
          'offersDelivery': false,
          'deliveryFee': null,
          'deliveryZoneKm': null,
        },
      },
      'machines': [
        {
          'nickname': 'Samsung 7kg',
          'brand': 'Samsung',
          'model': 'WW70TA046AE',
          'capacityKg': 7,
          'manufactureYear': 2020,
          'isAvailable': true,
          'status': 'AVAILABLE',
          'location': {'lat': 48.6280, 'lng': 2.4380, 'address': 'Gare d\'Évry-Courcouronnes, 91000 Évry', 'geohash': null},
          'characteristics': {'capacityKg': 7, 'brand': 'Samsung', 'description': '[Lave-linge] Samsung WW70TA046AE, bon état général.'},
          'pricing': {'pricePerWash': 3.5, 'currency': 'EUR'},
          'media': {'photoUrls': []},
          'stats': {'rating': 4.2, 'reviewCount': 8},
          'availability': {'availableDays': [1,2,3,4,5,6], 'startTimeHour': 7, 'endTimeHour': 22},
          'service': {'programs': [_cotton, _synth, _quick]},
        },
        {
          'nickname': 'Candy Connectée',
          'brand': 'Candy',
          'model': 'CS4 1272D3',
          'capacityKg': 8,
          'manufactureYear': 2021,
          'isAvailable': true,
          'status': 'AVAILABLE',
          'location': {'lat': 48.6280, 'lng': 2.4380, 'address': 'Gare d\'Évry-Courcouronnes, 91000 Évry', 'geohash': null},
          'characteristics': {'capacityKg': 8, 'brand': 'Candy', 'description': '[Lave-linge] Machine connectée, accessible 7j/7.'},
          'pricing': {'pricePerWash': 4.0, 'currency': 'EUR'},
          'media': {'photoUrls': []},
          'stats': {'rating': 4.1, 'reviewCount': 9},
          'availability': {'availableDays': [1,2,3,4,5,6,7], 'startTimeHour': 6, 'endTimeHour': 23},
          'service': {'programs': [_cotton, _synth, _quick]},
        },
      ],
    },

    // ─── 4. Laverie des Épinettes ─────────────────────────────────────────
    {
      'laundry': {
        'name': 'Laverie des Épinettes',
        'description': 'Laverie de quartier avec service pliage et collecte. Idéale pour les familles.',
        'address': 'Quartier des Épinettes, 91000 Évry',
        'latitude': 48.6200,
        'longitude': 2.4350,
        'openingHours': {
          'lundi': '8h00-21h00', 'mercredi': '8h00-21h00',
          'vendredi': '8h00-21h00', 'samedi': '9h00-19h00', 'dimanche': '10h00-17h00',
        },
        'rating': 4.5,
        'reviewCount': 17,
        'photoUrls': [],
        'isActive': true,
        'service': {
          'offersFolding': true,
          'offersPickup': true,
          'offersDelivery': false,
          'deliveryFee': null,
          'deliveryZoneKm': null,
        },
      },
      'machines': [
        {
          'nickname': 'Hotpoint 10kg',
          'brand': 'Hotpoint',
          'model': 'NSWM 1044C W',
          'capacityKg': 10,
          'manufactureYear': 2021,
          'isAvailable': true,
          'status': 'AVAILABLE',
          'location': {'lat': 48.6200, 'lng': 2.4350, 'address': 'Quartier des Épinettes, 91000 Évry', 'geohash': null},
          'characteristics': {'capacityKg': 10, 'brand': 'Hotpoint', 'description': '[Lave-linge] Grande capacité, parfait pour couettes et draps. — Lessive fournie.'},
          'pricing': {'pricePerWash': 5.0, 'currency': 'EUR'},
          'media': {'photoUrls': []},
          'stats': {'rating': 4.5, 'reviewCount': 22},
          'availability': {'availableDays': [2,3,4,5,6], 'startTimeHour': 9, 'endTimeHour': 21},
          'service': {'programs': [_cotton, _cotton60, _synth, _quick, _rinse]},
        },
        {
          'nickname': 'Electrolux Combiné',
          'brand': 'Electrolux',
          'model': 'EW7W3684IW',
          'capacityKg': 7,
          'manufactureYear': 2020,
          'isAvailable': true,
          'status': 'AVAILABLE',
          'location': {'lat': 48.6200, 'lng': 2.4350, 'address': 'Quartier des Épinettes, 91000 Évry', 'geohash': null},
          'characteristics': {'capacityKg': 7, 'brand': 'Electrolux', 'description': '[Combiné] Lave-linge séchant 2-en-1, pratique pour les petits espaces.'},
          'pricing': {'pricePerWash': 5.5, 'currency': 'EUR'},
          'media': {'photoUrls': []},
          'stats': {'rating': 4.4, 'reviewCount': 17},
          'availability': {'availableDays': [1,2,3,4,5,6,7], 'startTimeHour': 8, 'endTimeHour': 20},
          'service': {'programs': [_cotton, _synth, _delicate, _quick]},
        },
      ],
    },
  ];

  // ── Seed laveries + machines ───────────────────────────────────────────────
  Future<void> _seedLaundries() async {
    setState(() { _isSeeding = true; _log = '⏳ Seed laveries...\n'; });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() { _log += '❌ Vous devez être connecté.\n'; _isSeeding = false; });
      return;
    }

    int laundryCount = 0;
    int machineCount = 0;

    for (final entry in _seedData) {
      try {
        final laundryData = Map<String, dynamic>.from(entry['laundry'] as Map);
        laundryData['ownerId'] = uid;
        laundryData['createdAt'] = FieldValue.serverTimestamp();

        final laundryRef = await _db.collection('laundries').add(laundryData);
        final laundryId = laundryRef.id;
        laundryCount++;
        setState(() => _log += '✅ Laverie : ${laundryData['name']} ($laundryId)\n');

        final machines = entry['machines'] as List<Map<String, dynamic>>;
        for (final machine in machines) {
          final machineData = Map<String, dynamic>.from(machine);
          machineData['ownerId'] = uid;
          machineData['laundryId'] = laundryId;
          machineData['createdAt'] = FieldValue.serverTimestamp();

          await laundryRef.collection('machines').add(machineData);
          machineCount++;
          setState(() => _log += '   🔧 ${machineData['nickname']} ajoutée\n');
          await Future.delayed(const Duration(milliseconds: 80));
        }
      } catch (e) {
        setState(() => _log += '❌ Erreur : $e\n');
      }
    }

    setState(() {
      _isSeeding = false;
      _log += '\n🎉 $laundryCount laveries · $machineCount machines insérées !';
    });
  }

  // ── Seed réservations ──────────────────────────────────────────────────────
  Future<void> _seedReservations() async {
    setState(() { _isSeeding = true; _log = '⏳ Seed réservations...\n'; });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() { _log += '❌ Vous devez être connecté.\n'; _isSeeding = false; });
      return;
    }

    // Récupère la première laverie de l'utilisateur
    final laundrySnap = await _db
        .collection('laundries')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();

    if (laundrySnap.docs.isEmpty) {
      setState(() { _log += '❌ Aucune laverie trouvée. Lance le seed laveries d\'abord.\n'; _isSeeding = false; });
      return;
    }

    final laundryDoc = laundrySnap.docs.first;
    final laundryId = laundryDoc.id;
    final laundryName = laundryDoc.data()['name'] as String? ?? 'Laverie';
    setState(() => _log += '🏠 Laverie : $laundryName ($laundryId)\n');

    // Récupère la première machine de cette laverie
    final machineSnap = await laundryDoc.reference
        .collection('machines')
        .limit(1)
        .get();

    if (machineSnap.docs.isEmpty) {
      setState(() { _log += '❌ Aucune machine dans cette laverie.\n'; _isSeeding = false; });
      return;
    }

    final machineDoc = machineSnap.docs.first;
    final machineId = machineDoc.id;
    final machineData = machineDoc.data();
    final machineBrand = machineData['brand'] as String? ?? 'Machine';
    final machineAddress = machineData['location']?['address'] as String?;
    final programs = (machineData['service']?['programs'] as List?) ?? [];
    final firstProgramId = programs.isNotEmpty ? programs.first['id'] : null;
    final ownerId = machineData['ownerId'] as String? ?? uid;

    setState(() => _log += '🔧 Machine : $machineBrand ($machineId)\n');

    final now = DateTime.now();
    final col = _db.collection('reservations');

    final reservations = <Map<String, dynamic>>[
      _reservation('PENDING',      machineId, laundryId, machineBrand, machineAddress, ownerId, uid, firstProgramId, now,
        start: now.add(const Duration(days: 2, hours: 10)),
        end:   now.add(const Duration(days: 2, hours: 12)),
        price: 9.0, folding: false, pickup: 'DROP_OFF', instructions: 'Attention, linge délicat — éviter les 60°C.',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      _reservation('CONFIRMED',    machineId, laundryId, machineBrand, machineAddress, ownerId, uid, firstProgramId, now,
        start: now.add(const Duration(days: 1, hours: 14)),
        end:   now.add(const Duration(days: 1, hours: 16)),
        price: 13.0, folding: true, pickup: 'COLLECTED', delivery: true,
        deliveryAddress: '15 rue Victor Hugo, 91000 Évry',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      _reservation('PICKED_UP',    machineId, laundryId, machineBrand, machineAddress, ownerId, uid, firstProgramId, now,
        start: now.subtract(const Duration(hours: 2)),
        end:   now.add(const Duration(hours: 2)),
        price: 4.5, pickup: 'DROP_OFF',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      _reservation('IN_PROGRESS',  machineId, laundryId, machineBrand, machineAddress, ownerId, uid, firstProgramId, now,
        start: now.subtract(const Duration(hours: 1)),
        end:   now.add(const Duration(hours: 1)),
        price: 4.5, pickup: 'DROP_OFF',
        createdAt: now.subtract(const Duration(days: 2)),
        reminder: true,
      ),
      _reservation('READY',        machineId, laundryId, machineBrand, machineAddress, ownerId, uid, firstProgramId, now,
        start: now.subtract(const Duration(hours: 3)),
        end:   now.subtract(const Duration(hours: 1)),
        price: 9.0, folding: true, pickup: 'DROP_OFF',
        instructions: 'Tache de café sur la chemise bleue.',
        createdAt: now.subtract(const Duration(days: 2)), reminder: true,
      ),
      _reservation('COMPLETED',    machineId, laundryId, machineBrand, machineAddress, ownerId, uid, firstProgramId, now,
        start: now.subtract(const Duration(days: 5, hours: 10)),
        end:   now.subtract(const Duration(days: 5, hours: 8)),
        price: 9.0, pickup: 'DROP_OFF',
        createdAt: now.subtract(const Duration(days: 6)), reminder: true,
      ),
      _reservation('CANCELLED',    machineId, laundryId, machineBrand, machineAddress, ownerId, uid, firstProgramId, now,
        start: now.subtract(const Duration(days: 3, hours: 10)),
        end:   now.subtract(const Duration(days: 3, hours: 8)),
        price: 4.5, pickup: 'DROP_OFF',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    ];

    int count = 0;
    for (final r in reservations) {
      try {
        await col.add(r);
        count++;
        setState(() => _log += '✅ Réservation ${r['status']} créée\n');
        await Future.delayed(const Duration(milliseconds: 80));
      } catch (e) {
        setState(() => _log += '❌ ${r['status']} : $e\n');
      }
    }

    setState(() {
      _isSeeding = false;
      _log += '\n🎉 $count/${reservations.length} réservations créées !';
    });
  }

  static Map<String, dynamic> _reservation(
    String status,
    String machineId,
    String laundryId,
    String machineBrand,
    String? machineAddress,
    String ownerId,
    String renterId,
    String? programId,
    DateTime now, {
    required DateTime start,
    required DateTime end,
    required double price,
    bool folding = false,
    bool delivery = false,
    String pickup = 'DROP_OFF',
    String? deliveryAddress,
    String? instructions,
    required DateTime createdAt,
    bool reminder = false,
  }) =>
      {
        'machineId': machineId,
        'laundryId': laundryId,
        'machineBrand': machineBrand,
        'machineAddress': machineAddress,
        'ownerId': ownerId,
        'renterId': renterId,
        'startTime': Timestamp.fromDate(start),
        'endTime': Timestamp.fromDate(end),
        'totalPrice': price,
        'status': status,
        'renterNote': null,
        'createdAt': Timestamp.fromDate(createdAt),
        'reminderSent': reminder,
        'hasBeenReviewed': false,
        'pickupMethod': pickup,
        'requestedFolding': folding,
        'requestedDelivery': delivery,
        'deliveryAddress': deliveryAddress,
        'washInstructions': instructions,
        'selectedProgramId': programId,
      };

  // ── Clear laveries (+ machines en sous-collection) ────────────────────────
  Future<void> _clearLaundries() async {
    setState(() { _isSeeding = true; _log = '🗑️ Suppression des laveries...\n'; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final snap = await _db.collection('laundries')
          .where('ownerId', isEqualTo: uid).get();

      for (final doc in snap.docs) {
        // Supprimer les machines de la sous-collection
        final machines = await doc.reference.collection('machines').get();
        final batch = _db.batch();
        for (final m in machines.docs) { batch.delete(m.reference); }
        batch.delete(doc.reference);
        await batch.commit();
        setState(() => _log += '✅ ${doc.data()['name']} supprimée (${machines.docs.length} machines)\n');
      }

      setState(() { _isSeeding = false; _log += '\n✅ ${snap.docs.length} laveries supprimées.'; });
    } catch (e) {
      setState(() { _isSeeding = false; _log += '❌ Erreur : $e'; });
    }
  }

  // ── Clear réservations ─────────────────────────────────────────────────────
  Future<void> _clearReservations() async {
    setState(() { _isSeeding = true; _log = '🗑️ Suppression des réservations...\n'; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final snap = await _db.collection('reservations')
          .where('ownerId', isEqualTo: uid).get();

      final batch = _db.batch();
      for (final doc in snap.docs) { batch.delete(doc.reference); }
      await batch.commit();

      setState(() { _isSeeding = false; _log += '✅ ${snap.docs.length} réservations supprimées.'; });
    } catch (e) {
      setState(() { _isSeeding = false; _log += '❌ Erreur : $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          '🔧 Dev — Seed Firestore',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Banner ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC00)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Outil de développement uniquement. Supprimer avant la mise en production.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF92400E), fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Section Laveries ────────────────────────────────────
            _SectionTitle('🏠 Laveries + Machines (${_seedData.length} laveries, ${_seedData.fold(0, (s, e) => s + (e['machines'] as List).length)} machines à Évry)'),
            Text(
              'Données sous laundries/{id}/machines — services au niveau laverie, programmes au niveau machine',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSeeding ? null : _seedLaundries,
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: Text('Insérer laveries + machines', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _ClearButton(onPressed: _isSeeding ? null : _clearLaundries, label: 'Supprimer'),
            ]),

            const SizedBox(height: 20),

            // ── Section Réservations ────────────────────────────────
            _SectionTitle('📋 Réservations (7 statuts : PENDING → CANCELLED)'),
            Text(
              '⚠ Lance le seed laveries en premier. Utilise la 1ère laverie + 1ère machine de ton compte.',
              style: GoogleFonts.inter(color: const Color(0xFFD97706), fontSize: 11),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSeeding ? null : _seedReservations,
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text('Insérer les réservations', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _ClearButton(onPressed: _isSeeding ? null : _clearReservations, label: 'Supprimer'),
            ]),

            const SizedBox(height: 20),

            // ── Log ─────────────────────────────────────────────────
            if (_log.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _log,
                      style: GoogleFonts.sourceCodePro(color: const Color(0xFF4ADE80), fontSize: 12),
                    ),
                  ),
                ),
              ),

            if (_isSeeding)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A)),
        ),
      );
}

class _ClearButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  const _ClearButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
        label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFDC2626), fontSize: 13)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          side: const BorderSide(color: Color(0xFFDC2626)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
}
