import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../publications/domain/publicacion.dart';
import '../../domain/oferta.dart';
import '../controllers/publicacion_detail_controller.dart';
import '../widgets/oferta_card.dart';

class PublicationDetailScreen extends ConsumerStatefulWidget {
  const PublicationDetailScreen({required this.publicacionId, super.key});

  final String publicacionId;

  @override
  ConsumerState<PublicationDetailScreen> createState() =>
      _PublicationDetailScreenState();
}

class _PublicationDetailScreenState
    extends ConsumerState<PublicationDetailScreen> {
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _loadedPublicacionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureLoaded();
    });
  }

  @override
  void didUpdateWidget(covariant PublicationDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.publicacionId != widget.publicacionId) {
      _loadedPublicacionId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureLoaded();
      });
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final state = ref.watch(publicacionDetailControllerProvider);
    final publicacion = state.publicacion;

    if (publicacion == null && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (publicacion == null && state.hasError) {
      return _DetailErrorState(
        message: state.errorMessage!,
        onRetry: _ensureLoaded,
      );
    }

    if (publicacion == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentUserId = authState.usuario?.id;
    final isOwner = publicacion.usuario.id == currentUserId;
    final offerUserId = currentUserId;
    final canOffer =
        !isOwner &&
        publicacion.inventario.estado == 'en_venta' &&
        offerUserId != null;
    final visibleOffers = isOwner
        ? state.ofertas
        : state.ofertas
              .where((oferta) => oferta.usuario.id == currentUserId)
              .toList();

    return RefreshIndicator(
      onRefresh: ref.read(publicacionDetailControllerProvider.notifier).refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.isLoading) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                  ],
                  _PublicationHero(publicacion: publicacion),
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: 'Juego',
                    subtitle:
                        'Informacion ampliada y estado actual del anuncio.',
                  ),
                  const SizedBox(height: 12),
                  _GameDetailsCard(publicacion: publicacion),
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: 'Propietario',
                    subtitle: 'Datos visibles del usuario que publica.',
                  ),
                  const SizedBox(height: 12),
                  _OwnerCard(publicacion: publicacion),
                  const SizedBox(height: 24),
                  if (canOffer) ...[
                    _SectionTitle(
                      title: 'Enviar oferta',
                      subtitle:
                          'Disponible porque la publicacion esta en venta.',
                    ),
                    const SizedBox(height: 12),
                    _OfferFormCard(
                      formKey: _formKey,
                      priceController: _priceController,
                      messageController: _messageController,
                      isSubmitting: state.isSubmittingOferta,
                      onSubmit: () =>
                          _submitOferta(offerUserId, publicacion.id),
                    ),
                    const SizedBox(height: 24),
                  ] else if (!isOwner) ...[
                    const _OfferAvailabilityCard(),
                    const SizedBox(height: 24),
                  ],
                  _SectionTitle(
                    title: 'Ofertas',
                    subtitle: isOwner
                        ? 'Puedes aceptar o rechazar ofertas pendientes.'
                        : 'Aqui veras las ofertas que hayas enviado para esta publicacion.',
                  ),
                  const SizedBox(height: 12),
                  if (visibleOffers.isEmpty)
                    EmptyState(
                      icon: Icons.swap_horiz,
                      title: 'Sin ofertas',
                      description: isOwner
                          ? 'Todavia no hay ofertas registradas para esta publicacion.'
                          : 'Aun no has enviado ofertas para esta publicacion.',
                    )
                  else
                    ...visibleOffers.map(
                      (oferta) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: OfertaCard(
                          oferta: oferta,
                          isOwner: isOwner,
                          isMine: oferta.usuario.id == currentUserId,
                          isUpdating: state.updatingOfferIds.contains(
                            oferta.id,
                          ),
                          onAccept: () => _updateOfertaEstado(
                            oferta.id,
                            OfertaEstado.aceptada,
                          ),
                          onReject: () => _updateOfertaEstado(
                            oferta.id,
                            OfertaEstado.rechazada,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _ensureLoaded() {
    if (_loadedPublicacionId == widget.publicacionId) {
      return;
    }

    _loadedPublicacionId = widget.publicacionId;
    ref
        .read(publicacionDetailControllerProvider.notifier)
        .load(widget.publicacionId);
  }

  Future<void> _submitOferta(String usuarioId, String publicacionId) async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final precio = double.parse(_priceController.text.replaceAll(',', '.'));
    final error = await ref
        .read(publicacionDetailControllerProvider.notifier)
        .enviarOferta(
          usuarioId: usuarioId,
          publicacionId: publicacionId,
          precioOfrecido: precio,
          mensaje: _messageController.text.trim().isEmpty
              ? null
              : _messageController.text.trim(),
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error ?? 'Oferta enviada correctamente.')),
      );

    if (error == null) {
      _priceController.clear();
      _messageController.clear();
    }
  }

  Future<void> _updateOfertaEstado(String ofertaId, OfertaEstado estado) async {
    final error = await ref
        .read(publicacionDetailControllerProvider.notifier)
        .actualizarEstadoOferta(ofertaId: ofertaId, estado: estado);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error ??
                'Oferta ${estado == OfertaEstado.aceptada ? 'aceptada' : 'rechazada'} correctamente.',
          ),
        ),
      );
  }
}

class _PublicationHero extends StatelessWidget {
  const _PublicationHero({required this.publicacion});

  final Publicacion publicacion;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 112,
                height: 112,
                color: colorScheme.secondaryContainer,
                child: publicacion.juego.imagenUrl == null
                    ? Icon(
                        Icons.public,
                        color: colorScheme.onSecondaryContainer,
                        size: 38,
                      )
                    : Image.network(
                        publicacion.juego.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.public,
                            color: colorScheme.onSecondaryContainer,
                            size: 38,
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    publicacion.juego.nombre,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(label: publicacion.juego.tipoLabel),
                      _MetaChip(label: publicacion.inventario.estadoLabel),
                      if (publicacion.juego.plataforma != null)
                        _MetaChip(label: publicacion.juego.plataforma!),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    publicacion.descripcion,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (publicacion.inventario.precioLabel != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  publicacion.inventario.precioLabel!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GameDetailsCard extends StatelessWidget {
  const _GameDetailsCard({required this.publicacion});

  final Publicacion publicacion;

  @override
  Widget build(BuildContext context) {
    final juego = publicacion.juego;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                if (juego.jugadoresLabel != null)
                  _DetailItem(
                    icon: Icons.groups_outlined,
                    label: juego.jugadoresLabel!,
                  ),
                if (juego.duracionLabel != null)
                  _DetailItem(
                    icon: Icons.schedule_outlined,
                    label: juego.duracionLabel!,
                  ),
                if (juego.codigoBarras != null)
                  _DetailItem(
                    icon: Icons.qr_code_2_outlined,
                    label: juego.codigoBarras!,
                  ),
              ],
            ),
            if (juego.descripcion != null) ...[
              const SizedBox(height: 14),
              Text(
                juego.descripcion!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.publicacion});

  final Publicacion publicacion;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(publicacion.usuario.nombre),
        subtitle: Text('Propietario de la publicación'),
      ),
    );
  }
}

class _OfferFormCard extends StatelessWidget {
  const _OfferFormCard({
    required this.formKey,
    required this.priceController,
    required this.messageController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController priceController;
  final TextEditingController messageController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio ofrecido',
                  prefixIcon: Icon(Icons.euro_outlined),
                ),
                validator: (value) {
                  final text = (value ?? '').trim().replaceAll(',', '.');
                  final parsed = double.tryParse(text);

                  if (text.isEmpty) {
                    return 'Introduce un precio';
                  }

                  if (parsed == null || parsed <= 0) {
                    return 'Introduce un importe valido';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: messageController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mensaje (opcional)',
                  prefixIcon: Icon(Icons.message_outlined),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Enviar oferta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferAvailabilityCard extends StatelessWidget {
  const _OfferAvailabilityCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(Icons.info_outline, color: colorScheme.primary),
        title: const Text('Esta publicacion no admite ofertas'),
        subtitle: const Text(
          'Solo las publicaciones marcadas como en venta permiten enviar ofertas.',
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

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

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmptyState(
                icon: Icons.error_outline,
                title: 'No se pudo cargar la publicación',
                description:
                    'Revisa la conexión y vuelve a intentarlo desde esta pantalla.',
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
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
