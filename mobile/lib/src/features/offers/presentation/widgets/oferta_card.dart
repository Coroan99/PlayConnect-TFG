import 'package:flutter/material.dart';

import '../../domain/oferta.dart';

class OfertaCard extends StatelessWidget {
  const OfertaCard({
    required this.oferta,
    required this.isOwner,
    required this.isMine,
    required this.isUpdating,
    required this.onAccept,
    required this.onReject,
    super.key,
  });

  final Oferta oferta;
  final bool isOwner;
  final bool isMine;
  final bool isUpdating;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    oferta.usuario.nombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _EstadoChip(estado: oferta.estado),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              oferta.precioLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (oferta.mensaje != null) ...[
              const SizedBox(height: 8),
              Text(oferta.mensaje!),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.schedule_outlined,
                  label: _formatDate(oferta.createdAt),
                ),
                if (isMine)
                  const _MetaChip(
                    icon: Icons.person_outline,
                    label: 'Tu oferta',
                  ),
              ],
            ),
            if (isOwner && oferta.estaPendiente) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: isUpdating ? null : onAccept,
                    icon: isUpdating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Aceptar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isUpdating ? null : onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Rechazar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Fecha no disponible';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} $hour:$minute';
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});

  final OfertaEstado estado;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final colors = switch (estado) {
      OfertaEstado.aceptada => (
        background: colorScheme.tertiaryContainer,
        foreground: colorScheme.onTertiaryContainer,
      ),
      OfertaEstado.rechazada || OfertaEstado.cancelada => (
        background: colorScheme.errorContainer,
        foreground: colorScheme.onErrorContainer,
      ),
      OfertaEstado.pendiente => (
        background: colorScheme.primaryContainer,
        foreground: colorScheme.onPrimaryContainer,
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
