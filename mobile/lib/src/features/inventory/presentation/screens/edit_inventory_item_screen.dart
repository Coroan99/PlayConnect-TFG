import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/inventario_item.dart';
import '../controllers/edit_inventario_item_controller.dart';
import '../controllers/inventario_controller.dart';

class EditInventoryItemScreen extends ConsumerStatefulWidget {
  const EditInventoryItemScreen({required this.itemId, super.key});

  final String itemId;

  @override
  ConsumerState<EditInventoryItemScreen> createState() =>
      _EditInventoryItemScreenState();
}

class _EditInventoryItemScreenState
    extends ConsumerState<EditInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _publicationDescriptionController = TextEditingController();

  InventarioEstado? _selectedEstado;
  String? _hydratedSnapshotKey;
  String? _loadedItemId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItem();
    });
  }

  @override
  void didUpdateWidget(covariant EditInventoryItemScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.itemId != widget.itemId) {
      _loadedItemId = null;
      _hydratedSnapshotKey = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadItem();
      });
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _publicationDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editInventarioItemControllerProvider);
    final item = state.item;

    if (item == null && state.isLoadingItem) {
      return const Center(child: CircularProgressIndicator());
    }

    if (item == null && state.hasError) {
      return _EditInventoryErrorState(
        message: state.errorMessage!,
        onRetry: _retryLoadItem,
      );
    }

    if (item == null) {
      return const Center(child: CircularProgressIndicator());
    }

    _hydrateForm(item);

    final effectiveEstado = _selectedEstado ?? item.estado;
    final isEnVenta = effectiveEstado == InventarioEstado.enVenta;
    final canCreatePublication = effectiveEstado.puedePublicarse;
    final hasPublication = item.tienePublicacion;
    final shouldManagePublication = hasPublication || canCreatePublication;
    final publicationVisibilityLabel = canCreatePublication
        ? 'Visible en el feed principal'
        : 'Oculta en el feed mientras este en coleccion';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.isSubmitting) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                ],
                _GameSummaryCard(item: item, estado: effectiveEstado),
                const SizedBox(height: 24),
                _FormSection(
                  title: 'Estado del item',
                  subtitle:
                      'Define si el juego queda solo en tu coleccion, visible para intercambio o en venta.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<InventarioEstado>(
                        key: ValueKey(effectiveEstado),
                        initialValue: effectiveEstado,
                        decoration: const InputDecoration(
                          labelText: 'Estado del inventario',
                          prefixIcon: Icon(Icons.tune),
                        ),
                        items: InventarioEstado.values
                            .map(
                              (estado) => DropdownMenuItem(
                                value: estado,
                                child: Text(estado.label),
                              ),
                            )
                            .toList(),
                        onChanged: state.isSubmitting
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _selectedEstado = value;
                                });
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Selecciona un estado';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _HelperBanner(
                        icon: effectiveEstado == InventarioEstado.coleccion
                            ? Icons.visibility_off_outlined
                            : Icons.public_outlined,
                        message: effectiveEstado == InventarioEstado.coleccion
                            ? 'Los items en coleccion no aparecen en el feed, aunque puedan conservar una publicacion asociada.'
                            : 'Este estado forma parte del flujo publico de PlayConnect y se reflejara en el feed.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Precio',
                  subtitle:
                      'Solo es obligatorio cuando el item queda marcado como en venta.',
                  child: isEnVenta
                      ? TextFormField(
                          controller: _priceController,
                          enabled: !state.isSubmitting,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Precio de venta',
                            prefixIcon: Icon(Icons.sell_outlined),
                            suffixText: 'EUR',
                          ),
                          validator: _validatePrice,
                        )
                      : const _HelperBanner(
                          icon: Icons.info_outline,
                          message:
                              'Si el estado es coleccion o visible, el precio no se enviara al backend.',
                        ),
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Publicacion asociada',
                  subtitle:
                      'Cuando el item queda Visible o En venta, PlayConnect garantiza una publicacion asociada desde este mismo flujo.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (shouldManagePublication)
                        _PublicationStatusCard(
                          title: hasPublication
                              ? 'Publicacion ya creada'
                              : 'Se creara una publicacion al guardar',
                          description: publicationVisibilityLabel,
                          icon: canCreatePublication
                              ? Icons.public
                              : Icons.visibility_off_outlined,
                        )
                      else
                        const _HelperBanner(
                          icon: Icons.inventory_2_outlined,
                          message:
                              'Mientras el item permanezca en coleccion y no tenga publicacion previa, no se publicara en la comunidad.',
                        ),
                      if (shouldManagePublication) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _publicationDescriptionController,
                          enabled: !state.isSubmitting,
                          minLines: 4,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'Descripcion de la publicacion',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.description_outlined),
                            helperText:
                                'Opcional. Si la dejas vacia, se mantiene la actual o se genera una base automatica.',
                          ),
                          validator: (_) =>
                              _validatePublicationDescription(item),
                        ),
                      ],
                      if (hasPublication) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            TextButton.icon(
                              onPressed: () => context.pushNamed(
                                AppRoute.publicationDetail.name,
                                pathParameters: {'id': item.publicacion!.id},
                              ),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Ver publicacion actual'),
                            ),
                            if (!canCreatePublication)
                              const _InlineHint(
                                message:
                                    'La publicacion quedara oculta del feed hasta volver a estado Visible o En venta.',
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Guardar cambios',
                        icon: Icons.save_outlined,
                        isLoading: state.isSubmitting,
                        onPressed: () => _submit(item),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hydrateForm(InventarioItem item) {
    final snapshotKey = [
      item.id,
      item.estado.apiValue,
      item.precio?.toStringAsFixed(2) ?? '',
      item.updatedAt?.toIso8601String() ?? '',
      item.publicacion?.id ?? '',
      item.publicacion?.descripcion ?? '',
    ].join('|');

    if (_hydratedSnapshotKey == snapshotKey) {
      return;
    }

    _hydratedSnapshotKey = snapshotKey;
    _selectedEstado = item.estado;
    _priceController.text = item.precio?.toStringAsFixed(2) ?? '';
    _publicationDescriptionController.text =
        item.publicacion?.descripcion ?? '';
  }

  void _loadItem() {
    if (_loadedItemId == widget.itemId) {
      return;
    }

    _loadedItemId = widget.itemId;
    final inventoryItems = ref.read(inventarioControllerProvider).items;
    InventarioItem? fallbackItem;

    for (final item in inventoryItems) {
      if (item.id == widget.itemId) {
        fallbackItem = item;
        break;
      }
    }

    ref
        .read(editInventarioItemControllerProvider.notifier)
        .loadItem(itemId: widget.itemId, fallbackItem: fallbackItem);
  }

  void _retryLoadItem() {
    _loadedItemId = null;
    _loadItem();
  }

  Future<void> _submit(InventarioItem item) async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final estado = _selectedEstado;

    if (estado == null) {
      return;
    }

    FocusScope.of(context).unfocus();

    final precio = estado == InventarioEstado.enVenta
        ? _parsePrice(_priceController.text)
        : null;

    final error = await ref
        .read(editInventarioItemControllerProvider.notifier)
        .saveChanges(
          item: item,
          estado: estado,
          precio: precio,
          publicationDescription: _publicationDescriptionController.text,
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Item actualizado correctamente en el inventario.',
          ),
        ),
      );

    if (error == null) {
      context.pop(true);
    }
  }

  String? _validatePrice(String? value) {
    if ((_selectedEstado ?? InventarioEstado.coleccion) !=
        InventarioEstado.enVenta) {
      return null;
    }

    final normalizedValue = value?.trim() ?? '';

    if (normalizedValue.isEmpty) {
      return 'El precio es obligatorio cuando el estado es En venta';
    }

    final parsedValue = _parsePrice(normalizedValue);

    if (parsedValue == null) {
      return 'Introduce un precio valido';
    }

    if (parsedValue <= 0) {
      return 'El precio debe ser mayor que 0';
    }

    return null;
  }

  String? _validatePublicationDescription(InventarioItem item) {
    final shouldValidate =
        item.tienePublicacion ||
        (_selectedEstado ?? item.estado).puedePublicarse;

    if (!shouldValidate) {
      return null;
    }

    final value = _publicationDescriptionController.text.trim();

    if (value.length > 1000) {
      return 'La descripcion no puede superar los 1000 caracteres';
    }

    return null;
  }

  double? _parsePrice(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }
}

class _GameSummaryCard extends StatelessWidget {
  const _GameSummaryCard({required this.item, required this.estado});

  final InventarioItem item;
  final InventarioEstado estado;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 96,
                height: 96,
                color: colorScheme.secondaryContainer,
                child: item.juego.imagenUrl == null
                    ? Icon(
                        Icons.inventory_2_outlined,
                        color: colorScheme.onSecondaryContainer,
                        size: 36,
                      )
                    : Image.network(
                        item.juego.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.inventory_2_outlined,
                            color: colorScheme.onSecondaryContainer,
                            size: 36,
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.juego.nombre,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SummaryChip(label: item.juego.tipoLabel),
                      if (item.juego.plataforma != null)
                        _SummaryChip(label: item.juego.plataforma!),
                      _SummaryChip(label: estado.label),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.tienePublicacion
                        ? 'La publicacion asociada puede mantenerse sincronizada desde esta pantalla.'
                        : 'Puedes ajustar el estado, el precio y publicar el juego directamente desde el inventario.',
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

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _HelperBanner extends StatelessWidget {
  const _HelperBanner({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicationStatusCard extends StatelessWidget {
  const _PublicationStatusCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EditInventoryErrorState extends StatelessWidget {
  const _EditInventoryErrorState({
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_off_outlined,
                  color: colorScheme.onErrorContainer,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No se pudo cargar el item',
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
