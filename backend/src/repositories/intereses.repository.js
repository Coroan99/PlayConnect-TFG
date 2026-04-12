import { readFile } from "node:fs/promises";
import { getPool } from "../config/db.js";
import { ensurePublicacionesTable } from "./publicaciones.repository.js";

const BASE_SELECT = `
  SELECT
    it.id,
    it.created_at,
    iu.id AS usuario_interesado_id,
    iu.nombre AS usuario_interesado_nombre,
    p.id AS publicacion_id,
    p.descripcion AS publicacion_descripcion,
    p.created_at AS publicacion_created_at,
    inv.id AS inventario_id,
    inv.estado AS inventario_estado,
    inv.precio AS inventario_precio,
    pu.id AS propietario_id,
    pu.nombre AS propietario_nombre,
    j.id AS juego_id,
    j.nombre AS juego_nombre,
    j.codigo_barras AS juego_codigo_barras,
    j.imagen_url AS juego_imagen_url,
    j.tipo_juego AS juego_tipo_juego,
    j.plataforma AS juego_plataforma
  FROM intereses it
  INNER JOIN usuarios iu ON iu.id = it.usuario_id
  INNER JOIN publicaciones p ON p.id = it.publicacion_id
  INNER JOIN inventario inv ON inv.id = p.inventario_id
  INNER JOIN usuarios pu ON pu.id = inv.usuario_id
  INNER JOIN juegos j ON j.id = inv.juego_id
`;

const INTERESES_TABLE_SQL_URL = new URL(
  "../../sql/create_intereses_table.sql",
  import.meta.url,
);

let ensureTablePromise;

const mapInteresRow = (row) => ({
  id: row.id,
  created_at: row.created_at,
  usuario: {
    id: row.usuario_interesado_id,
    nombre: row.usuario_interesado_nombre,
  },
  publicacion: {
    id: row.publicacion_id,
    descripcion: row.publicacion_descripcion,
    created_at: row.publicacion_created_at,
    inventario: {
      id: row.inventario_id,
      estado: row.inventario_estado,
      precio: row.inventario_precio,
    },
    propietario: {
      id: row.propietario_id,
      nombre: row.propietario_nombre,
    },
    juego: {
      id: row.juego_id,
      nombre: row.juego_nombre,
      codigo_barras: row.juego_codigo_barras,
      imagen_url: row.juego_imagen_url,
      tipo_juego: row.juego_tipo_juego,
      plataforma: row.juego_plataforma,
    },
  },
});

export const ensureInteresesTable = async () => {
  if (!ensureTablePromise) {
    const pool = getPool();

    ensureTablePromise = (async () => {
      await ensurePublicacionesTable();
      const createTableSql = await readFile(INTERESES_TABLE_SQL_URL, "utf8");
      await pool.query(createTableSql);
    })().catch((error) => {
      ensureTablePromise = null;
      throw error;
    });
  }

  await ensureTablePromise;
};

export const generateInteresId = async () => {
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

export const findPublicacionReferenceById = async (id) => {
  const pool = getPool();
  const [rows] = await pool.execute(
    `SELECT
       p.id,
       p.descripcion,
       p.created_at,
       inv.id AS inventario_id,
       inv.usuario_id AS propietario_id,
       u.nombre AS propietario_nombre
     FROM publicaciones p
     INNER JOIN inventario inv ON inv.id = p.inventario_id
     INNER JOIN usuarios u ON u.id = inv.usuario_id
     WHERE p.id = ?
     LIMIT 1`,
    [id],
  );

  if (!rows[0]) {
    return null;
  }

  return {
    id: rows[0].id,
    descripcion: rows[0].descripcion,
    created_at: rows[0].created_at,
    inventario_id: rows[0].inventario_id,
    propietario: {
      id: rows[0].propietario_id,
      nombre: rows[0].propietario_nombre,
    },
  };
};

export const findInteresById = async (id) => {
  const pool = getPool();
  const [rows] = await pool.execute(
    `${BASE_SELECT} WHERE it.id = ? LIMIT 1`,
    [id],
  );

  return rows[0] ? mapInteresRow(rows[0]) : null;
};

export const findInteresByUsuarioAndPublicacion = async (usuarioId, publicacionId) => {
  const pool = getPool();
  const [rows] = await pool.execute(
    `SELECT id, usuario_id, publicacion_id, created_at
     FROM intereses
     WHERE usuario_id = ? AND publicacion_id = ?
     LIMIT 1`,
    [usuarioId, publicacionId],
  );

  return rows[0] ?? null;
};

export const findInteresesByPublicacionId = async (publicacionId) => {
  const pool = getPool();
  const [rows] = await pool.execute(
    `${BASE_SELECT} WHERE it.publicacion_id = ? ORDER BY it.created_at DESC`,
    [publicacionId],
  );

  return rows.map(mapInteresRow);
};

export const findInteresesByUsuarioId = async (usuarioId) => {
  const pool = getPool();
  const [rows] = await pool.execute(
    `${BASE_SELECT} WHERE it.usuario_id = ? ORDER BY it.created_at DESC`,
    [usuarioId],
  );

  return rows.map(mapInteresRow);
};

export const insertInteres = async (interes) => {
  const pool = getPool();

  await pool.execute(
    `INSERT INTO intereses (
      id,
      usuario_id,
      publicacion_id
    ) VALUES (?, ?, ?)`,
    [
      interes.id,
      interes.usuario_id,
      interes.publicacion_id,
    ],
  );
};

export const deleteInteres = async (id) => {
  const pool = getPool();
  const [result] = await pool.execute(
    "DELETE FROM intereses WHERE id = ?",
    [id],
  );

  return result.affectedRows;
};
