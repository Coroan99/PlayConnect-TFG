import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playconnect_mobile/src/core/network/api_client.dart';
import 'package:playconnect_mobile/src/features/inventory/data/inventario_api.dart';
import 'package:playconnect_mobile/src/features/inventory/data/inventario_repository.dart';
import 'package:playconnect_mobile/src/features/inventory/domain/inventario_item.dart';
import 'package:playconnect_mobile/src/features/inventory/presentation/controllers/edit_inventario_item_controller.dart';
import 'package:playconnect_mobile/src/features/inventory/presentation/controllers/inventario_controller.dart';
import 'package:playconnect_mobile/src/features/offers/presentation/controllers/publicacion_detail_controller.dart';
import 'package:playconnect_mobile/src/features/publications/data/publicaciones_api.dart';
import 'package:playconnect_mobile/src/features/publications/data/publicaciones_repository.dart';
import 'package:playconnect_mobile/src/features/publications/domain/publicacion.dart';
import 'package:playconnect_mobile/src/features/publications/presentation/controllers/publicaciones_controller.dart';

void main() {
  test(
    'saveChanges conserva la publicacion autocreada por backend cuando no hay descripcion manual',
    () async {
      final originalItem = _buildInventarioItem(
        id: 'inv-1',
        estado: InventarioEstado.coleccion,
        publicacion: null,
      );
      final backendCreatedItem = _buildInventarioItem(
        id: 'inv-1',
        estado: InventarioEstado.enVenta,
        precio: 25,
        publicacion: const InventarioPublicacion(
          id: 'pub-1',
          descripcion: 'Sonic en venta en PlayConnect por 25.00 EUR.',
          createdAt: null,
        ),
      );

      final fakeInventarioApi = _FakeInventarioApi(
        updatedItem: backendCreatedItem,
        fetchedItem: backendCreatedItem,
      );
      final fakePublicacionesApi = _FakePublicacionesApi();
      final fakeInventarioController = _FakeInventarioController();
      final fakePublicacionesController = _FakePublicacionesController();
      final fakeDetailController = _FakePublicacionDetailController();

      final container = ProviderContainer(
        overrides: [
          inventarioRepositoryProvider.overrideWithValue(
            InventarioRepository(fakeInventarioApi),
          ),
          publicacionesRepositoryProvider.overrideWithValue(
            PublicacionesRepository(fakePublicacionesApi),
          ),
          inventarioControllerProvider.overrideWith(() => fakeInventarioController),
          publicacionesControllerProvider.overrideWith(
            () => fakePublicacionesController,
          ),
          publicacionDetailControllerProvider.overrideWith(
            () => fakeDetailController,
          ),
        ],
      );
      addTearDown(container.dispose);

      final error = await container
          .read(editInventarioItemControllerProvider.notifier)
          .saveChanges(
            item: originalItem,
            estado: InventarioEstado.enVenta,
            precio: 25,
            publicationDescription: '',
          );

      expect(error, isNull);
      expect(fakePublicacionesApi.createCalls, 0);
      expect(fakePublicacionesApi.updateCalls, 0);
      expect(fakeInventarioController.refreshCalls, 1);
      expect(fakePublicacionesController.refreshCalls, 1);
      expect(
        container.read(editInventarioItemControllerProvider).item?.publicacion?.id,
        'pub-1',
      );
    },
  );

  test(
    'saveChanges actualiza la publicacion ya autocreada por backend cuando hay descripcion manual',
    () async {
      final originalItem = _buildInventarioItem(
        id: 'inv-1',
        estado: InventarioEstado.coleccion,
        publicacion: null,
      );
      final backendCreatedItem = _buildInventarioItem(
        id: 'inv-1',
        estado: InventarioEstado.enVenta,
        precio: 25,
        publicacion: const InventarioPublicacion(
          id: 'pub-1',
          descripcion: 'Texto automatico',
          createdAt: null,
        ),
      );
      final updatedPublicationItem = _buildInventarioItem(
        id: 'inv-1',
        estado: InventarioEstado.enVenta,
        precio: 25,
        publicacion: const InventarioPublicacion(
          id: 'pub-1',
          descripcion: 'Descripcion de demo',
          createdAt: null,
        ),
      );

      final fakeInventarioApi = _FakeInventarioApi(
        updatedItem: backendCreatedItem,
        fetchedItem: updatedPublicationItem,
      );
      final fakePublicacionesApi = _FakePublicacionesApi();
      final fakeInventarioController = _FakeInventarioController();
      final fakePublicacionesController = _FakePublicacionesController();
      final fakeDetailController = _FakePublicacionDetailController();

      final container = ProviderContainer(
        overrides: [
          inventarioRepositoryProvider.overrideWithValue(
            InventarioRepository(fakeInventarioApi),
          ),
          publicacionesRepositoryProvider.overrideWithValue(
            PublicacionesRepository(fakePublicacionesApi),
          ),
          inventarioControllerProvider.overrideWith(() => fakeInventarioController),
          publicacionesControllerProvider.overrideWith(
            () => fakePublicacionesController,
          ),
          publicacionDetailControllerProvider.overrideWith(
            () => fakeDetailController,
          ),
        ],
      );
      addTearDown(container.dispose);

      final error = await container
          .read(editInventarioItemControllerProvider.notifier)
          .saveChanges(
            item: originalItem,
            estado: InventarioEstado.enVenta,
            precio: 25,
            publicationDescription: 'Descripcion de demo',
          );

      expect(error, isNull);
      expect(fakePublicacionesApi.createCalls, 0);
      expect(fakePublicacionesApi.updateCalls, 1);
      expect(fakePublicacionesApi.lastUpdatedPublicacionId, 'pub-1');
      expect(
        container.read(editInventarioItemControllerProvider).item?.publicacion?.descripcion,
        'Descripcion de demo',
      );
    },
  );
}

InventarioItem _buildInventarioItem({
  required String id,
  required InventarioEstado estado,
  double? precio,
  InventarioPublicacion? publicacion,
}) {
  return InventarioItem(
    id: id,
    estado: estado,
    precio: precio,
    createdAt: null,
    updatedAt: null,
    publicacion: publicacion,
    usuario: const InventarioUsuario(id: 'user-1', nombre: 'Ana'),
    juego: const InventarioJuego(
      id: 'game-1',
      nombre: 'Sonic',
      tipoJuego: 'videojuego',
      plataforma: 'Mega Drive',
    ),
  );
}

class _FakeInventarioApi extends InventarioApi {
  _FakeInventarioApi({required this.updatedItem, required this.fetchedItem})
    : super(ApiClient(Dio()));

  final InventarioItem updatedItem;
  final InventarioItem fetchedItem;

  @override
  Future<InventarioItem> updateInventarioItem({
    required String itemId,
    required String usuarioId,
    required String juegoId,
    required String estado,
    double? precio,
  }) async {
    return updatedItem;
  }

  @override
  Future<InventarioItem> fetchInventarioItemById(String itemId) async {
    return fetchedItem;
  }
}

class _FakePublicacionesApi extends PublicacionesApi {
  _FakePublicacionesApi() : super(ApiClient(Dio()));

  int createCalls = 0;
  int updateCalls = 0;
  String? lastUpdatedPublicacionId;
  String? lastDescription;

  @override
  Future<void> createInteres({
    required String usuarioId,
    required String publicacionId,
  }) async {}

  @override
  Future<Publicacion> createPublicacion({
    required String inventarioId,
    required String descripcion,
  }) async {
    createCalls += 1;
    lastDescription = descripcion;
    return Publicacion(
      id: 'pub-created',
      descripcion: descripcion,
      createdAt: null,
      inventario: const PublicacionInventario(id: 'inv-1', estado: 'en_venta'),
      usuario: const PublicacionUsuario(id: 'user-1', nombre: 'Ana'),
      juego: const PublicacionJuego(
        id: 'game-1',
        nombre: 'Sonic',
        tipoJuego: 'videojuego',
      ),
    );
  }

  @override
  Future<Publicacion> updatePublicacion({
    required String publicacionId,
    required String inventarioId,
    required String descripcion,
  }) async {
    updateCalls += 1;
    lastUpdatedPublicacionId = publicacionId;
    lastDescription = descripcion;
    return Publicacion(
      id: publicacionId,
      descripcion: descripcion,
      createdAt: null,
      inventario: const PublicacionInventario(id: 'inv-1', estado: 'en_venta'),
      usuario: const PublicacionUsuario(id: 'user-1', nombre: 'Ana'),
      juego: const PublicacionJuego(
        id: 'game-1',
        nombre: 'Sonic',
        tipoJuego: 'videojuego',
      ),
    );
  }
}

class _FakeInventarioController extends InventarioController {
  int refreshCalls = 0;

  @override
  InventarioState build() {
    return const InventarioState.initial();
  }

  @override
  Future<void> refresh() async {
    refreshCalls += 1;
  }
}

class _FakePublicacionesController extends PublicacionesController {
  int refreshCalls = 0;

  @override
  PublicacionesState build() {
    return const PublicacionesState(
      publicaciones: [],
      isLoading: false,
      interestedPublicationIds: <String>{},
      processingInterestIds: <String>{},
    );
  }

  @override
  Future<void> refresh() async {
    refreshCalls += 1;
  }
}

class _FakePublicacionDetailController extends PublicacionDetailController {
  @override
  PublicacionDetailState build() {
    return const PublicacionDetailState.initial();
  }
}
