import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/inventory/presentation/screens/add_inventory_item_screen.dart';
import '../../features/inventory/presentation/screens/edit_inventory_item_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/market/presentation/screens/market_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/offers/presentation/screens/publication_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import 'main_shell.dart';

enum AppRoute {
  splash('/'),
  login('/login'),
  register('/register'),
  home('/home'),
  market('/market'),
  inventory('/inventory'),
  inventoryAdd('/inventory/add'),
  inventoryEdit('/inventory/edit'),
  notifications('/notifications'),
  publicationDetail('/publicaciones'),
  profile('/profile');

  const AppRoute(this.path);

  final String path;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoute.splash.path,
    redirect: (context, state) {
      final location = state.uri.path;
      final isAuthRoute =
          location == AppRoute.login.path || location == AppRoute.register.path;

      if (authState.isCheckingSession) {
        return location == AppRoute.splash.path ? null : AppRoute.splash.path;
      }

      if (location == AppRoute.splash.path) {
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
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.name,
        builder: (context, state) => const _SplashScreen(),
      ),
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
            path: AppRoute.market.path,
            name: AppRoute.market.name,
            builder: (context, state) => const MarketScreen(),
          ),
          GoRoute(
            path: AppRoute.inventory.path,
            name: AppRoute.inventory.name,
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: AppRoute.inventoryAdd.path,
            name: AppRoute.inventoryAdd.name,
            builder: (context, state) => const AddInventoryItemScreen(),
          ),
          GoRoute(
            path: '${AppRoute.inventoryEdit.path}/:id',
            name: AppRoute.inventoryEdit.name,
            builder: (context, state) => EditInventoryItemScreen(
              itemId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoute.notifications.path,
            name: AppRoute.notifications.name,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '${AppRoute.publicationDetail.path}/:id',
            name: AppRoute.publicationDetail.name,
            builder: (context, state) => PublicationDetailScreen(
              publicacionId: state.pathParameters['id'] ?? '',
            ),
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

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
