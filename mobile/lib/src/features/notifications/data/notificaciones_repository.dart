import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/notificacion.dart';
import 'notificaciones_api.dart';

final notificacionesApiProvider = Provider<NotificacionesApi>((ref) {
  return NotificacionesApi(ref.watch(apiClientProvider));
});

final notificacionesRepositoryProvider = Provider<NotificacionesRepository>((
  ref,
) {
  return NotificacionesRepository(ref.watch(notificacionesApiProvider));
});

class NotificacionesRepository {
  const NotificacionesRepository(this._api);

  final NotificacionesApi _api;

  Future<List<Notificacion>> getNotificacionesByUsuario(String usuarioId) {
    return _api.fetchNotificacionesByUsuario(usuarioId);
  }

  Future<Notificacion> markAsRead(String notificacionId) {
    return _api.markAsRead(notificacionId);
  }

  Future<void> markAllAsRead(String usuarioId) {
    return _api.markAllAsRead(usuarioId);
  }
}
