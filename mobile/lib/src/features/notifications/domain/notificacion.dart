class Notificacion {
  const Notificacion({
    required this.id,
    required this.tipo,
    required this.mensaje,
    required this.leida,
    required this.createdAt,
    this.readAt,
    this.usuario,
    this.emisor,
    this.referencia,
    this.metadata,
  });

  final String id;
  final NotificacionTipo tipo;
  final String mensaje;
  final bool leida;
  final DateTime? createdAt;
  final DateTime? readAt;
  final NotificacionUsuario? usuario;
  final NotificacionUsuario? emisor;
  final NotificacionReferencia? referencia;
  final Map<String, Object?>? metadata;

  Notificacion copyWith({bool? leida, DateTime? readAt}) {
    return Notificacion(
      id: id,
      tipo: tipo,
      mensaje: mensaje,
      leida: leida ?? this.leida,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      usuario: usuario,
      emisor: emisor,
      referencia: referencia,
      metadata: metadata,
    );
  }

  factory Notificacion.fromJson(Map<String, Object?> json) {
    return Notificacion(
      id: _readString(json['id']),
      tipo: NotificacionTipo.fromApi(_readString(json['tipo'])),
      mensaje: _readString(json['mensaje']),
      leida: json['leida'] == true,
      createdAt: _readDate(json['created_at'] ?? json['createdAt']),
      readAt: _readDate(json['read_at'] ?? json['readAt']),
      usuario: _readOptionalUser(json['usuario']),
      emisor: _readOptionalUser(json['emisor']),
      referencia: _readOptionalReference(json['referencia']),
      metadata: _readOptionalMap(json['metadata']),
    );
  }
}

enum NotificacionTipo {
  ofertaRecibida('OFERTA_RECIBIDA', 'Oferta recibida'),
  ofertaAceptada('OFERTA_ACEPTADA', 'Oferta aceptada'),
  ofertaRechazada('OFERTA_RECHAZADA', 'Oferta rechazada'),
  interesNuevo('INTERES_NUEVO', 'Nuevo interes'),
  muchoInteres('MUCHO_INTERES', 'Mucho interes'),
  desconocida('', 'Notificacion');

  const NotificacionTipo(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static NotificacionTipo fromApi(String value) {
    return NotificacionTipo.values.firstWhere(
      (tipo) => tipo.apiValue == value,
      orElse: () => NotificacionTipo.desconocida,
    );
  }
}

class NotificacionUsuario {
  const NotificacionUsuario({required this.id, required this.nombre});

  final String id;
  final String nombre;

  factory NotificacionUsuario.fromJson(Map<String, Object?> json) {
    return NotificacionUsuario(
      id: _readString(json['id']),
      nombre: _readString(json['nombre']),
    );
  }
}

class NotificacionReferencia {
  const NotificacionReferencia({required this.id, required this.tipo});

  final String id;
  final String tipo;

  String get label {
    return switch (tipo) {
      'OFERTA' => 'Oferta',
      'INTERES' => 'Interes',
      'PUBLICACION' => 'Publicacion',
      'INVENTARIO' => 'Inventario',
      'JUEGO' => 'Juego',
      'SISTEMA' => 'Sistema',
      _ => tipo,
    };
  }

  factory NotificacionReferencia.fromJson(Map<String, Object?> json) {
    return NotificacionReferencia(
      id: _readString(json['id']),
      tipo: _readString(json['tipo']),
    );
  }
}

NotificacionUsuario? _readOptionalUser(Object? value) {
  final json = _readOptionalMap(value);

  if (json == null) {
    return null;
  }

  return NotificacionUsuario.fromJson(json);
}

NotificacionReferencia? _readOptionalReference(Object? value) {
  final json = _readOptionalMap(value);

  if (json == null) {
    return null;
  }

  return NotificacionReferencia.fromJson(json);
}

Map<String, Object?>? _readOptionalMap(Object? value) {
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

DateTime? _readDate(Object? value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}
