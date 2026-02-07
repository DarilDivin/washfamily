import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  // Pour simuler l'état du switch de localisation
  bool _isLocationEnabled = true; 

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // AppBar simple pour éventuellement revenir en arrière si erreur
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. TITRES
              Text(
                "Finalisez voitre inscription",
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Votre photo et votre nom rassureront les propriétaires de machines.",
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // 2. AVATAR (Selecteur Photo)
              Center(
                child: Stack(
                  children: [
                    // Le cercle de l'avatar
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                      ),
                      child: Icon(
                        Icons.person, 
                        size: 60, 
                        color: Colors.grey[300]
                      ),
                      // Plus tard, ici on affichera l'image choisie :
                      // child: ClipOval(child: Image.file(_imageFile, fit: BoxFit.cover)),
                    ),
                    
                    // Le petit bouton "+" bleu
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 3. FORMULAIRE
              // Prénom
              Text("PRÉNOM", style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words, // Majuscule auto
                decoration: const InputDecoration(
                  hintText: "Daril",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 24),

              // Nom
              Text("NOM", style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: "...",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 32),

              // 4. CARTE PERMISSION (Location)
              // C'est ici qu'on respecte ta "Clarté Domestique" : pas de popup agressive
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.location_on, color: theme.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Localisation",
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Pour voir les machines autour de vous.",
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isLocationEnabled,
                      activeThumbColor: theme.primaryColor.withValues(alpha: 1),
                      onChanged: (value) {
                        setState(() {
                          _isLocationEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 5. BOUTON FINAL
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // C'est ici qu'on enregistrera tout dans Firestore
                    // Pour l'instant, on va vers l'accueil (La Map)
                    context.go('/home'); 
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("C'est parti !"),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}