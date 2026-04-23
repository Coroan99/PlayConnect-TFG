class InventarioItem {
  const InventarioItem({
    required this.id,
    required this.estado,
    required this.precio,
    required this.createdAt,
    required this.updatedAt,
    required this.usuario,
    required this.juego,
  });

  final String id;
  final InventarioEstado estado;
  final double? precio;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final InventarioUsuario usuario;
  final InventarioJuego juego;

  bool get estaEnVenta => estado == InventarioEstado.enVenta;
  bool get puedePublicarse => estado == InventarioEstado.visible || estaEnVenta;

  String? get precioLabel {
    final value = precio;

    if (value == null) {
      return null;
    }

    return '${value.toStringAsFixed(2)} EUR';
  }

  factory InventarioItem.fromJson(Map<String, Object?> json) {
    return InventarioItem(
      id: _readString(json['id']),
      estado: InventarioEstado.fromApi(_readString(json['estado'])),
      precio: _readDouble(json['precio']),
      createdAt: _readDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _readDate(json['updated_at'] ?? json['updatedAt']),
      usuario: InventarioUsuario.fromJson(_readMap(json['usuario'])),
      juego: InventarioJuego.fromJson(_readMap(json['juego'])),
    );
  }
}

enum InventarioEstado {
  coleccion('coleccion', 'Coleccion'),
  visible('visible', 'Visible'),
  enVenta('en_venta', 'En venta');

  const InventarioEstado(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static InventarioEstado fromApi(String value) {
    return InventarioEstado.values.firstWhere(
      (estado) => estado.apiValue == value,
      orElse: () => InventarioEstado.coleccion,
    );
  }
}

class InventarioUsuario {
  const InventarioUsuario({required this.id, required this.nombre});

  final String id;
  final String nombre;

  factory InventarioUsuario.fromJson(Map<String, Object?> json) {
    return InventarioUsuario(
      id: _readString(json['id']),
      nombre: _readString(json['nombre']),
    );
  }
}

class InventarioJuego {
  const InventarioJuego({
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

  factory InventarioJuego.fromJson(Map<String, Object?> json) {
    return InventarioJuego(
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
