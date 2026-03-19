import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:washfamily/src/features/authentication/data/services/auth_service.dart'; // N'oublie pas l'import !

class OtpScreen extends StatefulWidget {
  final String destination;

  const OtpScreen({super.key, required this.destination});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  bool _isLoading = false;

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
                'Nous avons envoyé un code à \n${widget.destination}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // --- LE WIDGET PINPUT ---
              Center(
                child: Pinput(
                  length:
                      6, // ⚠️ Attention : Firebase envoie des codes à 6 chiffres ! (Change ton 4 en 6)
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  showCursor: true,
                  onCompleted: (pin) async {
                    setState(() => _isLoading = true);

                    // 1. On interroge Firebase
                    final isSuccess = await AuthService().verifyOTP(pin);

                    setState(() => _isLoading = false);

                    // 2. On vérifie le résultat
                    if (isSuccess) {
                      print("Authentification réussie !");
                      if (mounted) context.go('/profile-setup'); // Connexion validée
                    } else {
                      // Afficher une erreur visuelle
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Code incorrect ou expiré."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
                      debugPrint("Renvoyer le code");
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
