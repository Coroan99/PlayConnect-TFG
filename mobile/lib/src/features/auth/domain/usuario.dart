class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.tipo,
    this.createdAt,
  });

  final String id;
  final String nombre;
  final String email;
  final String tipo;
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
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
