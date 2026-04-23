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

  Future<List<InventarioItem>> getInventarioByUsuario(String usuarioId) {
    return _api.fetchInventarioByUsuario(usuarioId);
  }
}
