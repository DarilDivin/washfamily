// Ce fichier est conservé pour la compatibilité des imports existants.
// La logique du wizard a été remplacée par BecomeOwnerScreen.
// Voir : become_owner_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Redirige vers le nouvel écran '/become-owner'.
/// @deprecated Utiliser BecomeOwnerScreen via la route '/become-owner'.
class BecomeOwnerWizard extends StatelessWidget {
  const BecomeOwnerWizard({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/become-owner');
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
