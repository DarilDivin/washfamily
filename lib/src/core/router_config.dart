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
import '../features/booking/presentation/screens/booking_date_screen.dart';
import '../features/booking/presentation/screens/booking_summary_screen.dart';
import '../features/booking/presentation/screens/bookings_screen.dart';
import '../features/home/presentation/screens/main_scaffold.dart';
import '../features/user_profile/presentation/screens/profile_screen.dart';
import '../features/user_profile/presentation/screens/add_machine_screen.dart';
import '../features/user_profile/presentation/screens/my_machines_screen.dart';
import '../features/user_profile/presentation/screens/profile_subscreens.dart';
import '../features/shop/presentation/screens/shop_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/admin_subscriptions_screen.dart';
import '../features/admin/presentation/screens/manage_products_screen.dart';
import '../features/subscriptions/presentation/screens/subscription_plans_screen.dart';
import '../features/shop/presentation/screens/cart_screen.dart';
import '../features/machines_map/domain/models/machine_model.dart';
import '../dev/dev_seed_screen.dart';
import '../features/machines_map/presentation/screens/machine_detail_screen.dart';
import '../features/booking/presentation/screens/booking_success_screen.dart';
import '../features/booking/presentation/screens/owner_bookings_screen.dart';
import '../features/booking/domain/models/reservation_model.dart';

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
      GoRoute(path: '/dev/seed', builder: (context, state) => const DevSeedScreen()),
      GoRoute(
        path: '/machine/:id',
        builder: (context, state) {
          final machine = state.extra as MachineModel;
          return MachineDetailScreen(machine: machine);
        },
      ),
      // ── Tunnel réservation ────────────────────────────────────────────
      GoRoute(
        path: '/bookings/new',
        builder: (context, state) {
          final machine = state.extra as MachineModel;
          return BookingDateScreen(machine: machine);
        },
      ),
      GoRoute(
        path: '/bookings/summary',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return BookingSummaryScreen(
            machine: data['machine'] as MachineModel,
            startTime: data['startTime'] as DateTime,
            endTime: data['endTime'] as DateTime,
            price: data['price'] as double,
          );
        },
      ),
      GoRoute(
        path: '/bookings/success',
        builder: (context, state) {
          final reservation = state.extra as ReservationModel;
          return BookingSuccessScreen(reservation: reservation);
        },
      ),
      GoRoute(
        path: '/profile/owner-bookings',
        builder: (context, state) => const OwnerBookingsScreen(),
      ),
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
        path: '/subscriptions',
        builder: (context, state) => const SubscriptionPlansScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const ManageProductsScreen(),
      ),
      GoRoute(
        path: '/admin/subscriptions',
        builder: (context, state) => const AdminSubscriptionsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shop',
                builder: (context, state) => const ShopScreen(),
                routes: [
                   GoRoute(
                     path: 'cart',
                     builder: (context, state) => const CartScreen(),
                   ),
                ]
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                builder: (context, state) => const BookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                   GoRoute(path: 'my-machines', builder: (context, state) => const MyMachinesScreen()),
                   GoRoute(path: 'add-machine', builder: (context, state) => const AddMachineScreen()),
                   GoRoute(
                     path: 'edit-machine',
                     builder: (context, state) {
                       final machine = state.extra as MachineModel;
                       return EditMachineScreen(machine: machine);
                     },
                   ),
                   GoRoute(path: 'favorites', builder: (context, state) => const FavoritesScreen()),
                   GoRoute(path: 'personal-info', builder: (context, state) => const PersonalInfoScreen()),
                   GoRoute(path: 'payments', builder: (context, state) => const PaymentsScreen()),
                   GoRoute(path: 'help', builder: (context, state) => const HelpCenterScreen()),
                   GoRoute(path: 'security', builder: (context, state) => const SecurityReportScreen()),
                   GoRoute(path: 'pending-requests', builder: (context, state) => const PendingRequestsScreen()),
                   GoRoute(path: 'revenue', builder: (context, state) => const RevenueStatsScreen()),
                   GoRoute(path: 'bank-details', builder: (context, state) => const BankDetailsScreen()),
                ],
              ),
            ],
          ),
        ],
      ),

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
