CREATE TABLE IF NOT EXISTS juegos (
  id CHAR(36) NOT NULL PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  codigo_barras VARCHAR(100) NULL,
  imagen_url VARCHAR(500) NULL,
  tipo_juego ENUM('videojuego', 'juego_mesa') NOT NULL,
  plataforma VARCHAR(120) NULL,
  jugadores_min INT UNSIGNED NULL,
  jugadores_max INT UNSIGNED NULL,
  duracion_minutos INT UNSIGNED NULL,
  descripcion TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_juegos_codigo_barras (codigo_barras)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
