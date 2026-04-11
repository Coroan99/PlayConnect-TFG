CREATE TABLE IF NOT EXISTS inventario (
  id CHAR(36) NOT NULL PRIMARY KEY,
  usuario_id CHAR(36) NOT NULL,
  juego_id CHAR(36) NOT NULL,
  estado ENUM('coleccion', 'visible', 'en_venta') NOT NULL,
  precio DECIMAL(10,2) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_inventario_usuario_juego (usuario_id, juego_id),
  KEY idx_inventario_usuario_id (usuario_id),
  KEY idx_inventario_juego_id (juego_id),
  KEY idx_inventario_estado (estado),
  CONSTRAINT fk_inventario_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_inventario_juego
    FOREIGN KEY (juego_id) REFERENCES juegos(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
