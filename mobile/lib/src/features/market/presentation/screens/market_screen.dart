import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../publications/domain/publicacion.dart';
import '../../../publications/presentation/controllers/publicaciones_controller.dart';
import '../../../publications/presentation/widgets/publicacion_card.dart';
import '../controllers/mercado_local_controller.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIfIdle();
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final publicacionesState = ref.watch(publicacionesControllerProvider);
    final marketState = ref.watch(mercadoLocalControllerProvider);
    final marketView = ref.watch(mercadoLocalViewProvider);
    final publicacionesController = ref.read(
      publicacionesControllerProvider.notifier,
    );
    final marketController = ref.read(mercadoLocalControllerProvider.notifier);

    if (publicacionesState.isLoading &&
        publicacionesState.publicaciones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (publicacionesState.hasError &&
        publicacionesState.publicaciones.isEmpty) {
      return _MarketErrorState(
        message: publicacionesState.errorMessage!,
        onRetry: publicacionesController.loadPublicaciones,
      );
    }

    final userName = authState.usuario?.nombre ?? 'jugador';
    final hasAnyPublication = publicacionesState.publicaciones.any(
      (publicacion) => publicacion.usuario.id != authState.usuario?.id,
    );

    return RefreshIndicator(
      onRefresh: publicacionesController.refresh,
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
                  _MarketHeader(
                    userName: userName,
                    selectedCity: marketView.selectedCity,
                    isRefreshing: publicacionesState.isLoading,
                    hasRealCityData: marketView.hasRealCityData,
                  ),
                  const SizedBox(height: 18),
                  _CityFilterCard(
                    availableCities: marketView.availableCities,
                    selectedCity: marketView.selectedCity,
                    onSelected: marketController.selectCity,
                  ),
                  const SizedBox(height: 18),
                  if (!marketView.hasRealCityData) const _FallbackInfoCard(),
                  if (!marketView.hasRealCityData) const SizedBox(height: 18),
                  if (!hasAnyPublication)
                    const _MarketEmptyState(
                      title: 'Sin publicaciones en la comunidad',
                      description:
                          'Cuando otros usuarios publiquen juegos visibles o en venta, apareceran aqui.',
                    )
                  else if (marketView.publicaciones.isEmpty)
                    _MarketEmptyState(
                      title: 'Sin publicaciones en ${marketView.selectedCity}',
                      description:
                          'Todavia no hay juegos visibles o en venta para esa ciudad.',
                    )
                  else
                    ...marketView.publicaciones.map(
                      (publicacion) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PublicacionCard(
                          publicacion: publicacion,
                          isOwnPublication: false,
                          hasInterest: publicacionesState
                              .interestedPublicationIds
                              .contains(publicacion.id),
                          isSubmittingInterest: publicacionesState
                              .processingInterestIds
                              .contains(publicacion.id),
                          cityLabel: publicacion.usuario.ciudadOrDefault(
                            defaultMarketCity,
                          ),
                          isSubmittingOffer: marketState.isSubmittingOffer(
                            publicacion.id,
                          ),
                          onTap: () => context.pushNamed(
                            AppRoute.publicationDetail.name,
                            pathParameters: {'id': publicacion.id},
                          ),
                          onInterestPressed: authState.usuario == null
                              ? null
                              : () => _registrarInteres(
                                  context,
                                  authState.usuario!.id,
                                  publicacion.id,
                                ),
                          onOfferPressed:
                              authState.usuario == null ||
                                  publicacion.inventario.estado != 'en_venta'
                              ? null
                              : () => _openOfferSheet(
                                  publicacion: publicacion,
                                  usuarioId: authState.usuario!.id,
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

  void _refreshIfIdle() {
    final state = ref.read(publicacionesControllerProvider);

    if (state.isLoading) {
      return;
    }

    ref.read(publicacionesControllerProvider.notifier).refresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) {
        return;
      }

      _refreshIfIdle();
    });
  }

  Future<void> _registrarInteres(
    BuildContext context,
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

  Future<void> _openOfferSheet({
    required Publicacion publicacion,
    required String usuarioId,
  }) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _OfferBottomSheet(
          publicacion: publicacion,
          usuarioId: usuarioId,
        );
      },
    );

    if (!mounted || created != true) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Oferta enviada correctamente para ${publicacion.juego.nombre}.',
          ),
        ),
      );
  }
}

class _MarketHeader extends StatelessWidget {
  const _MarketHeader({
    required this.userName,
    required this.selectedCity,
    required this.isRefreshing,
    required this.hasRealCityData,
  });

  final String userName;
  final String selectedCity;
  final bool isRefreshing;
  final bool hasRealCityData;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
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
                    'Mercado local',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explora lo que la comunidad de $selectedCity esta publicando cerca de ti, $userName.',
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HeaderPill(icon: Icons.location_on_outlined, label: selectedCity),
            _HeaderPill(icon: Icons.refresh, label: 'Auto-refresh 30 s'),
            _HeaderPill(
              icon: hasRealCityData
                  ? Icons.approval_outlined
                  : Icons.tune_outlined,
              label: hasRealCityData
                  ? 'Ubicacion real detectada'
                  : 'Fallback de ciudad activo',
            ),
          ],
        ),
      ],
    );
  }
}

class _CityFilterCard extends StatelessWidget {
  const _CityFilterCard({
    required this.availableCities,
    required this.selectedCity,
    required this.onSelected,
  });

  final List<String> availableCities;
  final String selectedCity;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrar por ciudad',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'El mercado se centra en la ciudad seleccionada para reforzar la idea de comunidad local.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: availableCities.map((city) {
                return ChoiceChip(
                  label: Text(city),
                  selected: city == selectedCity,
                  onSelected: (_) => onSelected(city),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackInfoCard extends StatelessWidget {
  const _FallbackInfoCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(Icons.info_outline, color: colorScheme.primary),
        title: const Text('Ubicacion demo activa'),
        subtitle: const Text(
          'Todavia no hay ciudad real en el backend para publicaciones o usuarios. El mercado usa Córdoba como valor por defecto sin romper el flujo futuro.',
        ),
      ),
    );
  }
}

class _MarketEmptyState extends StatelessWidget {
  const _MarketEmptyState({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: EmptyState(
        icon: Icons.storefront_outlined,
        title: title,
        description: description,
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferBottomSheet extends ConsumerStatefulWidget {
  const _OfferBottomSheet({required this.publicacion, required this.usuarioId});

  final Publicacion publicacion;
  final String usuarioId;

  @override
  ConsumerState<_OfferBottomSheet> createState() => _OfferBottomSheetState();
}

class _OfferBottomSheetState extends ConsumerState<_OfferBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref
        .watch(mercadoLocalControllerProvider)
        .isSubmittingOffer(widget.publicacion.id);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enviar oferta',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Oferta para ${widget.publicacion.juego.nombre} en ${widget.publicacion.usuario.ciudadOrDefault(defaultMarketCity)}.',
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _priceController,
              enabled: !isSubmitting,
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
              controller: _messageController,
              enabled: !isSubmitting,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mensaje (opcional)',
                prefixIcon: Icon(Icons.message_outlined),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Enviar oferta',
                    icon: Icons.send,
                    isLoading: isSubmitting,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final precio = double.parse(
      _priceController.text.trim().replaceAll(',', '.'),
    );
    final error = await ref
        .read(mercadoLocalControllerProvider.notifier)
        .enviarOferta(
          usuarioId: widget.usuarioId,
          publicacionId: widget.publicacion.id,
          precioOfrecido: precio,
          mensaje: _messageController.text.trim().isEmpty
              ? null
              : _messageController.text.trim(),
        );

    if (!mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.of(context).pop(true);
  }
}

class _MarketErrorState extends StatelessWidget {
  const _MarketErrorState({required this.message, required this.onRetry});

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
                  Icons.storefront_outlined,
                  color: colorScheme.onErrorContainer,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No se pudo cargar el mercado',
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
