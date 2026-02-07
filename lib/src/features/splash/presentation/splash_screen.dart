import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // C'est ici qu'on décide quoi faire après le chargement.
    // Pour l'instant, on simule une attente de 2 secondes, puis on va au Login.
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      // GoRouter : On remplace l'écran actuel par /login
      // On utilise 'go' et pas 'push' pour ne pas pouvoir revenir au splash avec "Retour"
      context.go('/login'); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. La couleur de fond "Ghost White" de ta charte
      backgroundColor: const Color(0xFFF8FAFC), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 2. Le Logo (Ici une icône pour commencer, plus tard ton image)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, // Fond blanc pur
                shape: BoxShape.circle, // Forme ronde
                border: Border.all(
                  color: const Color(0xFFE2E8F0), // Bordure fine
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.local_laundry_service_outlined, // Icône temporaire
                size: 60,
                color: Color(0xFF2563EB), // Bleu Royal
              ),
            ),
            
            const SizedBox(height: 24), // Espacement

            // 3. Le Titre de l'app
            Text(
              'WashFamily',
              style: GoogleFonts.inter( // Police Inter ou Satoshi
                fontSize: 28,
                fontWeight: FontWeight.bold, // Titre gras
                color: const Color(0xFF0F172A), // Couleur foncée "Slate"
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 48), // Grand espace avant le loader

            // 4. L'indicateur de chargement discret
            const CircularProgressIndicator(
              color: Color(0xFF2563EB), // Bleu Royal
              strokeWidth: 3, // Trait fin élégant
            ),
          ],
        ),
      ),
    );
  }
}