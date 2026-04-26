import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../offers/presentation/controllers/publicacion_detail_controller.dart';
import '../../../publications/data/publicaciones_repository.dart';
import '../../../publications/presentation/controllers/publicaciones_controller.dart';
import '../../data/inventario_repository.dart';
import '../../domain/inventario_item.dart';
import 'inventario_controller.dart';

const _notSet = Object();

class EditInventarioItemState {
  const EditInventarioItemState({
    required this.isLoadingItem,
    required this.isSubmitting,
    this.itemId,
    this.item,
    this.errorMessage,
  });

  const EditInventarioItemState.initial()
    : this(isLoadingItem: false, isSubmitting: false);

  final String? itemId;
  final InventarioItem? item;
  final bool isLoadingItem;
  final bool isSubmitting;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  EditInventarioItemState copyWith({
    Object? itemId = _notSet,
    Object? item = _notSet,
    bool? isLoadingItem,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EditInventarioItemState(
      itemId: identical(itemId, _notSet) ? this.itemId : itemId as String?,
      item: identical(item, _notSet) ? this.item : item as InventarioItem?,
      isLoadingItem: isLoadingItem ?? this.isLoadingItem,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final editInventarioItemControllerProvider =
    NotifierProvider<EditInventarioItemController, EditInventarioItemState>(
      EditInventarioItemController.new,
    );

class EditInventarioItemController extends Notifier<EditInventarioItemState> {
  @override
  EditInventarioItemState build() {
    return const EditInventarioItemState.initial();
  }

  Future<void> loadItem({
    required String itemId,
    InventarioItem? fallbackItem,
  }) async {
    if (fallbackItem != null && fallbackItem.id == itemId) {
      state = state.copyWith(
        itemId: itemId,
        item: fallbackItem,
        isLoadingItem: false,
        clearError: true,
      );
      return;
    }

    if (state.isLoadingItem && state.itemId == itemId) {
      return;
    }

    state = state.copyWith(
      itemId: itemId,
      item: null,
      isLoadingItem: true,
      clearError: true,
    );

    try {
      final item = await ref
          .read(inventarioRepositoryProvider)
          .getInventarioItemById(itemId);

      state = state.copyWith(
        itemId: itemId,
        item: item,
        isLoadingItem: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        itemId: itemId,
        isLoadingItem: false,
        errorMessage: _errorMessage(
          error,
          fallback: 'No se pudo cargar el item del inventario.',
        ),
      );
    }
  }

  Future<String?> saveChanges({
    required InventarioItem item,
    required InventarioEstado estado,
    double? precio,
    required bool createPublication,
    String? publicationDescription,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final existingPublication = item.publicacion;
    final shouldSyncPublication =
        existingPublication != null || createPublication;
    final normalizedDescription = publicationDescription?.trim();

    if (shouldSyncPublication &&
        (normalizedDescription == null || normalizedDescription.isEmpty)) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'La descripcion de la publicacion es obligatoria.',
      );
      return state.errorMessage;
    }

    try {
      final inventarioRepository = ref.read(inventarioRepositoryProvider);
      final publicacionesRepository = ref.read(publicacionesRepositoryProvider);

      var updatedItem = await inventarioRepository.updateInventarioItem(
        itemId: item.id,
        usuarioId: item.usuario.id,
        juegoId: item.juego.id,
        estado: estado.apiValue,
        precio: precio,
      );

      if (shouldSyncPublication) {
        if (existingPublication == null) {
          await publicacionesRepository.createPublicacion(
            inventarioId: updatedItem.id,
            descripcion: normalizedDescription!,
          );
        } else {
          await publicacionesRepository.updatePublicacion(
            publicacionId: existingPublication.id,
            inventarioId: updatedItem.id,
            descripcion: normalizedDescription!,
          );
        }

        updatedItem = await inventarioRepository.getInventarioItemById(
          updatedItem.id,
        );
      }

      ref.read(inventarioControllerProvider.notifier).upsertItem(updatedItem);
      await _syncRelatedState(updatedItem);

      state = state.copyWith(
        itemId: updatedItem.id,
        item: updatedItem,
        isSubmitting: false,
        clearError: true,
      );

      return null;
    } catch (error) {
      final message = _errorMessage(
        error,
        fallback: 'No se pudieron guardar los cambios del inventario.',
      );

      state = state.copyWith(isSubmitting: false, errorMessage: message);
      return message;
    }
  }

  Future<void> _syncRelatedState(InventarioItem item) async {
    try {
      await ref.read(publicacionesControllerProvider.notifier).refresh();
    } catch (_) {
      // Mantiene el inventario consistente aunque falle el refresco secundario.
    }

    final publicationId = item.publicacion?.id;
    final detailState = ref.read(publicacionDetailControllerProvider);

    if (publicationId == null || detailState.publicacionId != publicationId) {
      return;
    }

    try {
      await ref.read(publicacionDetailControllerProvider.notifier).refresh();
    } catch (_) {
      // El detalle puede refrescarse manualmente si esta vista sigue abierta.
    }
  }

  String _errorMessage(Object error, {required String fallback}) {
    if (error is ApiException) {
      return error.message;
    }

    return fallback;
  }
}
