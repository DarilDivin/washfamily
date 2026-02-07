import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:washfamily/src/features/authentication/presentation/screens/email_login_screen.dart';
import 'package:washfamily/src/features/authentication/presentation/screens/phone_login_screen.dart';
import 'package:washfamily/src/features/home/presentation/screens/home_screen.dart';
import 'package:washfamily/src/features/splash/presentation/splash_screen.dart';

// import '../features/authentication/data/auth_repository.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/otp_screen.dart';
import '../features/authentication/presentation/screens/profile_setup_screen.dart';
import '../features/authentication/presentation/screens/register_screen.dart';

part 'router_config.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  // final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/',
    // refreshListenable: GoRouterRefreshStream(
    //   ref.watch(authStateChangesProvider.stream),
    // ),
    // redirect: (context, state) {
    //   final isLoggedIn = authState.asData?.value != null;
    //   final isLoggingIn =
    //       state.uri.path == '/login' ||
    //       state.uri.path == '/register' ||
    //       state.uri.path == '/otp' ||
    //       state.uri.path == '/profile-setup';

    //   if (!isLoggedIn && !isLoggingIn) {
    //     return '/login';
    //   }

    //   if (isLoggedIn && isLoggingIn) {
    //     return '/';
    //   }

    //   return null;
    // },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/login/phone',
        builder: (context, state) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: '/login/email',
        builder: (context, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          // On récupère l'info passée par l'écran précédent
          // Si on n'a rien reçu, on met un texte par défaut
          final destination = state.extra as String? ?? "votre contact";
          return OtpScreen(destination: destination);
        },
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
