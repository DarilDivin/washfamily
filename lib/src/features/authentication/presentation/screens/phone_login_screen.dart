import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:washfamily/src/features/authentication/data/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _isButtonEnabled = _phoneController.text.length >= 9;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Titre ──────────────────────────────────────────────
              Text(
                'Quel est votre\nnuméro?',
                style: tt.headlineLarge?.copyWith(height: 1.2),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Nous vous enverrons un code par SMS pour vérifier votre identité.',
                style: tt.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // ── Champ téléphone ────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Text(
                      '🇫🇷  +33',
                      style: tt.titleSmall?.copyWith(
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        autofocus: true,
                        keyboardType: TextInputType.phone,
                        style:
                            tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: '6 12 34 56 78',
                          hintStyle: tt.titleSmall
                              ?.copyWith(color: AppColors.textSecondary),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Sécurité ───────────────────────────────────────────
              Row(children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'DONNÉES SÉCURISÉES ET CRYPTÉES',
                  style: tt.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                      fontSize: 10),
                ),
              ]),

              const Spacer(),

              // ── CTA ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_isButtonEnabled && !_isLoading)
                      ? () {
                          setState(() => _isLoading = true);
                          final number =
                              '+33${_phoneController.text.trim()}';
                          AuthService().verifyPhoneNumber(
                            phoneNumber: number,
                            onCodeSent: () {
                              setState(() => _isLoading = false);
                              context.push('/otp', extra: number);
                            },
                            onError: (error) {
                              setState(() => _isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(error),
                                    backgroundColor: AppColors.error),
                              );
                            },
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg),
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.surface, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Envoyer le code'),
                            const SizedBox(width: AppSpacing.sm),
                            const PhosphorIcon(
                                PhosphorIconsRegular.arrowRight,
                                size: 18),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Footer ─────────────────────────────────────────────
              Center(
                child: Text(
                  'En continuant, vous acceptez de recevoir un SMS.\nDes frais peuvent s\'appliquer.',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall
                      ?.copyWith(color: AppColors.textSecondary, fontSize: 10),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text('WashFamily',
                    style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
