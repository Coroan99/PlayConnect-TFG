import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../games/data/juegos_repository.dart';
import '../../../games/domain/juego_catalogo.dart';
import '../../../publications/presentation/controllers/publicaciones_controller.dart';
import '../../data/inventario_repository.dart';
import '../../domain/inventario_item.dart';
import 'inventario_controller.dart';

class AddInventarioItemState {
  const AddInventarioItemState({
    required this.juegos,
    required this.isLoadingCatalog,
    required this.isLookingUpBarcode,
    required this.isSubmitting,
    required this.hasLoadedCatalog,
    required this.catalogQuery,
    this.catalogErrorMessage,
    this.lastScannedBarcode,
    this.barcodeLookupJuego,
    this.barcodeLookupErrorMessage,
    this.barcodeNotFound = false,
  });

  const AddInventarioItemState.initial()
    : this(
        juegos: const [],
        isLoadingCatalog: false,
        isLookingUpBarcode: false,
        isSubmitting: false,
        hasLoadedCatalog: false,
        catalogQuery: '',
      );

  final List<JuegoCatalogo> juegos;
  final bool isLoadingCatalog;
  final bool isLookingUpBarcode;
  final bool isSubmitting;
  final bool hasLoadedCatalog;
  final String catalogQuery;
  final String? catalogErrorMessage;
  final String? lastScannedBarcode;
  final JuegoCatalogo? barcodeLookupJuego;
  final String? barcodeLookupErrorMessage;
  final bool barcodeNotFound;

  bool get hasCatalogError => catalogErrorMessage != null;
  bool get hasBarcodeLookupError => barcodeLookupErrorMessage != null;
  bool get hasBarcodeLookupSuccess => barcodeLookupJuego != null;

  AddInventarioItemState copyWith({
    List<JuegoCatalogo>? juegos,
    bool? isLoadingCatalog,
    bool? isLookingUpBarcode,
    bool? isSubmitting,
    bool? hasLoadedCatalog,
    String? catalogQuery,
    String? catalogErrorMessage,
    String? lastScannedBarcode,
    JuegoCatalogo? barcodeLookupJuego,
    String? barcodeLookupErrorMessage,
    bool? barcodeNotFound,
    bool clearCatalogError = false,
    bool clearBarcodeLookupState = false,
  }) {
    return AddInventarioItemState(
      juegos: juegos ?? this.juegos,
      isLoadingCatalog: isLoadingCatalog ?? this.isLoadingCatalog,
      isLookingUpBarcode: isLookingUpBarcode ?? this.isLookingUpBarcode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasLoadedCatalog: hasLoadedCatalog ?? this.hasLoadedCatalog,
      catalogQuery: catalogQuery ?? this.catalogQuery,
      catalogErrorMessage: clearCatalogError
          ? null
          : catalogErrorMessage ?? this.catalogErrorMessage,
      lastScannedBarcode: clearBarcodeLookupState
          ? lastScannedBarcode
          : lastScannedBarcode ?? this.lastScannedBarcode,
      barcodeLookupJuego: clearBarcodeLookupState
          ? barcodeLookupJuego
          : barcodeLookupJuego ?? this.barcodeLookupJuego,
      barcodeLookupErrorMessage: clearBarcodeLookupState
          ? barcodeLookupErrorMessage
          : barcodeLookupErrorMessage ?? this.barcodeLookupErrorMessage,
      barcodeNotFound: clearBarcodeLookupState
          ? barcodeNotFound ?? false
          : barcodeNotFound ?? this.barcodeNotFound,
    );
  }
}

enum BarcodeLookupStatus { found, notFound, error }

class BarcodeLookupResult {
  const BarcodeLookupResult._({
    required this.status,
    required this.barcode,
    this.juego,
    this.message,
  });

  final BarcodeLookupStatus status;
  final String barcode;
  final JuegoCatalogo? juego;
  final String? message;

  bool get isFound => status == BarcodeLookupStatus.found;
  bool get isNotFound => status == BarcodeLookupStatus.notFound;

  factory BarcodeLookupResult.found({
    required String barcode,
    required JuegoCatalogo juego,
  }) {
    return BarcodeLookupResult._(
      status: BarcodeLookupStatus.found,
      barcode: barcode,
      juego: juego,
    );
  }

  factory BarcodeLookupResult.notFound({required String barcode}) {
    return BarcodeLookupResult._(
      status: BarcodeLookupStatus.notFound,
      barcode: barcode,
    );
  }

  factory BarcodeLookupResult.error({
    required String barcode,
    required String message,
  }) {
    return BarcodeLookupResult._(
      status: BarcodeLookupStatus.error,
      barcode: barcode,
      message: message,
    );
  }
}

final addInventarioItemControllerProvider =
    NotifierProvider<AddInventarioItemController, AddInventarioItemState>(
      AddInventarioItemController.new,
    );

class AddInventarioItemController extends Notifier<AddInventarioItemState> {
  int _catalogRequestId = 0;

  @override
  AddInventarioItemState build() {
    return const AddInventarioItemState.initial();
  }

  Future<void> loadCatalog({String search = '', bool force = false}) async {
    final normalizedSearch = search.trim();

    if (state.isLoadingCatalog && state.catalogQuery == normalizedSearch) {
      return;
    }

    if (state.hasLoadedCatalog &&
        !force &&
        state.catalogQuery == normalizedSearch) {
      return;
    }

    final requestId = ++_catalogRequestId;

    state = state.copyWith(
      isLoadingCatalog: true,
      catalogQuery: normalizedSearch,
      clearCatalogError: true,
    );

    try {
      final juegos = await ref
          .read(juegosRepositoryProvider)
          .getJuegos(search: normalizedSearch.isEmpty ? null : normalizedSearch);

      if (requestId != _catalogRequestId) {
        return;
      }

      state = state.copyWith(
        juegos: juegos,
        isLoadingCatalog: false,
        hasLoadedCatalog: true,
        catalogQuery: normalizedSearch,
        clearCatalogError: true,
      );
    } catch (error) {
      if (requestId != _catalogRequestId) {
        return;
      }

      state = state.copyWith(
        isLoadingCatalog: false,
        hasLoadedCatalog: true,
        catalogQuery: normalizedSearch,
        catalogErrorMessage: _errorMessage(
          error,
          fallback: 'No se pudo cargar el catalogo de juegos.',
        ),
      );
    }
  }

  Future<void> searchCatalog(String query) {
    return loadCatalog(search: query, force: true);
  }

  void clearBarcodeLookup() {
    state = state.copyWith(clearBarcodeLookupState: true);
  }

  Future<BarcodeLookupResult> lookupGameByBarcode(String barcode) async {
    state = state.copyWith(
      isLookingUpBarcode: true,
      lastScannedBarcode: barcode,
      clearBarcodeLookupState: true,
    );

    try {
      final juego = await ref
          .read(juegosRepositoryProvider)
          .getJuegoByBarcode(barcode);
      final updatedGames = [
        juego,
        ...state.juegos.where((existingGame) => existingGame.id != juego.id),
      ];

      state = state.copyWith(
        juegos: updatedGames,
        isLookingUpBarcode: false,
        hasLoadedCatalog: true,
        lastScannedBarcode: barcode,
        barcodeLookupJuego: juego,
      );

      return BarcodeLookupResult.found(barcode: barcode, juego: juego);
    } catch (error) {
      if (error is ApiException && error.statusCode == 404) {
        state = state.copyWith(
          isLookingUpBarcode: false,
          lastScannedBarcode: barcode,
          barcodeNotFound: true,
        );

        return BarcodeLookupResult.notFound(barcode: barcode);
      }

      final message = _errorMessage(
        error,
        fallback: 'No se pudo consultar el juego por codigo de barras.',
      );

      state = state.copyWith(
        isLookingUpBarcode: false,
        lastScannedBarcode: barcode,
        barcodeLookupErrorMessage: message,
      );

      return BarcodeLookupResult.error(barcode: barcode, message: message);
    }
  }

  Future<String?> addExistingGameToInventory({
    required String usuarioId,
    required String juegoId,
    required InventarioEstado estado,
    double? precio,
  }) async {
    state = state.copyWith(isSubmitting: true);

    try {
      final item = await ref
          .read(inventarioRepositoryProvider)
          .createInventarioItem(
            usuarioId: usuarioId,
            juegoId: juegoId,
            estado: estado.apiValue,
            precio: precio,
          );

      ref
          .read(inventarioControllerProvider.notifier)
          .upsertItem(item, prependWhenMissing: true);
      await _syncRelatedState(item);
      state = state.copyWith(isSubmitting: false);

      return null;
    } catch (error) {
      state = state.copyWith(isSubmitting: false);
      return _errorMessage(
        error,
        fallback: 'No se pudo anadir el juego al inventario.',
      );
    }
  }

  Future<String?> createGameAndAddToInventory({
    required String usuarioId,
    required String nombre,
    required JuegoTipo tipo,
    required InventarioEstado estado,
    String? plataforma,
    String? codigoBarras,
    String? imagenUrl,
    int? jugadoresMin,
    int? jugadoresMax,
    int? duracionMinutos,
    double? precio,
  }) async {
    state = state.copyWith(isSubmitting: true);

    try {
      final juego = await ref
          .read(juegosRepositoryProvider)
          .createJuego(
            nombre: nombre,
            tipo: tipo,
            codigoBarras: codigoBarras,
            imagenUrl: imagenUrl,
            plataforma: plataforma,
            jugadoresMin: jugadoresMin,
            jugadoresMax: jugadoresMax,
            duracionMinutos: duracionMinutos,
          );

      final item = await ref
          .read(inventarioRepositoryProvider)
          .createInventarioItem(
            usuarioId: usuarioId,
            juegoId: juego.id,
            estado: estado.apiValue,
            precio: precio,
          );

      ref
          .read(inventarioControllerProvider.notifier)
          .upsertItem(item, prependWhenMissing: true);
      await _syncRelatedState(item);
      state = state.copyWith(
        juegos: [
          juego,
          ...state.juegos.where((existingGame) => existingGame.id != juego.id),
        ],
        isSubmitting: false,
        hasLoadedCatalog: true,
      );

      return null;
    } catch (error) {
      state = state.copyWith(isSubmitting: false);
      return _errorMessage(
        error,
        fallback: 'No se pudo guardar el juego en el inventario.',
      );
    }
  }

  String _errorMessage(Object error, {required String fallback}) {
    if (error is ApiException) {
      return error.message;
    }

    return fallback;
  }

  Future<void> _syncRelatedState(InventarioItem item) async {
    if (!item.puedePublicarse && !item.tienePublicacion) {
      return;
    }

    try {
      await ref.read(publicacionesControllerProvider.notifier).refresh();
    } catch (_) {
      // El alta del inventario no debe fallar por un refresco secundario.
    }
  }
}
