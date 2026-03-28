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

  // ── 10 machines de test réalistes à Évry ──────────────
  static const List<Map<String, dynamic>> _testMachines = [
    {
      'brand': 'Bosch',
      'characteristics': {'capacityKg': 8, 'brand': 'Bosch', 'description': '[Lave-linge] Machine récente (2022), très silencieuse. Disponible 7j/7. Parking gratuit. — Lessive fournie.'},
      'location': {'lat': 48.6290, 'lng': 2.4400, 'address': 'Université d\'Évry, 91000 Évry-Courcouronnes'},
      'pricing': {'pricePerWash': 4.5, 'currency': 'EUR'},
      'media': {'photoUrls': []},
      'status': 'AVAILABLE',
      'stats': {'rating': 4.8, 'reviewCount': 24},
    },
    {
      'brand': 'LG',
      'characteristics': {'capacityKg': 9, 'brand': 'LG', 'description': '[Lave-linge] Grande capacité parfaite pour les familles. Rez-de-chaussée. Accès facile.'},
      'location': {'lat': 48.6310, 'lng': 2.4420, 'address': 'Centre Commercial Évry 2, 91000 Évry'},
      'pricing': {'pricePerWash': 5.0, 'currency': 'EUR'},
      'media': {'photoUrls': []},
      'status': 'AVAILABLE',
      'stats': {'rating': 4.6, 'reviewCount': 12},
    },
    {
      'brand': 'Samsung',
      'characteristics': {'capacityKg': 7, 'brand': 'Samsung', 'description': '[Lave-linge] Lave-linge Samsung WW70TA046AE. Bon état général. Horaires : 9h-21h.'},
      'location': {'lat': 48.6280, 'lng': 2.4380, 'address': 'Gare d\'Évry-Courcouronnes, 91000 Évry'},
      'pricing': {'pricePerWash': 3.5, 'currency': 'EUR'},
      'media': {'photoUrls': []},
      'status': 'AVAILABLE',
      'stats': {'rating': 4.2, 'reviewCount': 8},
    },
    {
      'brand': 'Whirlpool',
      'characteristics': {'capacityKg': 6, 'brand': 'Whirlpool', 'description': '[Sèche-linge] Sèche-linge à condensation, parfait pour finir le lavage. — Lessive fournie.'},
      'location': {'lat': 48.6325, 'lng': 2.4350, 'address': 'Préfecture de l\'Essonne, 91000 Évry'},
      'pricing': {'pricePerWash': 3.0, 'currency': 'EUR'},
      'media': {'photoUrls': []},
      'status': 'AVAILABLE',
      'stats': {'rating': 4.0, 'reviewCount': 5},
    },
    {
      'brand': 'Miele',
      'characteristics': {'capacityKg': 8, 'brand': 'Miele', 'description': '[Lave-linge] Miele W1 — qualité supérieure. Très doux pour les vêtements. Sur RDV.'},
      'location': {'lat': 48.6270, 'lng': 2.4450, 'address': 'Parc des Loges, 91000 Évry'},
      'pricing': {'pricePerWash': 6.0, 'currency': 'EUR'},
      'media': {'photoUrls': []},
      'status': 'AVAILABLE',
      'stats': {'rating': 4.9, 'reviewCount': 31},
    },
    {
      'brand': 'Electrolux',
      'characteristics': {'capacityKg': 7, 'brand': 'Electrolux', 'description': '[Combiné] Lave-linge séchant 2-en-1. Pratique pour les petits espaces.'},
      'location': {'lat': 48.6350, 'lng': 2.4480, 'address': 'Courcouronnes Centre, 91080 Courcouronnes'},
      'pricing': {'pricePerWash': 5.5, 'currency': 'EUR'},
      'media': {'photoUrls': []},
      'status': 'AVAILABLE',
      'stats': {'rating': 4.4, 'reviewCount': 17},
    },
    {
      'brand': 'Candy',
      'characteristics': {'capacityKg': 8, 'brand': 'Candy', 'description': '[Lave-linge] Machine connectée, commandes depuis l\'app. Accessible 24h/24.'},
      'location': {'lat': 48.6250, 'lng': 2.4300, 'address': 'Bras de Fer, 91000 Évry'},
      'pricing': {'pricePerWash': 4.0, 'currency': 'EUR'},
      'media': {'photoUrls': []},
      'status': 'AVAILABLE',
      'stats': {'rating': 4.1, 'reviewCount': 9},
    },
    {
      'brand': 'Hotpoint',
      'characteristics': {'capacityKg': 10, 'brand': 'Hotpoint', 'description': '[Lave-linge] Grande capacité 10kg. Parfait pour couettes et draps. — Lessive fournie.'},
      'location': {'lat': 48.6400, 'lng': 2.4500, 'address': 'Route de Corbeil, 91000 Évry'},
      'pricing': {'pricePerWash': 5.0, 'currency': 'EUR'},
      'media': {'photoUrls': []},
      'status': 'IN_USE',
      'stats': {'rating': 4.5, 'reviewCount': 22},
    },
    {
      'brand': 'AEG',
      'characteristics': {'capacityKg': 8, 'brand': 'AEG', 'description': '[Lave-linge] Machine à laver AEG ProSteam, élimine 99,9% des bactéries.'},
      'location': {'lat': 48.6200, 'lng': 2.4350, 'address': 'Quartier des Épinettes, 91000 Évry'},
      'pricing': {'pricePerWash': 4.8, 'currency': 'EUR'},
      'media': {'photoUrls': []},
      'status': 'AVAILABLE',
      'stats': {'rating': 4.7, 'reviewCount': 14},
    },
    {
      'brand': 'Siemens',
      'characteristics': {'capacityKg': 9, 'brand': 'Siemens', 'description': '[Lave-linge] Siemens iQ500, classe A, très économique en eau et en énergie.'},
      'location': {'lat': 48.6305, 'lng': 2.4500, 'address': 'Bords de Seine, 91000 Évry'},
      'pricing': {'pricePerWash': 4.2, 'currency': 'EUR'},
      'media': {'photoUrls': []},
      'status': 'AVAILABLE',
      'stats': {'rating': 4.3, 'reviewCount': 19},
    },
  ];

  Future<void> _seedMachines() async {
    setState(() {
      _isSeeding = true;
      _log = '⏳ Démarrage du seed...\n';
    });

    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('machines');
    int count = 0;

    // Attribuer les machines à l'utilisateur actuellement connecté
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _log += '❌ Erreur : Vous devez être connecté pour lancer ce script.\n';
        _isSeeding = false;
      });
      return;
    }
    
    final ownerUid = currentUser.uid;
    setState(() => _log += '✅ Propriétaire utilisé : vous-même ($ownerUid)\n');


    for (final machine in _testMachines) {
      try {
        await collection.add({
          ...machine,
          'ownerId': ownerUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        count++;
        setState(() => _log += '✅ Machine ${machine['brand']} ajoutée\n');
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        setState(() => _log += '❌ Erreur pour ${machine['brand']} : $e\n');
      }
    }

    setState(() {
      _isSeeding = false;
      _log += '\n🎉 $count/${_testMachines.length} machines insérées avec succès !';
    });
  }

  Future<void> _clearMachines() async {
    setState(() {
      _isSeeding = true;
      _log = '🗑️ Suppression des machines de test...\n';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('machines')
          .where('ownerId', isEqualTo: currentUser.uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      setState(() {
        _isSeeding = false;
        _log += '✅ ${snapshot.docs.length} machines supprimées.';
      });
    } catch (e) {
      setState(() {
        _isSeeding = false;
        _log += '❌ Erreur : $e';
      });
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
            // Banner d'avertissement
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

            Text('${_testMachines.length} machines de test à Évry',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A))),
            Text('Bosch, LG, Samsung, Miele, AEG, Siemens...',
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13)),

            const SizedBox(height: 24),

            // Bouton Seed
            FilledButton.icon(
              onPressed: _isSeeding ? null : _seedMachines,
              icon: const Icon(Icons.upload_rounded),
              label: Text('Insérer les ${_testMachines.length} machines dans Firestore',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 12),

            // Bouton Clear
            OutlinedButton.icon(
              onPressed: _isSeeding ? null : _clearMachines,
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
              label: Text('Supprimer les machines de test',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFDC2626))),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFDC2626)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 24),

            // Log de progression
            if (_log.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
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
