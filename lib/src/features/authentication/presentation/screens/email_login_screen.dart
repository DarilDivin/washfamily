import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      // Validation simple : contient un @ et un .
      final isValid =
          _emailController.text.contains('@') &&
          _emailController.text.contains('.');
      setState(() {
        _isButtonEnabled = isValid;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quel est votre e-mail ?",
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),

                  // --- CHAMP EMAIL ---
                  TextField(
                    controller: _emailController,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      // Utilise le style défini dans ton Theme !
                      hintText: "exemple@email.com",
                      prefixIcon: Icon(
                        Icons.mail_outline,
                        color: theme.primaryColor,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isButtonEnabled
                          ? () {
                              // Ici, soit on demande un mot de passe, soit on envoie un lien magique
                              // Pour l'instant, disons qu'on va vers le setup profil
                              context.push('/otp', extra: _emailController.text);
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Continuer"),
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
