import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/set_password_screen.dart';
import '../../features/farms/presentation/screens/farm_detail_screen.dart';
import '../../features/farms/presentation/screens/farms_screen.dart';
import '../../features/listings/presentation/screens/cart_screen.dart';
import '../../features/listings/presentation/screens/listings_screen.dart';
import '../../features/orders/presentation/screens/profile_screen.dart';
import 'go_router_refresh_stream.dart';
import 'main_shell.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const setPassword = '/set-password';
  static const home = '/';
  static const farms = '/farms';
  static const farmDetail = '/farms/detail'; // + '/<sellerId>'
  static const profile = '/profile';
  static const cart = '/cart';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final user = authRepository.currentUser;
      final isLoggedIn = user != null;
      final isOnPublicScreen =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.forgotPassword;
      final isOnSetPassword = state.matchedLocation == AppRoutes.setPassword;

      if (!isLoggedIn && !isOnPublicScreen) return AppRoutes.login;
      if (isLoggedIn && isOnPublicScreen) return AppRoutes.home;

      // Google-only accounts must set a password before they can reach
      // anything else (so the account is always reachable both ways).
      if (isLoggedIn && !user.hasPasswordIdentity && !isOnSetPassword) {
        return AppRoutes.setPassword;
      }
      if (isLoggedIn && user.hasPasswordIdentity && isOnSetPassword) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const ListingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.farms,
                builder: (context, state) => const FarmsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '${AppRoutes.farmDetail}/:sellerId',
        builder: (context, state) =>
            FarmDetailScreen(sellerId: state.pathParameters['sellerId']!),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.setPassword,
        builder: (context, state) => const SetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
    ],
  );
});
