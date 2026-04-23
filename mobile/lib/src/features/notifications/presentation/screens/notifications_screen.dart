import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/notificaciones_controller.dart';
import '../widgets/notificacion_card.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
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
        _loadNotificaciones(nextUsuarioId);
      }
    });

    final usuario = ref.watch(authControllerProvider).usuario;
    final state = ref.watch(notificacionesControllerProvider);
    final controller = ref.read(notificacionesControllerProvider.notifier);

    if (usuario == null) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Sesion no disponible',
        description:
            'Vuelve a iniciar sesion para consultar tus notificaciones.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (state.isLoading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.hasError && state.items.isEmpty) {
          return _NotificationsErrorState(
            message: state.errorMessage!,
            onRetry: () => controller.loadNotificaciones(usuario.id),
          );
        }

        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: constraints.maxHeight,
                  child: const EmptyState(
                    icon: Icons.notifications_none,
                    title: 'Sin notificaciones',
                    description:
                        'Las ofertas, intereses y avisos importantes apareceran aqui.',
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
                return _NotificationsHeader(state: state);
              }

              final notificacion = state.items[index - 1];

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: NotificacionCard(
                    notificacion: notificacion,
                    isMarkingRead: state.markingReadIds.contains(
                      notificacion.id,
                    ),
                    onTap: () => _openNotification(notificacion.id),
                    onMarkAsRead: () => _markAsRead(notificacion.id),
                  ),
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

    _loadNotificaciones(usuarioId);
  }

  void _loadNotificaciones(String usuarioId) {
    if (_lastRequestedUsuarioId == usuarioId) {
      return;
    }

    _lastRequestedUsuarioId = usuarioId;
    ref
        .read(notificacionesControllerProvider.notifier)
        .loadNotificaciones(usuarioId);
  }

  Future<void> _markAsRead(String notificacionId) async {
    final error = await ref
        .read(notificacionesControllerProvider.notifier)
        .markAsRead(notificacionId);

    if (!mounted || error == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _openNotification(String notificacionId) async {
    await _markAsRead(notificacionId);

    if (!mounted) {
      return;
    }

    final notificacion = ref
        .read(notificacionesControllerProvider)
        .items
        .where((item) => item.id == notificacionId)
        .firstOrNull;
    final publicacionId = notificacion?.publicacionId;

    if (publicacionId != null) {
      context.pushNamed(
        AppRoute.publicationDetail.name,
        pathParameters: {'id': publicacionId},
      );
      return;
    }

    final referencia = notificacion?.referencia;

    if (referencia == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Navegacion preparada para ${referencia.label.toLowerCase()}.',
          ),
        ),
      );
  }
}

class _NotificationsHeader extends ConsumerWidget {
  const _NotificationsHeader({required this.state});

  final NotificacionesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = ref.read(notificacionesControllerProvider.notifier);

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
                        'Notificaciones',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${state.unreadCount} pendientes de leer',
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
                  )
                else
                  TextButton.icon(
                    onPressed: state.unreadCount == 0
                        ? null
                        : () => _markAllAsRead(context, controller),
                    icon: const Icon(Icons.done_all),
                    label: const Text('Leer todas'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _markAllAsRead(
    BuildContext context,
    NotificacionesController controller,
  ) async {
    final error = await controller.markAllAsRead();

    if (!context.mounted || error == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }
}

class _NotificationsErrorState extends StatelessWidget {
  const _NotificationsErrorState({
    required this.message,
    required this.onRetry,
  });

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
                'No se pudieron cargar las notificaciones',
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
