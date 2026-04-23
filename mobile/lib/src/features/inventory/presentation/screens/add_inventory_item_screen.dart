import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../games/domain/juego_catalogo.dart';
import '../../domain/inventario_item.dart';
import '../controllers/add_inventario_item_controller.dart';
import 'barcode_scanner_screen.dart';

enum AddGameMode { existente, manual }

class AddInventoryItemScreen extends ConsumerStatefulWidget {
  const AddInventoryItemScreen({super.key});

  @override
  ConsumerState<AddInventoryItemScreen> createState() =>
      _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState
    extends ConsumerState<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _platformController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _playersMinController = TextEditingController();
  final _playersMaxController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();

  AddGameMode _mode = AddGameMode.existente;
  JuegoTipo _tipo = JuegoTipo.videojuego;
  InventarioEstado _estado = InventarioEstado.coleccion;
  String? _selectedJuegoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addInventarioItemControllerProvider.notifier).loadCatalog();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _platformController.dispose();
    _barcodeController.dispose();
    _imageUrlController.dispose();
    _playersMinController.dispose();
    _playersMaxController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(authControllerProvider).usuario;
    final state = ref.watch(addInventarioItemControllerProvider);

    if (usuario == null) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Sesion no disponible',
        description: 'Vuelve a iniciar sesion para anadir juegos.',
      );
    }

    final filteredJuegos = state.juegos
        .where((juego) => juego.matchesQuery(_searchController.text))
        .toList();
    final selectedJuego = state.juegos
        .where((juego) => juego.id == _selectedJuegoId)
        .firstOrNull;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.isLoadingCatalog ||
                      state.isLookingUpBarcode ||
                      state.isSubmitting) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Anadir juego',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Busca un juego existente o crea uno manualmente y guardalo en tu inventario.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: 'Modo de alta',
                    subtitle:
                        'Elige si quieres reutilizar un juego ya creado o registrar uno nuevo.',
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SegmentedButton<AddGameMode>(
                            segments: const [
                              ButtonSegment(
                                value: AddGameMode.existente,
                                icon: Icon(Icons.search),
                                label: Text('Buscar existente'),
                              ),
                              ButtonSegment(
                                value: AddGameMode.manual,
                                icon: Icon(Icons.add_box_outlined),
                                label: Text('Crear manualmente'),
                              ),
                            ],
                            selected: {_mode},
                            onSelectionChanged: (selection) {
                              setState(() {
                                _mode = selection.first;
                                if (_mode == AddGameMode.manual &&
                                    _nameController.text.trim().isEmpty &&
                                    _searchController.text.trim().isNotEmpty) {
                                  _nameController.text = _searchController.text
                                      .trim();
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.icon(
                                onPressed:
                                    state.isLookingUpBarcode ||
                                        state.isSubmitting
                                    ? null
                                    : _openScannerAndResolve,
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Escanear codigo'),
                              ),
                              if (state.lastScannedBarcode != null)
                                OutlinedButton.icon(
                                  onPressed:
                                      state.isLookingUpBarcode ||
                                          state.isSubmitting
                                      ? null
                                      : () => _resolveBarcode(
                                          state.lastScannedBarcode!,
                                        ),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reconsultar codigo'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (state.lastScannedBarcode != null &&
                      (state.barcodeNotFound ||
                          state.barcodeLookupJuego != null ||
                          state.barcodeLookupErrorMessage != null)) ...[
                    _BarcodeLookupStatusCard(
                      state: state,
                      onRetryLookup: () =>
                          _resolveBarcode(state.lastScannedBarcode!),
                      onScanAgain: _openScannerAndResolve,
                      onCreateManual: state.barcodeNotFound
                          ? () {
                              setState(() {
                                _applyBarcodeNotFound(
                                  state.lastScannedBarcode!,
                                );
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_mode == AddGameMode.existente)
                    _ExistingGameSection(
                      searchController: _searchController,
                      juegos: filteredJuegos,
                      selectedJuegoId: _selectedJuegoId,
                      selectedJuego: selectedJuego,
                      isLoading: state.isLoadingCatalog,
                      errorMessage: state.catalogErrorMessage,
                      onSearchChanged: (_) => setState(() {}),
                      onRetry: () {
                        ref
                            .read(addInventarioItemControllerProvider.notifier)
                            .loadCatalog(force: true);
                      },
                      onSwitchToManual: () {
                        setState(() {
                          _mode = AddGameMode.manual;
                          if (_nameController.text.trim().isEmpty) {
                            _nameController.text = _searchController.text
                                .trim();
                          }
                        });
                      },
                      onSelected: (juegoId) {
                        setState(() {
                          _selectedJuegoId = juegoId;
                        });
                      },
                    )
                  else
                    _ManualGameSection(
                      tipo: _tipo,
                      nameController: _nameController,
                      platformController: _platformController,
                      barcodeController: _barcodeController,
                      imageUrlController: _imageUrlController,
                      playersMinController: _playersMinController,
                      playersMaxController: _playersMaxController,
                      durationController: _durationController,
                      onTipoChanged: (tipo) {
                        setState(() {
                          _tipo = tipo;
                          if (_tipo != JuegoTipo.videojuego) {
                            _platformController.clear();
                          }
                        });
                      },
                    ),
                  const SizedBox(height: 24),
                  _InventoryConfigSection(
                    estado: _estado,
                    priceController: _priceController,
                    onEstadoChanged: (estado) {
                      setState(() {
                        _estado = estado;
                        if (_estado != InventarioEstado.enVenta) {
                          _priceController.clear();
                        }
                      });
                    },
                    validatePrice: _validatePrice,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.isSubmitting
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Guardar en inventario',
                          icon: Icons.save_outlined,
                          isLoading: state.isSubmitting,
                          onPressed: () => _submit(usuario.id),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(String usuarioId) async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    String? errorMessage;

    if (_mode == AddGameMode.existente) {
      final juegoId = _selectedJuegoId;

      if (juegoId == null || juegoId.isEmpty) {
        _showMessage('Selecciona un juego del catalogo.');
        return;
      }

      errorMessage = await ref
          .read(addInventarioItemControllerProvider.notifier)
          .addExistingGameToInventory(
            usuarioId: usuarioId,
            juegoId: juegoId,
            estado: _estado,
            precio: _parseOptionalDouble(_priceController.text),
          );
    } else {
      errorMessage = await ref
          .read(addInventarioItemControllerProvider.notifier)
          .createGameAndAddToInventory(
            usuarioId: usuarioId,
            nombre: _nameController.text.trim(),
            tipo: _tipo,
            estado: _estado,
            plataforma: _tipo == JuegoTipo.videojuego
                ? _normalizedOrNull(_platformController.text)
                : null,
            codigoBarras: _normalizedOrNull(_barcodeController.text),
            imagenUrl: _normalizedOrNull(_imageUrlController.text),
            jugadoresMin: _parseOptionalInt(_playersMinController.text),
            jugadoresMax: _parseOptionalInt(_playersMaxController.text),
            duracionMinutos: _parseOptionalInt(_durationController.text),
            precio: _parseOptionalDouble(_priceController.text),
          );
    }

    if (!mounted) {
      return;
    }

    _showMessage(errorMessage ?? 'Juego anadido al inventario correctamente.');

    if (errorMessage == null) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openScannerAndResolve() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (!mounted || barcode == null || barcode.trim().isEmpty) {
      return;
    }

    await _resolveBarcode(barcode.trim());
  }

  Future<void> _resolveBarcode(String barcode) async {
    final result = await ref
        .read(addInventarioItemControllerProvider.notifier)
        .lookupGameByBarcode(barcode);

    if (!mounted) {
      return;
    }

    if (result.isFound && result.juego != null) {
      _applyExistingGame(result.juego!, barcode: barcode);
      _showMessage('Juego encontrado en el catalogo.');
      return;
    }

    if (result.isNotFound) {
      setState(() {
        _applyBarcodeNotFound(barcode);
      });
      _showMessage(
        'No existe un juego con ese codigo. Completa el alta manual.',
      );
      return;
    }

    _showMessage(result.message ?? 'No se pudo consultar el codigo.');
  }

  void _applyExistingGame(JuegoCatalogo juego, {required String barcode}) {
    setState(() {
      _mode = AddGameMode.existente;
      _selectedJuegoId = juego.id;
      _searchController.text = juego.nombre;
      _barcodeController.text = barcode;
      _nameController.clear();
      _platformController.clear();
      _imageUrlController.clear();
      _playersMinController.clear();
      _playersMaxController.clear();
      _durationController.clear();
    });
  }

  void _applyBarcodeNotFound(String barcode) {
    _mode = AddGameMode.manual;
    _selectedJuegoId = null;
    _barcodeController.text = barcode;
    if (_nameController.text.trim().isEmpty &&
        _searchController.text.trim().isNotEmpty) {
      _nameController.text = _searchController.text.trim();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  int? _parseOptionalInt(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return int.tryParse(normalized);
  }

  double? _parseOptionalDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');

    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }

  String? _normalizedOrNull(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String? _validatePrice(String? value) {
    if (_estado != InventarioEstado.enVenta) {
      return null;
    }

    final normalized = (value ?? '').trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);

    if (normalized.isEmpty) {
      return 'Introduce un precio';
    }

    if (parsed == null || parsed <= 0) {
      return 'Introduce un importe valido';
    }

    return null;
  }
}

class _BarcodeLookupStatusCard extends StatelessWidget {
  const _BarcodeLookupStatusCard({
    required this.state,
    required this.onRetryLookup,
    required this.onScanAgain,
    this.onCreateManual,
  });

  final AddInventarioItemState state;
  final VoidCallback onRetryLookup;
  final VoidCallback onScanAgain;
  final VoidCallback? onCreateManual;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barcode = state.lastScannedBarcode ?? '';

    late final Color background;
    late final Color foreground;
    late final IconData icon;
    late final String title;
    late final String description;

    if (state.hasBarcodeLookupSuccess) {
      background = colorScheme.tertiaryContainer;
      foreground = colorScheme.onTertiaryContainer;
      icon = Icons.check_circle_outline;
      title = 'Juego encontrado';
      description =
          'El codigo $barcode corresponde a ${state.barcodeLookupJuego!.nombre}. Puedes anadirlo directamente al inventario.';
    } else if (state.barcodeNotFound) {
      background = colorScheme.secondaryContainer;
      foreground = colorScheme.onSecondaryContainer;
      icon = Icons.info_outline;
      title = 'Codigo no encontrado';
      description =
          'No existe un juego registrado con el codigo $barcode. Se ha preparado el formulario manual con ese valor.';
    } else {
      background = colorScheme.errorContainer;
      foreground = colorScheme.onErrorContainer;
      icon = Icons.error_outline;
      title = 'No se pudo consultar el codigo';
      description =
          state.barcodeLookupErrorMessage ??
          'Ha ocurrido un error al consultar el codigo $barcode.';
    }

    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: foreground),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onScanAgain,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear otro'),
                ),
                if (!state.hasBarcodeLookupSuccess)
                  OutlinedButton.icon(
                    onPressed: onRetryLookup,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                if (onCreateManual != null)
                  OutlinedButton.icon(
                    onPressed: onCreateManual,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Alta manual'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExistingGameSection extends StatelessWidget {
  const _ExistingGameSection({
    required this.searchController,
    required this.juegos,
    required this.selectedJuegoId,
    required this.selectedJuego,
    required this.isLoading,
    required this.errorMessage,
    required this.onSearchChanged,
    required this.onRetry,
    required this.onSwitchToManual,
    required this.onSelected,
  });

  final TextEditingController searchController;
  final List<JuegoCatalogo> juegos;
  final String? selectedJuegoId;
  final JuegoCatalogo? selectedJuego;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRetry;
  final VoidCallback onSwitchToManual;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final visibleGames = juegos.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Juego existente',
          subtitle: 'Busca por nombre, plataforma o codigo de barras.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: searchController,
                  label: 'Buscar juego',
                  prefixIcon: Icons.search,
                  onChanged: onSearchChanged,
                ),
                if (selectedJuego != null) ...[
                  const SizedBox(height: 16),
                  _SelectedGameCard(juego: selectedJuego!),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _InlineErrorCard(message: errorMessage!, onRetry: onRetry),
                ] else if (!isLoading && visibleGames.isEmpty) ...[
                  const SizedBox(height: 16),
                  _EmptyCatalogCard(),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: onSwitchToManual,
                      icon: const Icon(Icons.add_box_outlined),
                      label: const Text('Crear juego nuevo'),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Text(
                    'Resultados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...visibleGames.map(
                    (juego) => _ExistingGameTile(
                      juego: juego,
                      selectedJuegoId: selectedJuegoId,
                      isSelected: juego.id == selectedJuegoId,
                      onSelected: () => onSelected(juego.id),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ManualGameSection extends StatelessWidget {
  const _ManualGameSection({
    required this.tipo,
    required this.nameController,
    required this.platformController,
    required this.barcodeController,
    required this.imageUrlController,
    required this.playersMinController,
    required this.playersMaxController,
    required this.durationController,
    required this.onTipoChanged,
  });

  final JuegoTipo tipo;
  final TextEditingController nameController;
  final TextEditingController platformController;
  final TextEditingController barcodeController;
  final TextEditingController imageUrlController;
  final TextEditingController playersMinController;
  final TextEditingController playersMaxController;
  final TextEditingController durationController;
  final ValueChanged<JuegoTipo> onTipoChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Nuevo juego',
          subtitle:
              'Completa los datos basicos para crear el juego manualmente.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: nameController,
                  label: 'Nombre',
                  prefixIcon: Icons.sports_esports_outlined,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SegmentedButton<JuegoTipo>(
                  segments: const [
                    ButtonSegment(
                      value: JuegoTipo.videojuego,
                      icon: Icon(Icons.videogame_asset_outlined),
                      label: Text('Videojuego'),
                    ),
                    ButtonSegment(
                      value: JuegoTipo.juegoMesa,
                      icon: Icon(Icons.casino_outlined),
                      label: Text('Juego de mesa'),
                    ),
                  ],
                  selected: {tipo},
                  onSelectionChanged: (selection) {
                    onTipoChanged(selection.first);
                  },
                ),
                if (tipo == JuegoTipo.videojuego) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: platformController,
                    label: 'Plataforma (opcional)',
                    prefixIcon: Icons.devices_outlined,
                  ),
                ],
                const SizedBox(height: 16),
                AppTextField(
                  controller: barcodeController,
                  label: 'Codigo de barras (opcional)',
                  prefixIcon: Icons.qr_code_2_outlined,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: imageUrlController,
                  label: 'URL de imagen (opcional)',
                  prefixIcon: Icons.image_outlined,
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    final normalized = (value ?? '').trim();

                    if (normalized.isEmpty) {
                      return null;
                    }

                    final uri = Uri.tryParse(normalized);

                    if (uri == null ||
                        (!uri.isScheme('http') && !uri.isScheme('https'))) {
                      return 'Introduce una URL valida';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 180,
                      child: AppTextField(
                        controller: playersMinController,
                        label: 'Jugadores min (opcional)',
                        prefixIcon: Icons.group_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            _validatePositiveInt(value, label: 'jugadores min'),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: AppTextField(
                        controller: playersMaxController,
                        label: 'Jugadores max (opcional)',
                        prefixIcon: Icons.groups_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final error = _validatePositiveInt(
                            value,
                            label: 'jugadores max',
                          );

                          if (error != null) {
                            return error;
                          }

                          final min = int.tryParse(
                            playersMinController.text.trim(),
                          );
                          final max = int.tryParse((value ?? '').trim());

                          if (min != null && max != null && min > max) {
                            return 'Max debe ser mayor o igual que min';
                          }

                          return null;
                        },
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: AppTextField(
                        controller: durationController,
                        label: 'Duracion min (opcional)',
                        prefixIcon: Icons.schedule_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            _validatePositiveInt(value, label: 'duracion'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String? _validatePositiveInt(String? value, {required String label}) {
    final normalized = (value ?? '').trim();

    if (normalized.isEmpty) {
      return null;
    }

    final parsed = int.tryParse(normalized);

    if (parsed == null || parsed < 0) {
      return 'Introduce un numero valido para $label';
    }

    return null;
  }
}

class _InventoryConfigSection extends StatelessWidget {
  const _InventoryConfigSection({
    required this.estado,
    required this.priceController,
    required this.onEstadoChanged,
    required this.validatePrice,
  });

  final InventarioEstado estado;
  final TextEditingController priceController;
  final ValueChanged<InventarioEstado> onEstadoChanged;
  final String? Function(String?) validatePrice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Inventario',
          subtitle: 'Define como se guardara el juego en tu cuenta.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<InventarioEstado>(
                  segments: const [
                    ButtonSegment(
                      value: InventarioEstado.coleccion,
                      icon: Icon(Icons.inventory_2_outlined),
                      label: Text('Coleccion'),
                    ),
                    ButtonSegment(
                      value: InventarioEstado.visible,
                      icon: Icon(Icons.visibility_outlined),
                      label: Text('Visible'),
                    ),
                    ButtonSegment(
                      value: InventarioEstado.enVenta,
                      icon: Icon(Icons.sell_outlined),
                      label: Text('En venta'),
                    ),
                  ],
                  selected: {estado},
                  onSelectionChanged: (selection) {
                    onEstadoChanged(selection.first);
                  },
                ),
                if (estado == InventarioEstado.enVenta) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 240,
                    child: AppTextField(
                      controller: priceController,
                      label: 'Precio',
                      prefixIcon: Icons.euro_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: validatePrice,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedGameCard extends StatelessWidget {
  const _SelectedGameCard({required this.juego});

  final JuegoCatalogo juego;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GameThumbnail(imageUrl: juego.imagenUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  juego.nombre,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(label: juego.tipo.label),
                    if (juego.plataforma != null)
                      _MetaChip(label: juego.plataforma!),
                    if (juego.codigoBarras != null)
                      _MetaChip(label: juego.codigoBarras!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExistingGameTile extends StatelessWidget {
  const _ExistingGameTile({
    required this.juego,
    required this.selectedJuegoId,
    required this.isSelected,
    required this.onSelected,
  });

  final JuegoCatalogo juego;
  final String? selectedJuegoId;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(top: 10),
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.24)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GameThumbnail(imageUrl: juego.imagenUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      juego.nombre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(label: juego.tipo.label),
                        if (juego.plataforma != null)
                          _MetaChip(label: juego.plataforma!),
                        if (juego.jugadoresLabel != null)
                          _MetaChip(label: juego.jugadoresLabel!),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selectedJuegoId == juego.id
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: selectedJuegoId == juego.id
                    ? colorScheme.primary
                    : colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCatalogCard extends StatelessWidget {
  const _EmptyCatalogCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'No se han encontrado juegos con esos criterios.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No se pudo cargar el catalogo',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _GameThumbnail extends StatelessWidget {
  const _GameThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 56,
        height: 56,
        color: colorScheme.secondaryContainer,
        child: imageUrl == null
            ? Icon(
                Icons.sports_esports_outlined,
                color: colorScheme.onSecondaryContainer,
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.sports_esports_outlined,
                    color: colorScheme.onSecondaryContainer,
                  );
                },
              ),
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
