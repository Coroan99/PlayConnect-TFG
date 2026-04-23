import 'package:flutter/material.dart';

import '../../domain/publicacion.dart';

class PublicacionCard extends StatelessWidget {
  const PublicacionCard({
    required this.publicacion,
    required this.isOwnPublication,
    required this.hasInterest,
    required this.isSubmittingInterest,
    this.onTap,
    required this.onInterestPressed,
    super.key,
  });

  final Publicacion publicacion;
  final bool isOwnPublication;
  final bool hasInterest;
  final bool isSubmittingInterest;
  final VoidCallback? onTap;
  final VoidCallback? onInterestPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final precioLabel = publicacion.inventario.precioLabel;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GameImage(publicacion.juego.imagenUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          publicacion.juego.nombre,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Publicado por ${publicacion.usuario.nombre}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(label: publicacion.juego.tipoLabel),
                            if (publicacion.juego.plataforma != null)
                              _InfoChip(label: publicacion.juego.plataforma!),
                            _InfoChip(
                              label: publicacion.inventario.estadoLabel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (publicacion.descripcion.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(publicacion.descripcion),
              ],
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (precioLabel != null)
                    Text(
                      precioLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    )
                  else
                    Text(
                      'Intercambio',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Detalle'),
                      ),
                      _InterestButton(
                        isOwnPublication: isOwnPublication,
                        hasInterest: hasInterest,
                        isSubmitting: isSubmittingInterest,
                        onPressed: onInterestPressed,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameImage extends StatelessWidget {
  const _GameImage(this.imageUrl);

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 84,
        height: 84,
        color: colorScheme.secondaryContainer,
        child: imageUrl == null
            ? Icon(
                Icons.sports_esports,
                color: colorScheme.onSecondaryContainer,
                size: 34,
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.sports_esports,
                    color: colorScheme.onSecondaryContainer,
                    size: 34,
                  );
                },
              ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InterestButton extends StatelessWidget {
  const _InterestButton({
    required this.isOwnPublication,
    required this.hasInterest,
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isOwnPublication;
  final bool hasInterest;
  final bool isSubmitting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (isOwnPublication) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.person_outline),
        label: const Text('Tuya'),
      );
    }

    if (hasInterest) {
      return FilledButton.tonalIcon(
        onPressed: null,
        icon: const Icon(Icons.favorite),
        label: const Text('Enviado'),
      );
    }

    return OutlinedButton.icon(
      onPressed: isSubmitting ? null : onPressed,
      icon: isSubmitting
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.favorite_border),
      label: const Text('Me interesa'),
    );
  }
}
