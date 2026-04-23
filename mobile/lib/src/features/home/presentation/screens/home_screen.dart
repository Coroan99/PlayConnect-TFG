import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../publications/presentation/controllers/publicaciones_controller.dart';
import '../../../publications/presentation/widgets/publicacion_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;
    final state = ref.watch(publicacionesControllerProvider);
    final publicacionesController = ref.read(
      publicacionesControllerProvider.notifier,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (state.isLoading && state.publicaciones.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.hasError && state.publicaciones.isEmpty) {
          return _FeedErrorState(
            message: state.errorMessage!,
            onRetry: publicacionesController.loadPublicaciones,
          );
        }

        if (state.publicaciones.isEmpty) {
          return RefreshIndicator(
            onRefresh: publicacionesController.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: constraints.maxHeight,
                  child: const EmptyState(
                    icon: Icons.public_outlined,
                    title: 'Sin publicaciones',
                    description:
                        'Cuando la comunidad publique juegos disponibles, apareceran aqui.',
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: publicacionesController.refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            itemCount: state.publicaciones.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _FeedHeader(
                  userName: usuario?.nombre ?? 'jugador',
                  isRefreshing: state.isLoading,
                );
              }

              final publicacion = state.publicaciones[index - 1];
              final isOwnPublication = publicacion.usuario.id == usuario?.id;
              final hasInterest = state.interestedPublicationIds.contains(
                publicacion.id,
              );
              final isSubmittingInterest = state.processingInterestIds.contains(
                publicacion.id,
              );

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: PublicacionCard(
                    publicacion: publicacion,
                    isOwnPublication: isOwnPublication,
                    hasInterest: hasInterest,
                    isSubmittingInterest: isSubmittingInterest,
                    onInterestPressed: usuario == null
                        ? null
                        : () => _registrarInteres(
                            context,
                            ref,
                            usuario.id,
                            publicacion.id,
                          ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _registrarInteres(
    BuildContext context,
    WidgetRef ref,
    String usuarioId,
    String publicacionId,
  ) async {
    final error = await ref
        .read(publicacionesControllerProvider.notifier)
        .registrarInteres(usuarioId: usuarioId, publicacionId: publicacionId);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error ?? 'Interes registrado correctamente.')),
      );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.userName, required this.isRefreshing});

  final String userName;
  final bool isRefreshing;

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
                        'Hola, $userName',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Publicaciones recientes de la comunidad PlayConnect.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isRefreshing)
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FeedErrorState extends StatelessWidget {
  const _FeedErrorState({required this.message, required this.onRetry});

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
                'No se pudieron cargar las publicaciones',
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
