import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:washfamily/src/features/authentication/data/services/auth_service.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  // Contrôleur pour récupérer ce que l'utilisateur tape
  final TextEditingController _phoneController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // On écoute le changement de texte pour activer le bouton seulement si on a 9 chiffres
    _phoneController.addListener(() {
      setState(() {
        _isButtonEnabled = _phoneController.text.length >= 9;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Le resizeToAvoidBottomInset est true par défaut, c'est ce qui fait remonter l'écran
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      // 👇 LA SOLUTION MAGIQUE : CustomScrollView
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false, // Important pour que le Spacer fonctionne
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quel est votre numéro ?",
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Nous vous enverrons un code pour vérifier votre compte.",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- CHAMP TÉLÉPHONE ---
                  Container(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 4,
                      top: 4,
                      bottom: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "🇫🇷 +33",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            autofocus: true,
                            keyboardType: TextInputType.phone,
                            style: theme.textTheme.titleMedium?.copyWith(),
                            decoration: const InputDecoration(
                              hintText: "6 12 34 56 78",
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 👇 Ce Spacer va pousser le bouton en bas quand il y a de la place
                  // et rétrécir à 0 quand le clavier est là.
                  const Spacer(),

                  // --- BOUTON D'ACTION ---
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_isButtonEnabled && !_isLoading)
                          ? () {
                              // 1. On lance le chargement
                              setState(() {
                                _isLoading = true;
                              });

                              // 2. On formate le numéro (ex: +33612345678)
                              final number =
                                  "+33${_phoneController.text.trim()}";

                              // 3. On appelle le service
                              AuthService().verifyPhoneNumber(
                                phoneNumber: number,
                                onCodeSent: () {
                                  // Succès : Le SMS est parti !
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  context.push(
                                    '/otp',
                                    extra: number,
                                  ); // On passe à la suite
                                },
                                onError: (error) {
                                  // Échec : Mauvais numéro, quota dépassé...
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                              );
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      // Affiche un loader si _isLoading est vrai, sinon le texte
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Envoyer le code"),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
