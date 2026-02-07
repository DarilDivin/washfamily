import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart'; // N'oublie pas l'import !

class OtpScreen extends StatelessWidget {
  final String destination;

  const OtpScreen({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    // On récupère ton thème magique
    final theme = Theme.of(context);

    // --- Configuration du style des cases PIN ---
    // 1. Le style par défaut (Case vide)
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: theme.textTheme.headlineMedium, // Gros chiffres
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Fond blanc
        borderRadius: BorderRadius.circular(12), // Arrondi doux
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ), // Gris clair (Slate 200)
      ),
    );

    // 2. Le style quand la case est sélectionnée (Focus)
    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: theme.primaryColor, width: 2), // Bordure Bleue
    );

    // 3. Le style quand le code est validé (Optionnel)
    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      color: const Color(0xFFF1F5F9), // Fond légèrement gris
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // AppBar minimaliste pour le retour arrière
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => context.pop(), // Retour au login
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Tout prend la largeur
            children: [
              const SizedBox(height: 24),

              // Titre
              Text(
                'Vérification',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Sous-titre avec le numéro (fictif pour l'instant)
              Text(
                'Nous avons envoyé un code à \n$destination',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // --- LE WIDGET PINPUT ---
              Center(
                child: Pinput(
                  length: 4, // Code à 4 chiffres
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  // Validateur (Simulation)
                  validator: (s) {
                    return s == '2222' ? null : 'Code incorrect';
                  },
                  pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                  showCursor: true,
                  onCompleted: (pin) {
                    print('Code entré : $pin');
                    // Si le code est bon, on passe à la suite
                    if (pin == '2222') {
                      context.push('/profile-setup');
                    }
                  },
                ),
              ),

              const SizedBox(height: 48),

              // Bouton "Renvoyer le code"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Vous n'avez rien reçu ? ",
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      print("Renvoyer le code");
                    },
                    child: const Text("Renvoyer"),
                  ),
                ],
              ),

              const Spacer(), // Pousse le bouton vers le bas
              // Bouton Valider (Optionnel car Pinput valide auto, mais rassurant)
              FilledButton(
                onPressed: () {
                  // Action manuelle si besoin
                  context.push('/profile-setup');
                },
                child: const Text("Vérifier"),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
