import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/services/auth_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

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
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  static Future<void> _checkUserRoute(
      BuildContext context, User user) async {
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
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // ── Logo ───────────────────────────────────────────────
              Center(
                child: Text(
                  'WashFamily',
                  style: tt.titleLarge?.copyWith(color: AppColors.primary),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              Text(
                'Lavez votre linge,\ntout simplement.',
                style: tt.headlineLarge?.copyWith(height: 1.2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Le pressing haut de gamme qui vient à vous.\nUn service expert, en un clic.',
                style: tt.bodyLarge?.copyWith(
                    color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Image hero ─────────────────────────────────────────
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                        color: AppColors.inputBackground,
                        image: const DecorationImage(
                          image: NetworkImage(
                              'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?q=80&w=800'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Badge qualité
                    Positioned(
                      bottom: AppSpacing.xxl,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary
                                  .withValues(alpha: 0.10),
                            ),
                            child: const PhosphorIcon(
                                PhosphorIconsRegular.sealCheck,
                                color: AppColors.primary,
                                size: 18),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('QUALITÉ PREMIUM',
                                  style: tt.labelSmall?.copyWith(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 1.2)),
                              const SizedBox(height: 2),
                              Text('Nettoyage expert certifié',
                                  style: tt.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Boutons ────────────────────────────────────────────
              if (_isLoading)
                const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
              else ...[
                FilledButton.icon(
                  onPressed: () => context.push('/login/phone'),
                  icon: const PhosphorIcon(
                      PhosphorIconsRegular.deviceMobile,
                      size: 18),
                  label: const Text('Continuer avec le téléphone'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd)),
                    elevation: 0,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                OutlinedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: Image.asset('assets/images/google_logo.png',
                      width: 18, height: 18),
                  label: Text('Continuer avec Google',
                      style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd)),
                    side: const BorderSide(color: AppColors.border),
                    backgroundColor: AppColors.surface,
                    elevation: 0,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                Center(
                  child: TextButton(
                    onPressed: () => context.push('/login/email'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                    child: const Text('Utiliser une adresse e-mail'),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // ── Footer légal ───────────────────────────────────────
              Text(
                'En continuant, vous acceptez nos CGU et notre',
                textAlign: TextAlign.center,
                style: tt.bodySmall
                    ?.copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                'Politique de confidentialité.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '© 2025 WashFamily. All rights reserved.',
                textAlign: TextAlign.center,
                style: tt.bodySmall
                    ?.copyWith(color: AppColors.textSecondary, fontSize: 10),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// Fonction utilitaire partagée entre splash et auth screens
Future<void> checkAuthRedirection(BuildContext context, User user) async {
  final userModel = await UserRepository().getUser(user.uid);
  if (!context.mounted) return;
  if (userModel == null) {
    context.go('/profile-setup');
  } else {
    context.go('/home');
  }
}
