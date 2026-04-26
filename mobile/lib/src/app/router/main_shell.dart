import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import 'app_router.dart';

class MainShell extends ConsumerWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  static const _tabs = [
    AppRoute.home,
    AppRoute.games,
    AppRoute.inventory,
    AppRoute.profile,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final detailTitle = _detailTitle(location);
    final isDetailRoute = detailTitle != null;

    return Scaffold(
      appBar: AppBar(
        leading: isDetailRoute
            ? IconButton(
                tooltip: 'Volver',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }

                  context.go(AppRoute.home.path);
                },
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: Text(detailTitle ?? AppConfig.appName),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {
              if (location != AppRoute.notifications.path) {
                context.go(AppRoute.notifications.path);
              }
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: isDetailRoute
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex(location),
              onDestinationSelected: (index) {
                final path = _tabs[index].path;

                if (path != location) {
                  context.go(path);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.sports_esports_outlined),
                  selectedIcon: Icon(Icons.sports_esports),
                  label: 'Juegos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: 'Inventario',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
    );
  }

  int _selectedIndex(String location) {
    if (location.startsWith(AppRoute.games.path)) {
      return 1;
    }

    if (location.startsWith(AppRoute.inventory.path)) {
      return 2;
    }

    if (location.startsWith(AppRoute.notifications.path)) {
      return 0;
    }

    if (location.startsWith(AppRoute.profile.path)) {
      return 3;
    }

    return 0;
  }

  String? _detailTitle(String location) {
    if (location.startsWith(AppRoute.publicationDetail.path)) {
      return 'Detalle de publicacion';
    }

    if (location.startsWith(AppRoute.inventoryAdd.path)) {
      return 'Anadir juego';
    }

    if (location.startsWith(AppRoute.inventoryEdit.path)) {
      return 'Editar inventario';
    }

    return null;
  }
}
