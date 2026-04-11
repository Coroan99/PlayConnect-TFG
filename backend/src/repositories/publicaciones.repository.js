import { getPool } from "../config/db.js";
import { ensureInventarioTable } from "./inventario.repository.js";

const PUBLICACIONES_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS publicaciones (
    id CHAR(36) NOT NULL PRIMARY KEY,
    inventario_id CHAR(36) NOT NULL,
    descripcion TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_publicaciones_inventario_id (inventario_id),
    KEY idx_publicaciones_created_at (created_at),
    CONSTRAINT fk_publicaciones_inventario
      FOREIGN KEY (inventario_id) REFERENCES inventario(id)
      ON UPDATE CASCADE
      ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
`;

const BASE_SELECT = `
  SELECT
    p.id,
    p.descripcion,
    p.created_at,
    i.id AS inventario_id,
    i.estado AS inventario_estado,
    i.precio AS inventario_precio,
    u.id AS usuario_id,
    u.nombre AS usuario_nombre,
    j.id AS juego_id,
    j.nombre AS juego_nombre,
    j.codigo_barras AS juego_codigo_barras,
    j.imagen_url AS juego_imagen_url,
    j.tipo_juego AS juego_tipo_juego,
    j.plataforma AS juego_plataforma
  FROM publicaciones p
  INNER JOIN inventario i ON i.id = p.inventario_id
  INNER JOIN usuarios u ON u.id = i.usuario_id
  INNER JOIN juegos j ON j.id = i.juego_id
`;

let ensureTablePromise;

const mapPublicacionRow = (row) => ({
  id: row.id,
  descripcion: row.descripcion,
  created_at: row.created_at,
  inventario: {
    id: row.inventario_id,
    estado: row.inventario_estado,
    precio: row.inventario_precio,
  },
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
  },
});

export const ensurePublicacionesTable = async () => {
  if (!ensureTablePromise) {
    const pool = getPool();

    ensureTablePromise = (async () => {
      await ensureInventarioTable();
      await pool.query(PUBLICACIONES_TABLE_SQL);
    })().catch((error) => {
      ensureTablePromise = null;
      throw error;
    });
  }

  await ensureTablePromise;
};

export const generatePublicacionId = async () => {
  const pool = getPool();
  const [rows] = await pool.query("SELECT UUID() AS id");

  return rows[0]?.id ?? null;
};

export const findAllPublicaciones = async () => {
  const pool = getPool();
  const [rows] = await pool.query(`${BASE_SELECT} ORDER BY p.created_at DESC`);
  return rows.map(mapPublicacionRow);
};

export const findPublicacionById = async (id) => {
  const pool = getPool();
  const [rows] = await pool.execute(
    `${BASE_SELECT} WHERE p.id = ? LIMIT 1`,
    [id],
  );

  return rows[0] ? mapPublicacionRow(rows[0]) : null;
};

export const insertPublicacion = async (publicacion) => {
  const pool = getPool();

  await pool.execute(
    `INSERT INTO publicaciones (
      id,
      inventario_id,
      descripcion
    ) VALUES (?, ?, ?)`,
    [
      publicacion.id,
      publicacion.inventario_id,
      publicacion.descripcion,
    ],
  );
};

export const deletePublicacion = async (id) => {
  const pool = getPool();
  const [result] = await pool.execute(
    "DELETE FROM publicaciones WHERE id = ?",
    [id],
  );

  return result.affectedRows;
};
