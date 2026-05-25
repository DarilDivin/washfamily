import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/services/auth_service.dart';
import 'login_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pwd = _passwordCtrl.text.trim();
    if (email.isEmpty || pwd.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final credential = await AuthService().signInWithEmail(email, pwd);
      if (credential.user != null && mounted) {
        await checkAuthRedirection(context, credential.user!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('WashFamily',
            style: tt.titleSmall?.copyWith(color: AppColors.primary)),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),

              Text(
                'Connectez-vous par\ne-mail',
                style: tt.headlineLarge?.copyWith(height: 1.2),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Heureux de vous revoir. Gérez votre linge en toute simplicité.',
                style: tt.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // ── Email ─────────────────────────────────────────────────
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
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Mot de passe ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('MOT DE PASSE',
                      style: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5)),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text('MOT DE PASSE OUBLIÉ?',
                        style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _InputField(
                controller: _passwordCtrl,
                hint: '••••••••',
                obscureText: _obscureText,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
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
                      onPressed: _login,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd)),
                        elevation: 0,
                      ),
                      child: const Text('Se connecter'),
                    ),

              const SizedBox(height: AppSpacing.xl),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Pas encore de compte ? ", style: tt.bodyMedium),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text("S'inscrire",
                        style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxxl),
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InputField
// ─────────────────────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      style: tt.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: tt.bodyLarge?.copyWith(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Footer
// ─────────────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final style = tt.labelSmall?.copyWith(
        color: AppColors.textSecondary, fontSize: 10);
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Privacy Policy', style: style),
        const SizedBox(width: AppSpacing.lg),
        Text('Terms of Service', style: style),
        const SizedBox(width: AppSpacing.lg),
        Text('Legal', style: style),
      ]),
      const SizedBox(height: AppSpacing.xs),
      Text('© 2025 WashFamily. All rights reserved.',
          textAlign: TextAlign.center, style: style),
      const SizedBox(height: AppSpacing.lg),
    ]);
  }
}
