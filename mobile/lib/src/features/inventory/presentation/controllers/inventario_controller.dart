import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/inventario_repository.dart';
import '../../domain/inventario_item.dart';

class InventarioState {
  const InventarioState({
    required this.items,
    required this.isLoading,
    this.usuarioId,
    this.errorMessage,
  });

  const InventarioState.initial() : this(items: const [], isLoading: false);

  final List<InventarioItem> items;
  final bool isLoading;
  final String? usuarioId;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
  bool get isEmpty => items.isEmpty;

  int get total => items.length;
  int get totalColeccion => _countByEstado(InventarioEstado.coleccion);
  int get totalVisible => _countByEstado(InventarioEstado.visible);
  int get totalEnVenta => _countByEstado(InventarioEstado.enVenta);

  int _countByEstado(InventarioEstado estado) {
    return items.where((item) => item.estado == estado).length;
  }

  InventarioState copyWith({
    List<InventarioItem>? items,
    bool? isLoading,
    String? usuarioId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InventarioState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      usuarioId: usuarioId ?? this.usuarioId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final inventarioControllerProvider =
    NotifierProvider<InventarioController, InventarioState>(
      InventarioController.new,
    );

class InventarioController extends Notifier<InventarioState> {
  @override
  InventarioState build() {
    return const InventarioState.initial();
  }

  Future<void> loadInventario(String usuarioId) async {
    if (state.isLoading && state.usuarioId == usuarioId) {
      return;
    }

    state = state.copyWith(
      usuarioId: usuarioId,
      isLoading: true,
      clearError: true,
    );

    try {
      final items = await ref
          .read(inventarioRepositoryProvider)
          .getInventarioByUsuario(usuarioId);

      state = state.copyWith(
        items: items,
        usuarioId: usuarioId,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        usuarioId: usuarioId,
        isLoading: false,
        errorMessage: _errorMessage(error),
      );
    }
  }

  Future<void> refresh() async {
    final currentUsuarioId = state.usuarioId;

    if (currentUsuarioId == null || currentUsuarioId.isEmpty) {
      return;
    }

    await loadInventario(currentUsuarioId);
  }

  void prependItem(InventarioItem item) {
    upsertItem(item, prependWhenMissing: true);
  }

  void upsertItem(InventarioItem item, {bool prependWhenMissing = false}) {
    final currentIndex = state.items.indexWhere(
      (existingItem) => existingItem.id == item.id,
    );

    final nextItems = [...state.items];

    if (currentIndex == -1) {
      if (prependWhenMissing) {
        nextItems.insert(0, item);
      } else {
        nextItems.add(item);
      }
    } else {
      nextItems[currentIndex] = item;
    }

    state = state.copyWith(items: nextItems, clearError: true);
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No se pudo cargar el inventario.';
  }
}
