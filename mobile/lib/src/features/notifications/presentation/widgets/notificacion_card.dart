import 'package:flutter/material.dart';

import '../../domain/notificacion.dart';

class NotificacionCard extends StatelessWidget {
  const NotificacionCard({
    required this.notificacion,
    required this.isMarkingRead,
    required this.onTap,
    required this.onMarkAsRead,
    super.key,
  });

  final Notificacion notificacion;
  final bool isMarkingRead;
  final VoidCallback onTap;
  final VoidCallback? onMarkAsRead;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visual = _visualFor(notificacion.tipo, colorScheme);
    final referencia = notificacion.referencia;

    return Card(
      color: notificacion.leida ? Colors.white : visual.background,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: visual.iconBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(visual.icon, color: visual.iconForeground),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notificacion.tipo.label,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (!notificacion.leida)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(notificacion.mensaje),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetaChip(
                          icon: Icons.schedule_outlined,
                          label: _formatDate(notificacion.createdAt),
                        ),
                        if (referencia != null)
                          _MetaChip(
                            icon: Icons.link_outlined,
                            label: referencia.label,
                          ),
                        if (notificacion.emisor != null)
                          _MetaChip(
                            icon: Icons.person_outline,
                            label: notificacion.emisor!.nombre,
                          ),
                      ],
                    ),
                    if (!notificacion.leida) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: isMarkingRead ? null : onMarkAsRead,
                          icon: isMarkingRead
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.done_all),
                          label: const Text('Marcar como leida'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _NotificationVisual _visualFor(
    NotificacionTipo tipo,
    ColorScheme colorScheme,
  ) {
    return switch (tipo) {
      NotificacionTipo.ofertaRecibida => _NotificationVisual(
        icon: Icons.swap_horiz,
        background: colorScheme.primaryContainer.withValues(alpha: 0.20),
        iconBackground: colorScheme.primaryContainer,
        iconForeground: colorScheme.onPrimaryContainer,
      ),
      NotificacionTipo.ofertaAceptada => _NotificationVisual(
        icon: Icons.check_circle_outline,
        background: colorScheme.tertiaryContainer.withValues(alpha: 0.24),
        iconBackground: colorScheme.tertiaryContainer,
        iconForeground: colorScheme.onTertiaryContainer,
      ),
      NotificacionTipo.ofertaRechazada => _NotificationVisual(
        icon: Icons.cancel_outlined,
        background: colorScheme.errorContainer.withValues(alpha: 0.22),
        iconBackground: colorScheme.errorContainer,
        iconForeground: colorScheme.onErrorContainer,
      ),
      NotificacionTipo.interesNuevo => _NotificationVisual(
        icon: Icons.favorite_border,
        background: colorScheme.secondaryContainer.withValues(alpha: 0.24),
        iconBackground: colorScheme.secondaryContainer,
        iconForeground: colorScheme.onSecondaryContainer,
      ),
      NotificacionTipo.muchoInteres => _NotificationVisual(
        icon: Icons.trending_up,
        background: colorScheme.primaryContainer.withValues(alpha: 0.20),
        iconBackground: colorScheme.primaryContainer,
        iconForeground: colorScheme.onPrimaryContainer,
      ),
      NotificacionTipo.desconocida => _NotificationVisual(
        icon: Icons.notifications_outlined,
        background: colorScheme.surfaceContainerHighest,
        iconBackground: colorScheme.surfaceContainerHighest,
        iconForeground: colorScheme.onSurfaceVariant,
      ),
    };
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

class _NotificationVisual {
  const _NotificationVisual({
    required this.icon,
    required this.background,
    required this.iconBackground,
    required this.iconForeground,
  });

  final IconData icon;
  final Color background;
  final Color iconBackground;
  final Color iconForeground;
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
