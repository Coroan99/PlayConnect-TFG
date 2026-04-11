CREATE TABLE IF NOT EXISTS publicaciones (
  id CHAR(36) NOT NULL PRIMARY KEY,
  inventario_id CHAR(36) NOT NULL,
  descripcion TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_publicaciones_inventario_id (inventario_id),
  KEY idx_publicaciones_created_at (created_at),
  KEY idx_publicaciones_inventario_id (inventario_id),
  CONSTRAINT fk_publicaciones_inventario
    FOREIGN KEY (inventario_id) REFERENCES inventario(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
