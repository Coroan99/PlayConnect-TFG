const spanishCities = <String>[
  'A Coruña',
  'Albacete',
  'Alcalá de Henares',
  'Alcobendas',
  'Alcorcón',
  'Algeciras',
  'Alicante',
  'Almería',
  'Ávila',
  'Badajoz',
  'Badalona',
  'Barcelona',
  'Bilbao',
  'Burgos',
  'Cáceres',
  'Cádiz',
  'Cartagena',
  'Castellón de la Plana',
  'Ceuta',
  'Ciudad Real',
  'Córdoba',
  'Cuenca',
  'Donostia-San Sebastián',
  'Elche',
  'Fuenlabrada',
  'Getafe',
  'Gijón',
  'Girona',
  'Granada',
  'Guadalajara',
  'Hospitalet de Llobregat',
  'Huelva',
  'Huesca',
  'Jaén',
  'Jerez de la Frontera',
  'Las Palmas de Gran Canaria',
  'Leganés',
  'León',
  'Lleida',
  'Logroño',
  'Lugo',
  'Madrid',
  'Majadahonda',
  'Málaga',
  'Marbella',
  'Melilla',
  'Mérida',
  'Móstoles',
  'Murcia',
  'Ourense',
  'Oviedo',
  'Palma',
  'Pamplona',
  'Pontevedra',
  'Sabadell',
  'Salamanca',
  'San Cristóbal de La Laguna',
  'San Sebastián de los Reyes',
  'Santa Cruz de Tenerife',
  'Santander',
  'Santiago de Compostela',
  'Segovia',
  'Sevilla',
  'Soria',
  'Tarragona',
  'Terrassa',
  'Teruel',
  'Toledo',
  'Torrejón de Ardoz',
  'Valencia',
  'Valladolid',
  'Vigo',
  'Vitoria-Gasteiz',
  'Zamora',
  'Zaragoza',
];

String normalizeSpanishCity(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
}

String? canonicalizeSpanishCity(String? value) {
  if (value == null) {
    return null;
  }

  final normalizedValue = normalizeSpanishCity(value);

  if (normalizedValue.isEmpty) {
    return null;
  }

  for (final city in spanishCities) {
    if (normalizeSpanishCity(city) == normalizedValue) {
      return city;
    }
  }

  return null;
}

List<String> suggestSpanishCities(String query, {int limit = 6}) {
  final normalizedQuery = normalizeSpanishCity(query);

  if (normalizedQuery.isEmpty) {
    return spanishCities.take(limit).toList();
  }

  final startsWith = <String>[];
  final contains = <String>[];

  for (final city in spanishCities) {
    final normalizedCity = normalizeSpanishCity(city);

    if (normalizedCity.startsWith(normalizedQuery)) {
      startsWith.add(city);
      continue;
    }

    if (normalizedCity.contains(normalizedQuery)) {
      contains.add(city);
    }
  }

  return [...startsWith, ...contains].take(limit).toList();
}
