class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.tipo,
    this.ciudad,
    this.createdAt,
  });

  final String id;
  final String nombre;
  final String email;
  final String tipo;
  final String? ciudad;
  final DateTime? createdAt;

  String get tipoLabel {
    return switch (tipo) {
      'tienda' => 'Tienda',
      _ => 'Jugador',
    };
  }

  factory Usuario.fromJson(Map<String, Object?> json) {
    final createdAtValue = json['created_at'] ?? json['createdAt'];

    return Usuario(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'normal',
      ciudad: _readNullableString(
        json['ciudad'] ?? _readMap(json['ubicacion'])['ciudad'],
      ),
      createdAt: createdAtValue is String
          ? DateTime.tryParse(createdAtValue)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'tipo': tipo,
      if (ciudad != null) 'ciudad': ciudad,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
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

String? _readNullableString(Object? value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
