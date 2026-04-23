import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 720
            ? (constraints.maxWidth - 56) / 2
            : constraints.maxWidth;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${usuario?.nombre ?? 'jugador'}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Resumen de tu actividad en PlayConnect.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: const _ModuleCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Inventario',
                      description: 'Gestiona los juegos que quieres cambiar.',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const _ModuleCard(
                      icon: Icons.public_outlined,
                      title: 'Publicaciones',
                      description: 'Consulta anuncios activos de la comunidad.',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const _ModuleCard(
                      icon: Icons.favorite_border,
                      title: 'Intereses',
                      description: 'Sigue juegos y propuestas relevantes.',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const _ModuleCard(
                      icon: Icons.swap_horiz,
                      title: 'Ofertas',
                      description: 'Revisa intercambios enviados y recibidos.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colorScheme.onSecondaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
