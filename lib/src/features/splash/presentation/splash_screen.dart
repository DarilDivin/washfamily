import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:washfamily/src/features/authentication/presentation/screens/login_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      FirebaseAuth.instance.authStateChanges().first,
    ]);

    if (!mounted) return;

    final user = results[1] as User?;
    if (user != null) {
      await checkAuthRedirection(context, user);
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const PhosphorIcon(
                PhosphorIconsRegular.washingMachine,
                size: 56,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'WashFamily',
              style: tt.headlineLarge?.copyWith(letterSpacing: -0.5),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
