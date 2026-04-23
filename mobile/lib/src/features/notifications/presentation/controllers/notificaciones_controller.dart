import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/notificaciones_repository.dart';
import '../../domain/notificacion.dart';

class NotificacionesState {
  const NotificacionesState({
    required this.items,
    required this.isLoading,
    required this.markingReadIds,
    this.usuarioId,
    this.errorMessage,
  });

  const NotificacionesState.initial()
    : this(items: const [], isLoading: false, markingReadIds: const {});

  final List<Notificacion> items;
  final bool isLoading;
  final Set<String> markingReadIds;
  final String? usuarioId;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
  bool get isEmpty => items.isEmpty;
  int get unreadCount => items.where((item) => !item.leida).length;

  NotificacionesState copyWith({
    List<Notificacion>? items,
    bool? isLoading,
    Set<String>? markingReadIds,
    String? usuarioId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificacionesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      markingReadIds: markingReadIds ?? this.markingReadIds,
      usuarioId: usuarioId ?? this.usuarioId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final notificacionesControllerProvider =
    NotifierProvider<NotificacionesController, NotificacionesState>(
      NotificacionesController.new,
    );

class NotificacionesController extends Notifier<NotificacionesState> {
  @override
  NotificacionesState build() {
    return const NotificacionesState.initial();
  }

  Future<void> loadNotificaciones(String usuarioId) async {
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
          .read(notificacionesRepositoryProvider)
          .getNotificacionesByUsuario(usuarioId);

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

    await loadNotificaciones(currentUsuarioId);
  }

  Future<String?> markAsRead(String notificacionId) async {
    final currentItem = state.items
        .where((item) => item.id == notificacionId)
        .firstOrNull;

    if (currentItem == null || currentItem.leida) {
      return null;
    }

    state = state.copyWith(
      markingReadIds: {...state.markingReadIds, notificacionId},
    );

    try {
      final updatedItem = await ref
          .read(notificacionesRepositoryProvider)
          .markAsRead(notificacionId);

      state = state.copyWith(
        items: state.items
            .map((item) => item.id == updatedItem.id ? updatedItem : item)
            .toList(),
        markingReadIds: state.markingReadIds
            .where((id) => id != notificacionId)
            .toSet(),
      );

      return null;
    } catch (error) {
      state = state.copyWith(
        markingReadIds: state.markingReadIds
            .where((id) => id != notificacionId)
            .toSet(),
      );

      return _errorMessage(error);
    }
  }

  Future<String?> markAllAsRead() async {
    final currentUsuarioId = state.usuarioId;

    if (currentUsuarioId == null || currentUsuarioId.isEmpty) {
      return null;
    }

    try {
      await ref
          .read(notificacionesRepositoryProvider)
          .markAllAsRead(currentUsuarioId);

      final readAt = DateTime.now();
      state = state.copyWith(
        items: state.items
            .map(
              (item) => item.leida
                  ? item
                  : item.copyWith(leida: true, readAt: readAt),
            )
            .toList(),
      );

      return null;
    } catch (error) {
      return _errorMessage(error);
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No se pudo completar la operacion.';
  }
}
