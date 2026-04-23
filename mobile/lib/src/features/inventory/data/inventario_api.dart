import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/inventario_item.dart';

class InventarioApi {
  const InventarioApi(this._client);

  final ApiClient _client;

  Future<InventarioItem> createInventarioItem({
    required String usuarioId,
    required String juegoId,
    required String estado,
    double? precio,
  }) async {
    final response = await _client.post(
      'inventario',
      data: {
        'usuario_id': usuarioId,
        'juego_id': juegoId,
        'estado': estado,
        'precio': precio?.toStringAsFixed(2),
      },
    );

    return InventarioItem.fromJson(_asJsonMap(response.data));
  }

  Future<List<InventarioItem>> fetchInventarioByUsuario(
    String usuarioId,
  ) async {
    final response = await _client.get('inventario/usuario/$usuarioId');
    final items = _asJsonList(response.data);

    return items.map(InventarioItem.fromJson).toList();
  }

  Map<String, Object?> _asJsonMap(Object? payload) {
    if (payload is Map<String, Object?>) {
      return payload;
    }

    if (payload is Map) {
      return Map<String, Object?>.from(payload);
    }

    throw const ApiException('La API devolvio un inventario inesperado.');
  }

  List<Map<String, Object?>> _asJsonList(Object? payload) {
    if (payload is! List) {
      throw const ApiException('La API devolvio una lista inesperada.');
    }

    return payload.map((item) {
      if (item is Map<String, Object?>) {
        return item;
      }

      if (item is Map) {
        return Map<String, Object?>.from(item);
      }

      throw const ApiException('La API devolvio un inventario inesperado.');
    }).toList();
  }
}
