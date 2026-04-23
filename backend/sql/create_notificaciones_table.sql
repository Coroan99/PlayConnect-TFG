CREATE TABLE IF NOT EXISTS notificaciones (
  id CHAR(36) NOT NULL PRIMARY KEY,
  usuario_id CHAR(36) NOT NULL,
  tipo VARCHAR(50) NOT NULL,
  mensaje TEXT NOT NULL,
  leida TINYINT(1) NOT NULL DEFAULT 0,
  referencia_id CHAR(36) NULL,
  referencia_tipo VARCHAR(50) NULL,
  emisor_id CHAR(36) NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  read_at TIMESTAMP NULL DEFAULT NULL,
  KEY idx_notificaciones_usuario_created_at (usuario_id, created_at),
  KEY idx_notificaciones_usuario_leida_created_at (usuario_id, leida, created_at),
  KEY idx_notificaciones_tipo (tipo),
  KEY idx_notificaciones_referencia (referencia_tipo, referencia_id),
  KEY idx_notificaciones_emisor_id (emisor_id),
  UNIQUE KEY uq_notificaciones_usuario_tipo_referencia (
    usuario_id,
    tipo,
    referencia_tipo,
    referencia_id
  ),
  CONSTRAINT chk_notificaciones_leida
    CHECK (leida IN (0, 1)),
  CONSTRAINT fk_notificaciones_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_notificaciones_emisor
    FOREIGN KEY (emisor_id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
