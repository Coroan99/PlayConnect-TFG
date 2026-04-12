CREATE TABLE IF NOT EXISTS intereses (
  id CHAR(36) NOT NULL PRIMARY KEY,
  usuario_id CHAR(36) NOT NULL,
  publicacion_id CHAR(36) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_intereses_usuario_publicacion (usuario_id, publicacion_id),
  KEY idx_intereses_usuario_id (usuario_id),
  KEY idx_intereses_publicacion_id (publicacion_id),
  CONSTRAINT fk_intereses_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_intereses_publicacion
    FOREIGN KEY (publicacion_id) REFERENCES publicaciones(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
