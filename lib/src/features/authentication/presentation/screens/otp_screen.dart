import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:washfamily/src/features/authentication/data/services/auth_service.dart'; 
import 'login_screen.dart'; // pour checkAuthRedirection

class OtpScreen extends StatefulWidget {
  final String destination;

  const OtpScreen({super.key, required this.destination});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Style pour les 6 cases
    final defaultPinTheme = PinTheme(
      width: 46,
      height: 54,
      textStyle: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: theme.primaryColor, width: 2),
      boxShadow: [BoxShadow(color: theme.primaryColor.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
    );

    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      color: const Color(0xFFF1F5F9),
      border: Border.all(color: Colors.transparent),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 150,
        leading: TextButton.icon(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: theme.primaryColor, size: 18),
          label: Text("WashFamily", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               const SizedBox(height: 40),
              
               Text(
                "Entrez le code",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Envoyé au ${widget.destination}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.pop(), // Revenir en arrière pour modifier
                    child: Text(
                      "MODIFIER",
                      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 48),

              // PINPUT 6 CHIFFRES
              Center(
                child: Pinput(
                  length: 6, // Firebase demande toujours 6 chiffres
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  showCursor: true,
                  onCompleted: (pin) async {
                    final isSuccess = await AuthService().verifyOTP(pin);
                    if (!context.mounted) return;

                    if (isSuccess) {
                       final user = FirebaseAuth.instance.currentUser;
                       if (user != null) {
                         await checkAuthRedirection(context, user);
                       } else {
                         context.go('/profile-setup');
                       }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Code incorrect ou expiré."), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 32),
              
              // Widget Sécurité
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // Bleu très clair
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(Icons.shield_rounded, color: theme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Sécurité WashFamily", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                          const SizedBox(height: 4),
                          Text("Nous vérifions votre identité pour sécuriser vos prochaines commandes.", style: TextStyle(fontSize: 11, color: Colors.blue[800])),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 64),

              Center(
                child: Text(
                  "Je n'ai pas reçu le code (00:30)",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
              
              const Spacer(),
              
              // Footer
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Privacy Policy", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    const SizedBox(width: 16),
                    Text("Terms of Service", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    const SizedBox(width: 16),
                    Text("Legal", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text("© 2024 WashFamily. All rights reserved.", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
