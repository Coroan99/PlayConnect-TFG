import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playconnect_mobile/src/features/auth/domain/usuario.dart';
import 'package:playconnect_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:playconnect_mobile/src/features/market/presentation/controllers/mercado_local_controller.dart';
import 'package:playconnect_mobile/src/features/publications/domain/publicacion.dart';
import 'package:playconnect_mobile/src/features/publications/presentation/controllers/publicaciones_controller.dart';

void main() {
  test(
    'mercado local muestra publicaciones de otros usuarios aunque no haya ciudad real',
    () {
      final currentUser = Usuario(
        id: 'user-1',
        nombre: 'Ana',
        email: 'ana@test.com',
        tipo: 'jugador',
      );

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FakeAuthController(AuthState.authenticated(currentUser)),
          ),
          publicacionesControllerProvider.overrideWith(
            () => _FakePublicacionesController(
              const PublicacionesState(
                publicaciones: [
                  Publicacion(
                    id: 'pub-own',
                    descripcion: 'Propia',
                    createdAt: null,
                    inventario: PublicacionInventario(
                      id: 'inv-own',
                      estado: 'visible',
                    ),
                    usuario: PublicacionUsuario(id: 'user-1', nombre: 'Ana'),
                    juego: PublicacionJuego(
                      id: 'game-1',
                      nombre: 'Sonic',
                      tipoJuego: 'videojuego',
                    ),
                  ),
                  Publicacion(
                    id: 'pub-other',
                    descripcion: 'Otra',
                    createdAt: null,
                    inventario: PublicacionInventario(
                      id: 'inv-other',
                      estado: 'en_venta',
                      precio: 20,
                    ),
                    usuario: PublicacionUsuario(id: 'user-2', nombre: 'Luis'),
                    juego: PublicacionJuego(
                      id: 'game-2',
                      nombre: 'Mario',
                      tipoJuego: 'videojuego',
                    ),
                  ),
                ],
                isLoading: false,
                interestedPublicationIds: <String>{},
                processingInterestIds: <String>{},
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final view = container.read(mercadoLocalViewProvider);

      expect(view.publicaciones, hasLength(1));
      expect(view.publicaciones.single.id, 'pub-other');
      expect(view.hasRealCityData, isFalse);
      expect(view.selectedCity, defaultMarketCity);
    },
  );
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._state);

  final AuthState _state;

  @override
  AuthState build() {
    return _state;
  }
}

class _FakePublicacionesController extends PublicacionesController {
  _FakePublicacionesController(this._state);

  final PublicacionesState _state;

  @override
  PublicacionesState build() {
    return _state;
  }
}
