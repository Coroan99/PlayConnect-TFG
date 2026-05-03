import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../games/domain/juego_catalogo.dart';
import '../../../offers/data/ofertas_repository.dart';
import '../../../publications/domain/publicacion.dart';
import '../../../publications/presentation/controllers/publicaciones_controller.dart';

const defaultMarketCity = 'Córdoba';

class MercadoLocalState {
  const MercadoLocalState({
    required this.selectedCity,
    required this.selectedTypeFilter,
    required this.submittingOfferPublicationIds,
  });

  const MercadoLocalState.initial({required String selectedCity})
    : this(
        selectedCity: selectedCity,
        selectedTypeFilter: GameTypeFilter.all,
        submittingOfferPublicationIds: const {},
      );

  final String selectedCity;
  final GameTypeFilter selectedTypeFilter;
  final Set<String> submittingOfferPublicationIds;

  bool isSubmittingOffer(String publicationId) {
    return submittingOfferPublicationIds.contains(publicationId);
  }

  MercadoLocalState copyWith({
    String? selectedCity,
    GameTypeFilter? selectedTypeFilter,
    Set<String>? submittingOfferPublicationIds,
  }) {
    return MercadoLocalState(
      selectedCity: selectedCity ?? this.selectedCity,
      selectedTypeFilter: selectedTypeFilter ?? this.selectedTypeFilter,
      submittingOfferPublicationIds:
          submittingOfferPublicationIds ?? this.submittingOfferPublicationIds,
    );
  }
}

class MercadoLocalViewData {
  const MercadoLocalViewData({
    required this.selectedCity,
    required this.availableCities,
    required this.publicaciones,
    required this.publicacionesPorCiudad,
    required this.hasRealCityData,
    required this.selectedTypeFilter,
  });

  final String selectedCity;
  final List<String> availableCities;
  final List<Publicacion> publicaciones;
  final List<Publicacion> publicacionesPorCiudad;
  final bool hasRealCityData;
  final GameTypeFilter selectedTypeFilter;
}

final mercadoLocalControllerProvider =
    NotifierProvider<MercadoLocalController, MercadoLocalState>(
      MercadoLocalController.new,
    );

final mercadoLocalViewProvider = Provider<MercadoLocalViewData>((ref) {
  final publicacionesState = ref.watch(publicacionesControllerProvider);
  final marketState = ref.watch(mercadoLocalControllerProvider);
  final authUser = ref.watch(authControllerProvider).usuario;
  final currentUserId = authUser?.id;
  final preferredCity = authUser?.ciudad ?? defaultMarketCity;

  final publicacionesOtrosUsuarios = publicacionesState.publicaciones
      .where((publicacion) => publicacion.usuario.id != currentUserId)
      .toList();

  final availableCities = <String>{preferredCity};
  final publicacionesConCiudad = <Publicacion>[];

  for (final publicacion in publicacionesOtrosUsuarios) {
    if (publicacion.usuario.hasCiudad) {
      publicacionesConCiudad.add(publicacion);
      availableCities.add(publicacion.usuario.ciudadOrDefault());
    }
  }

  final hasRealCityData = publicacionesConCiudad.isNotEmpty;

  if (availableCities.isEmpty) {
    availableCities.add(defaultMarketCity);
  }

  final sortedCities = availableCities.toList()
    ..sort((a, b) => _normalizeCity(a).compareTo(_normalizeCity(b)));

  final selectedCity = sortedCities.firstWhere(
    (city) => _normalizeCity(city) == _normalizeCity(marketState.selectedCity),
    orElse: () => sortedCities.first,
  );

  final publicacionesPorCiudad = hasRealCityData
      ? publicacionesOtrosUsuarios.where((publicacion) {
          if (!publicacion.usuario.hasCiudad) {
            return true;
          }

          return _normalizeCity(publicacion.usuario.ciudadOrDefault()) ==
              _normalizeCity(selectedCity);
        }).toList()
      : publicacionesOtrosUsuarios;
  final publicacionesFiltradas = publicacionesPorCiudad.where((publicacion) {
    return marketState.selectedTypeFilter.matchesTipoApiValue(
      publicacion.juego.tipoJuego,
    );
  }).toList();

  _debugLog(
    'MercadoLocalView -> total=${publicacionesState.publicaciones.length}, otros=${publicacionesOtrosUsuarios.length}, ciudadesReales=$hasRealCityData, ciudadSeleccionada=$selectedCity, tipo=${marketState.selectedTypeFilter.name}, visibles=${publicacionesFiltradas.length}',
  );

  return MercadoLocalViewData(
    selectedCity: selectedCity,
    availableCities: sortedCities,
    publicaciones: publicacionesFiltradas,
    publicacionesPorCiudad: publicacionesPorCiudad,
    hasRealCityData: hasRealCityData,
    selectedTypeFilter: marketState.selectedTypeFilter,
  );
});

class MercadoLocalController extends Notifier<MercadoLocalState> {
  @override
  MercadoLocalState build() {
    final authUser = ref.watch(authControllerProvider).usuario;
    final selectedCity = authUser?.ciudad ?? defaultMarketCity;

    return MercadoLocalState.initial(selectedCity: selectedCity);
  }

  void selectCity(String city) {
    state = state.copyWith(selectedCity: city);
  }

  void selectTypeFilter(GameTypeFilter filter) {
    state = state.copyWith(selectedTypeFilter: filter);
  }

  Future<String?> enviarOferta({
    required String usuarioId,
    required String publicacionId,
    required double precioOfrecido,
    String? mensaje,
  }) async {
    if (state.isSubmittingOffer(publicacionId)) {
      return null;
    }

    state = state.copyWith(
      submittingOfferPublicationIds: {
        ...state.submittingOfferPublicationIds,
        publicacionId,
      },
    );

    try {
      await ref
          .read(ofertasRepositoryProvider)
          .createOferta(
            usuarioId: usuarioId,
            publicacionId: publicacionId,
            precioOfrecido: precioOfrecido,
            mensaje: mensaje,
          );

      state = state.copyWith(
        submittingOfferPublicationIds: state.submittingOfferPublicationIds
            .where((id) => id != publicacionId)
            .toSet(),
      );

      return null;
    } catch (error) {
      state = state.copyWith(
        submittingOfferPublicationIds: state.submittingOfferPublicationIds
            .where((id) => id != publicacionId)
            .toSet(),
      );

      return _errorMessage(error);
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No se pudo completar la oferta.';
  }
}

String _normalizeCity(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
}

void _debugLog(String message) {
  assert(() {
    debugPrint(message);
    return true;
  }());
}
