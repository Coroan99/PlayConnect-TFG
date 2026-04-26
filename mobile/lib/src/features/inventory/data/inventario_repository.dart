import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/inventario_item.dart';
import 'inventario_api.dart';

final inventarioApiProvider = Provider<InventarioApi>((ref) {
  return InventarioApi(ref.watch(apiClientProvider));
});

final inventarioRepositoryProvider = Provider<InventarioRepository>((ref) {
  return InventarioRepository(ref.watch(inventarioApiProvider));
});

class InventarioRepository {
  const InventarioRepository(this._api);

  final InventarioApi _api;

  Future<InventarioItem> createInventarioItem({
    required String usuarioId,
    required String juegoId,
    required String estado,
    double? precio,
  }) {
    return _api.createInventarioItem(
      usuarioId: usuarioId,
      juegoId: juegoId,
      estado: estado,
      precio: precio,
    );
  }

  Future<List<InventarioItem>> getInventarioByUsuario(String usuarioId) {
    return _api.fetchInventarioByUsuario(usuarioId);
  }

  Future<InventarioItem> getInventarioItemById(String itemId) {
    return _api.fetchInventarioItemById(itemId);
  }

  Future<InventarioItem> updateInventarioItem({
    required String itemId,
    required String usuarioId,
    required String juegoId,
    required String estado,
    double? precio,
  }) {
    return _api.updateInventarioItem(
      itemId: itemId,
      usuarioId: usuarioId,
      juegoId: juegoId,
      estado: estado,
      precio: precio,
    );
  }
}
