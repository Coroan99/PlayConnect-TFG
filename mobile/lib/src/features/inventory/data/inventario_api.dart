import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/inventario_item.dart';

class InventarioApi {
  const InventarioApi(this._client);

  final ApiClient _client;

  Future<List<InventarioItem>> fetchInventarioByUsuario(
    String usuarioId,
  ) async {
    final response = await _client.get('inventario/usuario/$usuarioId');
    final items = _asJsonList(response.data);

    return items.map(InventarioItem.fromJson).toList();
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
