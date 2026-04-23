import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/juego_catalogo.dart';
import 'juegos_api.dart';

final juegosApiProvider = Provider<JuegosApi>((ref) {
  return JuegosApi(ref.watch(apiClientProvider));
});

final juegosRepositoryProvider = Provider<JuegosRepository>((ref) {
  return JuegosRepository(ref.watch(juegosApiProvider));
});

class JuegosRepository {
  const JuegosRepository(this._api);

  final JuegosApi _api;

  Future<List<JuegoCatalogo>> getJuegos() {
    return _api.fetchJuegos();
  }

  Future<JuegoCatalogo> getJuegoByBarcode(String codigoBarras) {
    return _api.fetchJuegoByBarcode(codigoBarras);
  }

  Future<JuegoCatalogo> createJuego({
    required String nombre,
    required JuegoTipo tipo,
    String? codigoBarras,
    String? imagenUrl,
    String? plataforma,
    int? jugadoresMin,
    int? jugadoresMax,
    int? duracionMinutos,
  }) {
    return _api.createJuego(
      nombre: nombre,
      tipo: tipo,
      codigoBarras: codigoBarras,
      imagenUrl: imagenUrl,
      plataforma: plataforma,
      jugadoresMin: jugadoresMin,
      jugadoresMax: jugadoresMax,
      duracionMinutos: duracionMinutos,
    );
  }
}
