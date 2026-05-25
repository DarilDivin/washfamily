import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLocationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Titre ──────────────────────────────────────────────
              Text(
                'Finalisez votre inscription',
                style: tt.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Votre photo et votre nom rassureront les propriétaires de machines.',
                style: tt.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Avatar ─────────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.border, width: 2),
                      ),
                      child: const PhosphorIcon(
                        PhosphorIconsRegular.user,
                        size: 56,
                        color: AppColors.border,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.surface, width: 2),
                        ),
                        child: const PhosphorIcon(
                          PhosphorIconsRegular.camera,
                          color: AppColors.surface,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Prénom ─────────────────────────────────────────────
              Text('PRÉNOM',
                  style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Prénom',
                  prefixIcon: const PhosphorIcon(
                      PhosphorIconsRegular.user,
                      size: 18,
                      color: AppColors.textSecondary),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Nom ────────────────────────────────────────────────
              Text('NOM',
                  style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Nom de famille',
                  prefixIcon: const PhosphorIcon(
                      PhosphorIconsRegular.user,
                      size: 18,
                      color: AppColors.textSecondary),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Carte localisation ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.completedBg,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const PhosphorIcon(
                          PhosphorIconsRegular.mapPin,
                          color: AppColors.primary,
                          size: 20),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Localisation',
                              style: tt.titleSmall),
                          Text(
                            'Pour voir les machines autour de vous.',
                            style: tt.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isLocationEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: (value) =>
                          setState(() => _isLocationEnabled = value),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── CTA ────────────────────────────────────────────────
              FilledButton(
                onPressed: () async {
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      final newUser = UserModel(
                        uid: user.uid,
                        firstName: _firstNameController.text.trim(),
                        lastName: _lastNameController.text.trim(),
                        phoneNumber: user.phoneNumber ?? '',
                        email: user.email,
                      );
                      await UserRepository().createUser(newUser);
                    }
                    if (context.mounted) {
                      context.go('/home');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd)),
                ),
                child: const Text("C'est parti !"),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
