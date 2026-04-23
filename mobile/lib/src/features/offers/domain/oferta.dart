class Oferta {
  const Oferta({
    required this.id,
    required this.precioOfrecido,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
    required this.usuario,
    required this.publicacion,
    this.mensaje,
  });

  final String id;
  final double precioOfrecido;
  final String? mensaje;
  final OfertaEstado estado;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final OfertaUsuario usuario;
  final OfertaPublicacion publicacion;

  String get precioLabel => '${precioOfrecido.toStringAsFixed(2)} EUR';
  bool get estaPendiente => estado == OfertaEstado.pendiente;

  factory Oferta.fromJson(Map<String, Object?> json) {
    return Oferta(
      id: _readString(json['id']),
      precioOfrecido: _readDouble(json['precio_ofrecido']) ?? 0,
      mensaje: _readNullableString(json['mensaje']),
      estado: OfertaEstado.fromApi(_readString(json['estado'])),
      createdAt: _readDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _readDate(json['updated_at'] ?? json['updatedAt']),
      usuario: OfertaUsuario.fromJson(_readMap(json['usuario'])),
      publicacion: OfertaPublicacion.fromJson(_readMap(json['publicacion'])),
    );
  }
}

enum OfertaEstado {
  pendiente('pendiente', 'Pendiente'),
  aceptada('aceptada', 'Aceptada'),
  rechazada('rechazada', 'Rechazada'),
  cancelada('cancelada', 'Cancelada');

  const OfertaEstado(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static OfertaEstado fromApi(String value) {
    return OfertaEstado.values.firstWhere(
      (estado) => estado.apiValue == value,
      orElse: () => OfertaEstado.pendiente,
    );
  }
}

class OfertaUsuario {
  const OfertaUsuario({required this.id, required this.nombre});

  final String id;
  final String nombre;

  factory OfertaUsuario.fromJson(Map<String, Object?> json) {
    return OfertaUsuario(
      id: _readString(json['id']),
      nombre: _readString(json['nombre']),
    );
  }
}

class OfertaPublicacion {
  const OfertaPublicacion({
    required this.id,
    required this.descripcion,
    required this.propietario,
    required this.juego,
  });

  final String id;
  final String descripcion;
  final OfertaUsuario propietario;
  final OfertaJuego juego;

  factory OfertaPublicacion.fromJson(Map<String, Object?> json) {
    return OfertaPublicacion(
      id: _readString(json['id']),
      descripcion: _readString(json['descripcion']),
      propietario: OfertaUsuario.fromJson(_readMap(json['propietario'])),
      juego: OfertaJuego.fromJson(_readMap(json['juego'])),
    );
  }
}

class OfertaJuego {
  const OfertaJuego({required this.id, required this.nombre});

  final String id;
  final String nombre;

  factory OfertaJuego.fromJson(Map<String, Object?> json) {
    return OfertaJuego(
      id: _readString(json['id']),
      nombre: _readString(json['nombre']),
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
