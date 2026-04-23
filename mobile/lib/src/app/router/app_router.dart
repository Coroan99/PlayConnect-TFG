import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/games/presentation/screens/games_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import 'main_shell.dart';

enum AppRoute {
  login('/login'),
  register('/register'),
  home('/home'),
  games('/games'),
  inventory('/inventory'),
  profile('/profile');

  const AppRoute(this.path);

  final String path;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoute.login.path,
    redirect: (context, state) {
      final location = state.uri.path;
      final isAuthRoute =
          location == AppRoute.login.path || location == AppRoute.register.path;

      if (location == '/') {
        return authState.isAuthenticated
            ? AppRoute.home.path
            : AppRoute.login.path;
      }

      if (!authState.isAuthenticated && !isAuthRoute) {
        return AppRoute.login.path;
      }

      if (authState.isAuthenticated && isAuthRoute) {
        return AppRoute.home.path;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoute.login.path),
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoute.register.path,
        name: AppRoute.register.name,
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoute.home.path,
            name: AppRoute.home.name,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoute.games.path,
            name: AppRoute.games.name,
            builder: (context, state) => const GamesScreen(),
          ),
          GoRoute(
            path: AppRoute.inventory.path,
            name: AppRoute.inventory.name,
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: AppRoute.profile.path,
            name: AppRoute.profile.name,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
