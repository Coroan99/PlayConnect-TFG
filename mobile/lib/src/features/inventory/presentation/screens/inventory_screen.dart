import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/inventario_controller.dart';
import '../widgets/inventario_item_card.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String? _lastRequestedUsuarioId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final nextUsuarioId = next.usuario?.id;
      final previousUsuarioId = previous?.usuario?.id;

      if (nextUsuarioId != null &&
          nextUsuarioId.isNotEmpty &&
          nextUsuarioId != previousUsuarioId) {
        _loadInventario(nextUsuarioId);
      }
    });

    final usuario = ref.watch(authControllerProvider).usuario;
    final state = ref.watch(inventarioControllerProvider);
    final controller = ref.read(inventarioControllerProvider.notifier);

    if (usuario == null) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Sesion no disponible',
        description: 'Vuelve a iniciar sesion para consultar tu inventario.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (state.isLoading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.hasError && state.items.isEmpty) {
          return _InventoryErrorState(
            message: state.errorMessage!,
            onRetry: () => controller.loadInventario(usuario.id),
          );
        }

        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                _InventoryHeader(
                  state: state,
                  onAddGame: () => _openAddGameFlow(),
                ),
                SizedBox(
                  height: constraints.maxHeight > 220
                      ? constraints.maxHeight - 220
                      : 220,
                  child: _InventoryEmptyState(
                    onAddGame: () => _openAddGameFlow(),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            itemCount: state.items.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _InventoryHeader(
                  state: state,
                  onAddGame: () => _openAddGameFlow(),
                );
              }

              final item = state.items[index - 1];

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: InventarioItemCard(item: item),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _loadForCurrentUser() {
    final usuarioId = ref.read(authControllerProvider).usuario?.id;

    if (usuarioId == null || usuarioId.isEmpty) {
      return;
    }

    _loadInventario(usuarioId);
  }

  void _loadInventario(String usuarioId) {
    if (_lastRequestedUsuarioId == usuarioId) {
      return;
    }

    _lastRequestedUsuarioId = usuarioId;
    ref.read(inventarioControllerProvider.notifier).loadInventario(usuarioId);
  }

  Future<void> _openAddGameFlow() async {
    final created = await context.pushNamed<bool>(AppRoute.inventoryAdd.name);

    if (!mounted || created != true) {
      return;
    }

    await ref.read(inventarioControllerProvider.notifier).refresh();
  }
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader({required this.state, required this.onAddGame});

  final InventarioState state;
  final VoidCallback onAddGame;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mi inventario',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gestiona los juegos asociados a tu cuenta.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.isLoading)
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: onAddGame,
                icon: const Icon(Icons.add),
                label: const Text('Anadir juego'),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryCard(label: 'Total', value: state.total),
                _SummaryCard(label: 'Coleccion', value: state.totalColeccion),
                _SummaryCard(label: 'Visible', value: state.totalVisible),
                _SummaryCard(label: 'En venta', value: state.totalEnVenta),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _InventoryEmptyState extends StatelessWidget {
  const _InventoryEmptyState({required this.onAddGame});

  final VoidCallback onAddGame;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Inventario vacio',
            description:
                'Cuando anadas juegos a tu coleccion, apareceran aqui.',
          ),
          FilledButton.icon(
            onPressed: onAddGame,
            icon: const Icon(Icons.add),
            label: const Text('Anadir primer juego'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 128,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryErrorState extends StatelessWidget {
  const _InventoryErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.cloud_off_outlined,
                  color: colorScheme.onErrorContainer,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No se pudo cargar el inventario',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
