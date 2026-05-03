enum JuegoTipo {
  videojuego('videojuego', 'Videojuego'),
  juegoMesa('juego_mesa', 'Juego de mesa');

  const JuegoTipo(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static JuegoTipo fromApi(String value) {
    return JuegoTipo.values.firstWhere(
      (tipo) => tipo.apiValue == value,
      orElse: () => JuegoTipo.videojuego,
    );
  }
}

enum GameTypeFilter {
  all('Todos'),
  videogames('Videojuegos'),
  boardGames('Juegos de mesa');

  const GameTypeFilter(this.label);

  final String label;

  bool matchesTipoApiValue(String tipoJuego) {
    return switch (this) {
      GameTypeFilter.all => true,
      GameTypeFilter.videogames => tipoJuego == JuegoTipo.videojuego.apiValue,
      GameTypeFilter.boardGames => tipoJuego == JuegoTipo.juegoMesa.apiValue,
    };
  }
}

class JuegoCatalogo {
  const JuegoCatalogo({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.codigoBarras,
    this.imagenUrl,
    this.plataforma,
    this.jugadoresMin,
    this.jugadoresMax,
    this.duracionMinutos,
    this.descripcion,
    this.manualUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String nombre;
  final JuegoTipo tipo;
  final String? codigoBarras;
  final String? imagenUrl;
  final String? plataforma;
  final int? jugadoresMin;
  final int? jugadoresMax;
  final int? duracionMinutos;
  final String? descripcion;
  final String? manualUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get jugadoresLabel {
    if (jugadoresMin == null && jugadoresMax == null) {
      return null;
    }

    if (jugadoresMin != null && jugadoresMax != null) {
      return '$jugadoresMin-$jugadoresMax jugadores';
    }

    final value = jugadoresMin ?? jugadoresMax;
    return '$value jugadores';
  }

  String? get duracionLabel {
    final value = duracionMinutos;

    if (value == null) {
      return null;
    }

    return '$value min';
  }

  bool matchesQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return true;
    }

    return nombre.toLowerCase().contains(normalizedQuery) ||
        tipo.label.toLowerCase().contains(normalizedQuery) ||
        (plataforma?.toLowerCase().contains(normalizedQuery) ?? false) ||
        (codigoBarras?.toLowerCase().contains(normalizedQuery) ?? false);
  }

  factory JuegoCatalogo.fromJson(Map<String, Object?> json) {
    return JuegoCatalogo(
      id: _readString(json['id']),
      nombre: _readString(json['nombre']),
      tipo: JuegoTipo.fromApi(
        _readString(json['tipo_juego'] ?? json['tipoJuego']),
      ),
      codigoBarras: _readNullableString(
        json['codigo_barras'] ?? json['codigoBarras'],
      ),
      imagenUrl: _readNullableString(json['imagen_url'] ?? json['imagenUrl']),
      plataforma: _readNullableString(json['plataforma']),
      jugadoresMin: _readInt(json['jugadores_min'] ?? json['jugadoresMin']),
      jugadoresMax: _readInt(json['jugadores_max'] ?? json['jugadoresMax']),
      duracionMinutos: _readInt(
        json['duracion_minutos'] ?? json['duracionMinutos'],
      ),
      descripcion: _readNullableString(json['descripcion']),
      manualUrl: _readNullableString(json['manual_url'] ?? json['manualUrl']),
      createdAt: _readDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _readDate(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

String _readString(Object? value) {
  if (value == null) {
    return '';
  }

  return value.toString();
}

String? _readNullableString(Object? value) {
  final text = _readString(value).trim();
  return text.isEmpty ? null : text;
}

int? _readInt(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

DateTime? _readDate(Object? value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}
