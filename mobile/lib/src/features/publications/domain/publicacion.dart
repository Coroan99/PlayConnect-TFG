class Publicacion {
  const Publicacion({
    required this.id,
    required this.descripcion,
    required this.createdAt,
    required this.inventario,
    required this.usuario,
    required this.juego,
  });

  final String id;
  final String descripcion;
  final DateTime? createdAt;
  final PublicacionInventario inventario;
  final PublicacionUsuario usuario;
  final PublicacionJuego juego;

  Publicacion copyWith({PublicacionJuego? juego}) {
    return Publicacion(
      id: id,
      descripcion: descripcion,
      createdAt: createdAt,
      inventario: inventario,
      usuario: usuario,
      juego: juego ?? this.juego,
    );
  }

  factory Publicacion.fromJson(Map<String, Object?> json) {
    return Publicacion(
      id: _readString(json['id']),
      descripcion: _readString(json['descripcion']),
      createdAt: _readDate(json['created_at'] ?? json['createdAt']),
      inventario: PublicacionInventario.fromJson(_readMap(json['inventario'])),
      usuario: PublicacionUsuario.fromJson(_readMap(json['usuario'])),
      juego: PublicacionJuego.fromJson(_readMap(json['juego'])),
    );
  }
}

class PublicacionInventario {
  const PublicacionInventario({
    required this.id,
    required this.estado,
    this.precio,
  });

  final String id;
  final String estado;
  final double? precio;

  String get estadoLabel {
    return switch (estado) {
      'en_venta' => 'En venta',
      'visible' => 'Disponible',
      'coleccion' => 'Coleccion',
      _ => estado,
    };
  }

  String? get precioLabel {
    final value = precio;

    if (value == null) {
      return null;
    }

    return '${value.toStringAsFixed(2)} EUR';
  }

  factory PublicacionInventario.fromJson(Map<String, Object?> json) {
    return PublicacionInventario(
      id: _readString(json['id']),
      estado: _readString(json['estado']),
      precio: _readDouble(json['precio']),
    );
  }
}

class PublicacionUsuario {
  const PublicacionUsuario({
    required this.id,
    required this.nombre,
    this.ciudad,
  });

  final String id;
  final String nombre;
  final String? ciudad;

  bool get hasCiudad => ciudad != null && ciudad!.trim().isNotEmpty;

  String ciudadOrDefault([String fallbackCity = 'Córdoba']) {
    final value = ciudad?.trim();
    return value == null || value.isEmpty ? fallbackCity : value;
  }

  factory PublicacionUsuario.fromJson(Map<String, Object?> json) {
    final ubicacion = _readNullableMap(json['ubicacion']);

    return PublicacionUsuario(
      id: _readString(json['id']),
      nombre: _readString(json['nombre']),
      ciudad: _readNullableString(
        json['ciudad'] ?? json['localidad'] ?? ubicacion?['ciudad'],
      ),
    );
  }
}

class PublicacionJuego {
  const PublicacionJuego({
    required this.id,
    required this.nombre,
    required this.tipoJuego,
    this.codigoBarras,
    this.imagenUrl,
    this.plataforma,
    this.jugadoresMin,
    this.jugadoresMax,
    this.duracionMinutos,
    this.descripcion,
    this.manualUrl,
  });

  final String id;
  final String nombre;
  final String tipoJuego;
  final String? codigoBarras;
  final String? imagenUrl;
  final String? plataforma;
  final int? jugadoresMin;
  final int? jugadoresMax;
  final int? duracionMinutos;
  final String? descripcion;
  final String? manualUrl;

  String get tipoLabel {
    return switch (tipoJuego) {
      'juego_mesa' => 'Juego de mesa',
      'videojuego' => 'Videojuego',
      _ => tipoJuego,
    };
  }

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

  PublicacionJuego copyWith({
    String? codigoBarras,
    String? imagenUrl,
    String? plataforma,
    int? jugadoresMin,
    int? jugadoresMax,
    int? duracionMinutos,
    String? descripcion,
    String? manualUrl,
  }) {
    return PublicacionJuego(
      id: id,
      nombre: nombre,
      tipoJuego: tipoJuego,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      plataforma: plataforma ?? this.plataforma,
      jugadoresMin: jugadoresMin ?? this.jugadoresMin,
      jugadoresMax: jugadoresMax ?? this.jugadoresMax,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      descripcion: descripcion ?? this.descripcion,
      manualUrl: manualUrl ?? this.manualUrl,
    );
  }

  factory PublicacionJuego.fromJson(Map<String, Object?> json) {
    return PublicacionJuego(
      id: _readString(json['id']),
      nombre: _readString(json['nombre']),
      tipoJuego: _readString(json['tipo_juego'] ?? json['tipoJuego']),
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
    );
  }
}

Map<String, Object?> _readMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return const {};
}

Map<String, Object?>? _readNullableMap(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
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

double? _readDouble(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
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
