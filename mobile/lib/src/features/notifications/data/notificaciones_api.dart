import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/notificacion.dart';

class NotificacionesApi {
  const NotificacionesApi(this._client);

  final ApiClient _client;

  Future<List<Notificacion>> fetchNotificacionesByUsuario(
    String usuarioId,
  ) async {
    final response = await _client.get('usuarios/$usuarioId/notificaciones');
    final items = _asJsonList(response.data);

    return items.map(Notificacion.fromJson).toList();
  }

  Future<Notificacion> markAsRead(String notificacionId) async {
    final response = await _client.patch('notificaciones/$notificacionId/read');
    final payload = _asJsonMap(response.data);

    return Notificacion.fromJson(payload);
  }

  Future<void> markAllAsRead(String usuarioId) async {
    await _client.patch('usuarios/$usuarioId/notificaciones/read-all');
  }

  List<Map<String, Object?>> _asJsonList(Object? payload) {
    if (payload is! List) {
      throw const ApiException('La API devolvio una lista inesperada.');
    }

    return payload.map((item) => _asJsonMap(item)).toList();
  }

  Map<String, Object?> _asJsonMap(Object? payload) {
    if (payload is Map<String, Object?>) {
      return payload;
    }

    if (payload is Map) {
      return Map<String, Object?>.from(payload);
    }

    throw const ApiException('La API devolvio una notificacion inesperada.');
  }
}
