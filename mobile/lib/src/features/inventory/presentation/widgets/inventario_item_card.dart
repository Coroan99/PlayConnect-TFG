import 'package:flutter/material.dart';

import '../../domain/inventario_item.dart';

class InventarioItemCard extends StatelessWidget {
  const InventarioItemCard({
    required this.item,
    this.onEdit,
    this.onOpenPublication,
    super.key,
  });

  final InventarioItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onOpenPublication;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final precioLabel = item.precioLabel;
    final publicationLabel = switch ((item.tienePublicacion, item.estado)) {
      (true, InventarioEstado.coleccion) => 'Publicacion oculta',
      (true, _) => 'Publicada en comunidad',
      (false, _) => 'Sin publicacion',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GameImage(item.juego.imagenUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.juego.nombre,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(label: item.juego.tipoLabel),
                          if (item.juego.plataforma != null)
                            _InfoChip(label: item.juego.plataforma!),
                          _EstadoChip(estado: item.estado),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (item.juego.jugadoresLabel != null)
                  _MetaItem(
                    icon: Icons.groups_outlined,
                    label: item.juego.jugadoresLabel!,
                  ),
                if (item.juego.duracionLabel != null)
                  _MetaItem(
                    icon: Icons.schedule_outlined,
                    label: item.juego.duracionLabel!,
                  ),
                if (precioLabel != null)
                  _MetaItem(icon: Icons.sell_outlined, label: precioLabel),
                _MetaItem(
                  icon: item.tienePublicacion
                      ? Icons.public_outlined
                      : Icons.visibility_off_outlined,
                  label: publicationLabel,
                ),
              ],
            ),
            if (item.juego.descripcion != null) ...[
              const SizedBox(height: 12),
              Text(
                item.juego.descripcion!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                if (item.tienePublicacion)
                  TextButton.icon(
                    onPressed: onOpenPublication,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Ver publicacion'),
                  ),
              ],
            ),
          ],
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
                Icons.inventory_2,
                color: colorScheme.onSecondaryContainer,
                size: 34,
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.inventory_2,
                    color: colorScheme.onSecondaryContainer,
                    size: 34,
                  );
                },
              ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});

  final InventarioEstado estado;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final colors = switch (estado) {
      InventarioEstado.enVenta => (
        background: colorScheme.primaryContainer,
        foreground: colorScheme.onPrimaryContainer,
      ),
      InventarioEstado.visible => (
        background: colorScheme.tertiaryContainer,
        foreground: colorScheme.onTertiaryContainer,
      ),
      InventarioEstado.coleccion => (
        background: colorScheme.surfaceContainerHighest,
        foreground: colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        estado.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w700,
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

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
