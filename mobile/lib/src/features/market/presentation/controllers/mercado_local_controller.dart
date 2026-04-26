import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../offers/data/ofertas_repository.dart';
import '../../../publications/domain/publicacion.dart';
import '../../../publications/presentation/controllers/publicaciones_controller.dart';

const defaultMarketCity = 'Córdoba';

class MercadoLocalState {
  const MercadoLocalState({
    required this.selectedCity,
    required this.submittingOfferPublicationIds,
  });

  const MercadoLocalState.initial()
    : this(
        selectedCity: defaultMarketCity,
        submittingOfferPublicationIds: const {},
      );

  final String selectedCity;
  final Set<String> submittingOfferPublicationIds;

  bool isSubmittingOffer(String publicationId) {
    return submittingOfferPublicationIds.contains(publicationId);
  }

  MercadoLocalState copyWith({
    String? selectedCity,
    Set<String>? submittingOfferPublicationIds,
  }) {
    return MercadoLocalState(
      selectedCity: selectedCity ?? this.selectedCity,
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
    required this.hasRealCityData,
  });

  final String selectedCity;
  final List<String> availableCities;
  final List<Publicacion> publicaciones;
  final bool hasRealCityData;
}

final mercadoLocalControllerProvider =
    NotifierProvider<MercadoLocalController, MercadoLocalState>(
      MercadoLocalController.new,
    );

final mercadoLocalViewProvider = Provider<MercadoLocalViewData>((ref) {
  final publicacionesState = ref.watch(publicacionesControllerProvider);
  final marketState = ref.watch(mercadoLocalControllerProvider);
  final currentUserId = ref.watch(authControllerProvider).usuario?.id;

  final publicacionesOtrosUsuarios = publicacionesState.publicaciones
      .where((publicacion) => publicacion.usuario.id != currentUserId)
      .toList();

  final availableCities = <String>{marketState.selectedCity};
  var hasRealCityData = false;

  for (final publicacion in publicacionesOtrosUsuarios) {
    if (publicacion.usuario.hasCiudad) {
      hasRealCityData = true;
    }

    availableCities.add(publicacion.usuario.ciudadOrDefault(defaultMarketCity));
  }

  if (availableCities.isEmpty) {
    availableCities.add(defaultMarketCity);
  }

  final sortedCities = availableCities.toList()
    ..sort((a, b) => _normalizeCity(a).compareTo(_normalizeCity(b)));

  final selectedCity = sortedCities.firstWhere(
    (city) => _normalizeCity(city) == _normalizeCity(marketState.selectedCity),
    orElse: () => defaultMarketCity,
  );

  final publicacionesFiltradas = publicacionesOtrosUsuarios.where((
    publicacion,
  ) {
    return _normalizeCity(
          publicacion.usuario.ciudadOrDefault(defaultMarketCity),
        ) ==
        _normalizeCity(selectedCity);
  }).toList();

  return MercadoLocalViewData(
    selectedCity: selectedCity,
    availableCities: sortedCities,
    publicaciones: publicacionesFiltradas,
    hasRealCityData: hasRealCityData,
  );
});

class MercadoLocalController extends Notifier<MercadoLocalState> {
  @override
  MercadoLocalState build() {
    return const MercadoLocalState.initial();
  }

  void selectCity(String city) {
    state = state.copyWith(selectedCity: city);
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
