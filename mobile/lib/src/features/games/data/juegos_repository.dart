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

  Future<List<JuegoCatalogo>> getJuegos({String? search}) {
    return _api.fetchJuegos(search: search);
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
    String? descripcion,
    String? manualUrl,
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
      descripcion: descripcion,
      manualUrl: manualUrl,
    );
  }

  Future<JuegoCatalogo> updateJuego({
    required String juegoId,
    required String nombre,
    required JuegoTipo tipo,
    String? codigoBarras,
    String? imagenUrl,
    String? plataforma,
    int? jugadoresMin,
    int? jugadoresMax,
    int? duracionMinutos,
    String? descripcion,
    String? manualUrl,
  }) {
    return _api.updateJuego(
      juegoId: juegoId,
      nombre: nombre,
      tipo: tipo,
      codigoBarras: codigoBarras,
      imagenUrl: imagenUrl,
      plataforma: plataforma,
      jugadoresMin: jugadoresMin,
      jugadoresMax: jugadoresMax,
      duracionMinutos: duracionMinutos,
      descripcion: descripcion,
      manualUrl: manualUrl,
    );
  }
}
