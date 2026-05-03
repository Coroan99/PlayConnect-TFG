import { getPool } from "../config/db.js";
import { ensureJuegosTable } from "./juegos.repository.js";
import { ensureUsuariosTable } from "./usuarios.repository.js";

const INVENTARIO_TABLE_SQL = `
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
`;

const BASE_SELECT = `
  SELECT
    i.id,
    i.usuario_id,
    u.nombre AS usuario_nombre,
    i.juego_id,
    j.nombre AS juego_nombre,
    j.codigo_barras AS juego_codigo_barras,
    j.imagen_url AS juego_imagen_url,
    j.tipo_juego AS juego_tipo_juego,
    j.plataforma AS juego_plataforma,
    j.jugadores_min AS juego_jugadores_min,
    j.jugadores_max AS juego_jugadores_max,
    j.duracion_minutos AS juego_duracion_minutos,
    j.descripcion AS juego_descripcion,
    j.manual_url AS juego_manual_url,
    p.id AS publicacion_id,
    p.descripcion AS publicacion_descripcion,
    p.created_at AS publicacion_created_at,
    i.estado,
    i.precio,
    i.created_at,
    i.updated_at
  FROM inventario i
  INNER JOIN usuarios u ON u.id = i.usuario_id
  INNER JOIN juegos j ON j.id = i.juego_id
  LEFT JOIN publicaciones p ON p.inventario_id = i.id
`;

let ensureTablePromise;

const mapInventarioRow = (row) => ({
  id: row.id,
  estado: row.estado,
  precio: row.precio,
  created_at: row.created_at,
  updated_at: row.updated_at,
  publicacion: row.publicacion_id
    ? {
        id: row.publicacion_id,
        descripcion: row.publicacion_descripcion,
        created_at: row.publicacion_created_at,
      }
    : null,
  usuario: {
    id: row.usuario_id,
    nombre: row.usuario_nombre,
  },
  juego: {
    id: row.juego_id,
    nombre: row.juego_nombre,
    codigo_barras: row.juego_codigo_barras,
    imagen_url: row.juego_imagen_url,
    tipo_juego: row.juego_tipo_juego,
    plataforma: row.juego_plataforma,
    jugadores_min: row.juego_jugadores_min,
    jugadores_max: row.juego_jugadores_max,
    duracion_minutos: row.juego_duracion_minutos,
    descripcion: row.juego_descripcion,
    manual_url: row.juego_manual_url,
  },
});

export const ensureInventarioTable = async () => {
  if (!ensureTablePromise) {
    const pool = getPool();

    ensureTablePromise = (async () => {
      await ensureUsuariosTable();
      await ensureJuegosTable();
      await pool.query(INVENTARIO_TABLE_SQL);
    })().catch((error) => {
      ensureTablePromise = null;
      throw error;
    });
  }

  await ensureTablePromise;
};

export const generateInventarioId = async () => {
  const pool = getPool();
  const [rows] = await pool.query("SELECT UUID() AS id");

  return rows[0]?.id ?? null;
};

export const findUsuarioReferenceById = async (id) => {
  const pool = getPool();
  const [rows] = await pool.execute(
    `SELECT id, nombre
     FROM usuarios
     WHERE id = ?
     LIMIT 1`,
    [id],
  );

  return rows[0] ?? null;
};

export const findJuegoReferenceById = async (id) => {
  const pool = getPool();
  const [rows] = await pool.execute(
    `SELECT id, nombre
     FROM juegos
     WHERE id = ?
     LIMIT 1`,
    [id],
  );

  return rows[0] ?? null;
};

export const findAllInventario = async () => {
  const pool = getPool();
  const [rows] = await pool.query(`${BASE_SELECT} ORDER BY i.created_at DESC`);
  return rows.map(mapInventarioRow);
};

export const findInventarioById = async (id) => {
  const pool = getPool();
  const [rows] = await pool.execute(
    `${BASE_SELECT} WHERE i.id = ? LIMIT 1`,
    [id],
  );

  return rows[0] ? mapInventarioRow(rows[0]) : null;
};

export const findInventarioByUsuarioId = async (usuarioId) => {
  const pool = getPool();
  const [rows] = await pool.execute(
    `${BASE_SELECT} WHERE i.usuario_id = ? ORDER BY i.created_at DESC`,
    [usuarioId],
  );

  return rows.map(mapInventarioRow);
};

export const findInventarioEnVenta = async () => {
  const pool = getPool();
  const [rows] = await pool.query(
    `${BASE_SELECT} WHERE i.estado = 'en_venta' ORDER BY i.updated_at DESC`,
  );

  return rows.map(mapInventarioRow);
};

export const insertInventario = async (inventario) => {
  const pool = getPool();

  await pool.execute(
    `INSERT INTO inventario (
      id,
      usuario_id,
      juego_id,
      estado,
      precio
    ) VALUES (?, ?, ?, ?, ?)`,
    [
      inventario.id,
      inventario.usuario_id,
      inventario.juego_id,
      inventario.estado,
      inventario.precio,
    ],
  );
};

export const updateInventario = async (id, inventario) => {
  const pool = getPool();
  const [result] = await pool.execute(
    `UPDATE inventario
     SET
       usuario_id = ?,
       juego_id = ?,
       estado = ?,
       precio = ?
     WHERE id = ?`,
    [
      inventario.usuario_id,
      inventario.juego_id,
      inventario.estado,
      inventario.precio,
      id,
    ],
  );

  return result.affectedRows;
};

export const deleteInventario = async (id) => {
  const pool = getPool();
  const [result] = await pool.execute(
    "DELETE FROM inventario WHERE id = ?",
    [id],
  );

  return result.affectedRows;
};
