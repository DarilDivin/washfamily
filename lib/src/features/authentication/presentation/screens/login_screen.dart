import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/auth_service.dart';
import '../../data/repositories/user_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final credential = await AuthService().signInWithGoogle();
      if (credential != null && credential.user != null) {
        if (!mounted) return;
        await _checkUserRoute(context, credential.user!);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> _checkUserRoute(BuildContext context, User user) async {
    final userModel = await UserRepository().getUser(user.uid);
    if (!context.mounted) return;
    
    if (userModel == null) {
      context.go('/profile-setup');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Haut : Logo Text WashFamily
              Center(
                child: Text(
                  "WashFamily",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              Text(
                "Lavez votre linge,\ntout simplement.",
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Le pressing haut de gamme qui vient à vous.\nUn service expert, en un clic.",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF475569),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // L'image Premium (Mockup)
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.grey[100],
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1582735689369-4fe89db7114c?q=80&w=800'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Badge Qualité
                    Positioned(
                      bottom: -20, // Légèrement en dessous pour dépasser du cadre !
                      child: Container(
                         margin: const EdgeInsets.only(bottom: 40),
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: const Color(0xFFE2E8F0)),
                           boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
                         ),
                         child: Row(
                           children: [
                             Container(
                               padding: const EdgeInsets.all(4),
                               decoration: BoxDecoration(shape: BoxShape.circle, color: theme.primaryColor.withValues(alpha: 0.1)),
                               child: Icon(Icons.verified, color: theme.primaryColor, size: 20),
                             ),
                             const SizedBox(width: 12),
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Text("QUALITÉ PREMIUM", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2)),
                                 const SizedBox(height: 2),
                                 const Text("Nettoyage expert certifié", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 13)),
                               ],
                             )
                           ],
                         ),
                      ),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Boutons d'action
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                FilledButton.icon(
                  onPressed: () => context.push('/login/phone'),
                  icon: const Icon(Icons.phone_android, size: 18),
                  label: const Text("Continuer avec le téléphone", style: TextStyle(fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                OutlinedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: Image.asset('assets/images/google_logo.png', width: 20, height: 20),
                  label: const Text("Continuer avec Google", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey[300]!),
                    elevation: 0,
                    backgroundColor: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/login/email'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                    ),
                    child: const Text("Utiliser une adresse e-mail", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Footer
              Text(
                "En continuant, vous acceptez nos CGU et notre",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                "Politique de confidentialité.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: theme.primaryColor, decoration: TextDecoration.underline),
              ),
              const SizedBox(height: 16),
              Text(
                "© 2024 WashFamily. All rights reserved.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Fonction utilitaire
Future<void> checkAuthRedirection(BuildContext context, User user) async {
  final userModel = await UserRepository().getUser(user.uid);
  if (!context.mounted) return;
  if (userModel == null) {
    context.go('/profile-setup');
  } else {
    context.go('/home');
  }
}
