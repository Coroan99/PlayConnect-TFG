CREATE TABLE IF NOT EXISTS ofertas (
  id CHAR(36) NOT NULL PRIMARY KEY,
  usuario_id CHAR(36) NOT NULL,
  publicacion_id CHAR(36) NOT NULL,
  precio_ofrecido DECIMAL(10,2) NOT NULL,
  mensaje TEXT NULL,
  estado ENUM('pendiente', 'aceptada', 'rechazada', 'cancelada') NOT NULL DEFAULT 'pendiente',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_ofertas_usuario_created_at (usuario_id, created_at),
  KEY idx_ofertas_publicacion_created_at (publicacion_id, created_at),
  KEY idx_ofertas_publicacion_estado (publicacion_id, estado),
  KEY idx_ofertas_estado (estado),
  CONSTRAINT chk_ofertas_precio_ofrecido
    CHECK (precio_ofrecido > 0),
  CONSTRAINT fk_ofertas_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_ofertas_publicacion
    FOREIGN KEY (publicacion_id) REFERENCES publicaciones(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
