import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final pwd = _passwordCtrl.text.trim();
    if (email.isEmpty || pwd.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email invalide ou mot de passe trop court.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await AuthService().registerWithEmail(email, pwd);
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
          label: Text("Retour", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
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
                "Créer un compte\nWashFamily",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  height: 1.2
                ),
              ),
              const SizedBox(height: 16),
              Text(
                 "Rejoignez le réseau de pressing à proximité pour faciliter votre quotidien.",
                 style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              
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
              
              Text("MOT DE PASSE (6 caractères min.)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey[700], letterSpacing: 1.5)),
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
                    onPressed: _register,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("S'inscrire", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
