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
  const PublicacionUsuario({required this.id, required this.nombre});

  final String id;
  final String nombre;

  factory PublicacionUsuario.fromJson(Map<String, Object?> json) {
    return PublicacionUsuario(
      id: _readString(json['id']),
      nombre: _readString(json['nombre']),
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
  });

  final String id;
  final String nombre;
  final String tipoJuego;
  final String? codigoBarras;
  final String? imagenUrl;
  final String? plataforma;

  String get tipoLabel {
    return switch (tipoJuego) {
      'juego_mesa' => 'Juego de mesa',
      'videojuego' => 'Videojuego',
      _ => tipoJuego,
    };
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

DateTime? _readDate(Object? value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}
