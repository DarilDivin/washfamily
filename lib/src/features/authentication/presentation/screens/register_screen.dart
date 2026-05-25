import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/services/auth_service.dart';
import 'login_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Email invalide ou mot de passe trop court.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential =
          await AuthService().registerWithEmail(email, pwd);
      if (credential.user != null) {
        if (!mounted) return;
        await checkAuthRedirection(context, credential.user!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft,
              size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Créer un compte\nWashFamily',
                style: tt.headlineLarge?.copyWith(height: 1.2),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Rejoignez le réseau de pressing à proximité pour faciliter votre quotidien.',
                style: tt.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // ── Email ─────────────────────────────────────────────
              Text('ADRESSE E-MAIL',
                  style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5)),
              const SizedBox(height: AppSpacing.sm),
              _InputField(
                controller: _emailCtrl,
                hint: 'nom@exemple.com',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Mot de passe ──────────────────────────────────────
              Text('MOT DE PASSE (6 caractères min.)',
                  style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5)),
              const SizedBox(height: AppSpacing.sm),
              _InputField(
                controller: _passwordCtrl,
                hint: '••••••••',
                obscureText: _obscureText,
                suffixIcon: IconButton(
                  icon: PhosphorIcon(
                    _obscureText
                        ? PhosphorIconsRegular.eye
                        : PhosphorIconsRegular.eyeSlash,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscureText = !_obscureText),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : FilledButton(
                      onPressed: _register,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd)),
                        elevation: 0,
                      ),
                      child: const Text("S'inscrire"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Champ de saisie partagé
// ─────────────────────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: tt.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: tt.bodyLarge?.copyWith(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
