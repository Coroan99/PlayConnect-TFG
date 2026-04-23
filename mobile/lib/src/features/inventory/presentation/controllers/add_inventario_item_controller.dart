import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../games/data/juegos_repository.dart';
import '../../../games/domain/juego_catalogo.dart';
import '../../data/inventario_repository.dart';
import '../../domain/inventario_item.dart';
import 'inventario_controller.dart';

class AddInventarioItemState {
  const AddInventarioItemState({
    required this.juegos,
    required this.isLoadingCatalog,
    required this.isSubmitting,
    required this.hasLoadedCatalog,
    this.catalogErrorMessage,
  });

  const AddInventarioItemState.initial()
    : this(
        juegos: const [],
        isLoadingCatalog: false,
        isSubmitting: false,
        hasLoadedCatalog: false,
      );

  final List<JuegoCatalogo> juegos;
  final bool isLoadingCatalog;
  final bool isSubmitting;
  final bool hasLoadedCatalog;
  final String? catalogErrorMessage;

  bool get hasCatalogError => catalogErrorMessage != null;

  AddInventarioItemState copyWith({
    List<JuegoCatalogo>? juegos,
    bool? isLoadingCatalog,
    bool? isSubmitting,
    bool? hasLoadedCatalog,
    String? catalogErrorMessage,
    bool clearCatalogError = false,
  }) {
    return AddInventarioItemState(
      juegos: juegos ?? this.juegos,
      isLoadingCatalog: isLoadingCatalog ?? this.isLoadingCatalog,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasLoadedCatalog: hasLoadedCatalog ?? this.hasLoadedCatalog,
      catalogErrorMessage: clearCatalogError
          ? null
          : catalogErrorMessage ?? this.catalogErrorMessage,
    );
  }
}

final addInventarioItemControllerProvider =
    NotifierProvider<AddInventarioItemController, AddInventarioItemState>(
      AddInventarioItemController.new,
    );

class AddInventarioItemController extends Notifier<AddInventarioItemState> {
  @override
  AddInventarioItemState build() {
    return const AddInventarioItemState.initial();
  }

  Future<void> loadCatalog({bool force = false}) async {
    if (state.isLoadingCatalog) {
      return;
    }

    if (state.hasLoadedCatalog && !force) {
      return;
    }

    state = state.copyWith(isLoadingCatalog: true, clearCatalogError: true);

    try {
      final juegos = await ref.read(juegosRepositoryProvider).getJuegos();

      state = state.copyWith(
        juegos: juegos,
        isLoadingCatalog: false,
        hasLoadedCatalog: true,
        clearCatalogError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingCatalog: false,
        hasLoadedCatalog: true,
        catalogErrorMessage: _errorMessage(
          error,
          fallback: 'No se pudo cargar el catalogo de juegos.',
        ),
      );
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

      ref.read(inventarioControllerProvider.notifier).prependItem(item);
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

      ref.read(inventarioControllerProvider.notifier).prependItem(item);
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
}
