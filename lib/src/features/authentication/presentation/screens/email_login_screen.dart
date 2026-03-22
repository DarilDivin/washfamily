import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/auth_service.dart';
import 'login_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pwd = _passwordCtrl.text.trim();
    if (email.isEmpty || pwd.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final credential = await AuthService().signInWithEmail(email, pwd);
      if (credential.user != null) {
        if (!mounted) return;
        await checkAuthRedirection(context, credential.user!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
                "Connectez-vous par\ne-mail",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  height: 1.2
                ),
              ),
              const SizedBox(height: 16),
              Text(
                 "Heureux de vous revoir. Gérez votre linge en toute simplicité.",
                 style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              
              // Email Label
              Text("ADRESSE E-MAIL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey[700], letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    hintText: "nom@exemple.com",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Password Label + Forgot
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("MOT DE PASSE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey[700], letterSpacing: 1.5)),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text("MOT DE PASSE OUBLIÉ?", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _passwordCtrl,
                  decoration: InputDecoration(
                    hintText: "••••••••",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off, color: Colors.grey[500]),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
                  ),
                  obscureText: _obscureText,
                ),
              ),

              const SizedBox(height: 32),
              
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: _login,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("Se connecter", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Pas encore de compte ? "),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: Text("S'inscrire", style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                  )
                ],
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
