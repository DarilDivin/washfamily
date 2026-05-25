import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:washfamily/src/features/authentication/data/services/auth_service.dart';
import 'login_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class OtpScreen extends StatefulWidget {
  final String destination;

  const OtpScreen({super.key, required this.destination});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: tt.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700, color: AppColors.primary),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primary, width: 2),
    );

    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      color: AppColors.inputBackground,
      border: Border.all(color: Colors.transparent),
    );

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
        title: Text('WashFamily',
            style: tt.titleSmall?.copyWith(color: AppColors.primary)),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),

              Text(
                'Entrez le code',
                style: tt.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Envoyé au ${widget.destination}',
                    style: tt.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text('MODIFIER',
                        style: tt.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // ── Pinput ─────────────────────────────────────────────
              Center(
                child: Pinput(
                  length: 6,
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
                        const SnackBar(
                          content: Text('Code incorrect ou expiré.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Bloc sécurité ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.completedBg,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color:
                          AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const PhosphorIcon(
                        PhosphorIconsRegular.shieldCheck,
                        color: AppColors.primary,
                        size: 20),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Sécurité WashFamily',
                          style: tt.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                          'Nous vérifions votre identité pour sécuriser vos prochaines commandes.',
                          style: tt.bodySmall
                              ?.copyWith(color: AppColors.primary)),
                    ]),
                  ),
                ]),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              Center(
                child: Text(
                  'Je n\'ai pas reçu le code (00:30)',
                  style: tt.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),

              const Spacer(),

              // ── Footer ─────────────────────────────────────────────
              _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final style =
        tt.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 10);
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
