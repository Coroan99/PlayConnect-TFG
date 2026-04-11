import { getPool } from "../config/db.js";

const JUEGOS_TABLE_SQL = `
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
`;

const BASE_SELECT = `
  SELECT
    id,
    nombre,
    codigo_barras,
    imagen_url,
    tipo_juego,
    plataforma,
    jugadores_min,
    jugadores_max,
    duracion_minutos,
    descripcion,
    created_at,
    updated_at
  FROM juegos
`;

let ensureTablePromise;

export const ensureJuegosTable = async () => {
  if (!ensureTablePromise) {
    const pool = getPool();

    ensureTablePromise = pool.query(JUEGOS_TABLE_SQL).catch((error) => {
      ensureTablePromise = null;
      throw error;
    });
  }

  await ensureTablePromise;
};

export const generateJuegoId = async () => {
  const pool = getPool();
  const [rows] = await pool.query("SELECT UUID() AS id");

  return rows[0]?.id ?? null;
};

export const findAllJuegos = async () => {
  const pool = getPool();
  const [rows] = await pool.query(`${BASE_SELECT} ORDER BY created_at DESC`);
  return rows;
};

export const findJuegoById = async (id) => {
  const pool = getPool();
  const [rows] = await pool.execute(
    `${BASE_SELECT} WHERE id = ? LIMIT 1`,
    [id],
  );

  return rows[0] ?? null;
};

export const findJuegoByBarcode = async (codigoBarras) => {
  const pool = getPool();
  const [rows] = await pool.execute(
    `${BASE_SELECT} WHERE codigo_barras = ? LIMIT 1`,
    [codigoBarras],
  );

  return rows[0] ?? null;
};

export const insertJuego = async (juego) => {
  const pool = getPool();

  await pool.execute(
    `INSERT INTO juegos (
      id,
      nombre,
      codigo_barras,
      imagen_url,
      tipo_juego,
      plataforma,
      jugadores_min,
      jugadores_max,
      duracion_minutos,
      descripcion
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      juego.id,
      juego.nombre,
      juego.codigo_barras,
      juego.imagen_url,
      juego.tipo_juego,
      juego.plataforma,
      juego.jugadores_min,
      juego.jugadores_max,
      juego.duracion_minutos,
      juego.descripcion,
    ],
  );
};

export const updateJuego = async (id, juego) => {
  const pool = getPool();
  const [result] = await pool.execute(
    `UPDATE juegos
     SET
       nombre = ?,
       codigo_barras = ?,
       imagen_url = ?,
       tipo_juego = ?,
       plataforma = ?,
       jugadores_min = ?,
       jugadores_max = ?,
       duracion_minutos = ?,
       descripcion = ?
     WHERE id = ?`,
    [
      juego.nombre,
      juego.codigo_barras,
      juego.imagen_url,
      juego.tipo_juego,
      juego.plataforma,
      juego.jugadores_min,
      juego.jugadores_max,
      juego.duracion_minutos,
      juego.descripcion,
      id,
    ],
  );

  return result.affectedRows;
};

export const deleteJuego = async (id) => {
  const pool = getPool();
  const [result] = await pool.execute(
    "DELETE FROM juegos WHERE id = ?",
    [id],
  );

  return result.affectedRows;
};
