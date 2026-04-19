import { readFile } from "node:fs/promises";
import { getPool } from "../config/db.js";
import { ensurePublicacionesTable } from "./publicaciones.repository.js";
import { ensureUsuariosTable } from "./usuarios.repository.js";

const BASE_SELECT = `
  SELECT
    o.id,
    o.precio_ofrecido,
    o.mensaje,
    o.estado,
    o.created_at,
    o.updated_at,
    ou.id AS ofertante_id,
    ou.nombre AS ofertante_nombre,
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
  FROM ofertas o
  INNER JOIN usuarios ou ON ou.id = o.usuario_id
  INNER JOIN publicaciones p ON p.id = o.publicacion_id
  INNER JOIN inventario inv ON inv.id = p.inventario_id
  INNER JOIN usuarios pu ON pu.id = inv.usuario_id
  INNER JOIN juegos j ON j.id = inv.juego_id
`;

const OFERTAS_TABLE_SQL_URL = new URL(
  "../sql/create_ofertas_table.sql",
  import.meta.url,
);

let ensureTablePromise;

const getExecutor = (executor) => executor ?? getPool();

const mapOfertaRow = (row) => ({
  id: row.id,
  precio_ofrecido: row.precio_ofrecido,
  mensaje: row.mensaje,
  estado: row.estado,
  created_at: row.created_at,
  updated_at: row.updated_at,
  usuario: {
    id: row.ofertante_id,
    nombre: row.ofertante_nombre,
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

export const ensureOfertasTable = async () => {
  if (!ensureTablePromise) {
    const pool = getPool();

    ensureTablePromise = (async () => {
      await ensureUsuariosTable();
      await ensurePublicacionesTable();
      const createTableSql = await readFile(OFERTAS_TABLE_SQL_URL, "utf8");
      await pool.query(createTableSql);
    })().catch((error) => {
      ensureTablePromise = null;
      throw error;
    });
  }

  await ensureTablePromise;
};

export const runOfertasTransaction = async (callback) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    const result = await callback(connection);
    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

export const generateOfertaId = async () => {
  const pool = getPool();
  const [rows] = await pool.query("SELECT UUID() AS id");

  return rows[0]?.id ?? null;
};

export const findUsuarioReferenceById = async (id, executor) => {
  const db = getExecutor(executor);
  const [rows] = await db.execute(
    `SELECT id, nombre
     FROM usuarios
     WHERE id = ?
     LIMIT 1`,
    [id],
  );

  return rows[0] ?? null;
};

export const findPublicacionReferenceById = async (id, executor) => {
  const db = getExecutor(executor);
  const [rows] = await db.execute(
    `SELECT
       p.id,
       p.descripcion,
       p.created_at,
       inv.id AS inventario_id,
       inv.estado AS inventario_estado,
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
    inventario_estado: rows[0].inventario_estado,
    propietario: {
      id: rows[0].propietario_id,
      nombre: rows[0].propietario_nombre,
    },
  };
};

export const lockPublicacionById = async (id, executor) => {
  const db = getExecutor(executor);
  const [rows] = await db.execute(
    `SELECT id
     FROM publicaciones
     WHERE id = ?
     LIMIT 1
     FOR UPDATE`,
    [id],
  );

  return rows[0] ?? null;
};

export const findOfertaById = async (id, executor) => {
  const db = getExecutor(executor);
  const [rows] = await db.execute(
    `${BASE_SELECT} WHERE o.id = ? LIMIT 1`,
    [id],
  );

  return rows[0] ? mapOfertaRow(rows[0]) : null;
};

export const findOfertaStateById = async (id, executor, { forUpdate = false } = {}) => {
  const db = getExecutor(executor);
  const [rows] = await db.execute(
    `SELECT
       id,
       usuario_id,
       publicacion_id,
       estado
     FROM ofertas
     WHERE id = ?
     LIMIT 1${forUpdate ? " FOR UPDATE" : ""}`,
    [id],
  );

  return rows[0] ?? null;
};

export const findAcceptedOfertaByPublicacionId = async (
  publicacionId,
  executor,
  { excludeOfertaId } = {},
) => {
  const db = getExecutor(executor);
  const params = [publicacionId];
  let sql = `
    SELECT id, publicacion_id, estado
    FROM ofertas
    WHERE publicacion_id = ?
      AND estado = 'aceptada'
  `;

  if (excludeOfertaId) {
    sql += " AND id <> ?";
    params.push(excludeOfertaId);
  }

  sql += " LIMIT 1";

  const [rows] = await db.execute(sql, params);

  return rows[0] ?? null;
};

export const findOfertasByPublicacionId = async (publicacionId, executor) => {
  const db = getExecutor(executor);
  const [rows] = await db.execute(
    `${BASE_SELECT} WHERE o.publicacion_id = ? ORDER BY o.created_at DESC`,
    [publicacionId],
  );

  return rows.map(mapOfertaRow);
};

export const findOfertasSentByUsuarioId = async (usuarioId, executor) => {
  const db = getExecutor(executor);
  const [rows] = await db.execute(
    `${BASE_SELECT} WHERE o.usuario_id = ? ORDER BY o.created_at DESC`,
    [usuarioId],
  );

  return rows.map(mapOfertaRow);
};

export const findOfertasReceivedByUsuarioId = async (usuarioId, executor) => {
  const db = getExecutor(executor);
  const [rows] = await db.execute(
    `${BASE_SELECT} WHERE pu.id = ? ORDER BY o.created_at DESC`,
    [usuarioId],
  );

  return rows.map(mapOfertaRow);
};

export const insertOferta = async (oferta, executor) => {
  const db = getExecutor(executor);

  await db.execute(
    `INSERT INTO ofertas (
      id,
      usuario_id,
      publicacion_id,
      precio_ofrecido,
      mensaje,
      estado
    ) VALUES (?, ?, ?, ?, ?, ?)`,
    [
      oferta.id,
      oferta.usuario_id,
      oferta.publicacion_id,
      oferta.precio_ofrecido,
      oferta.mensaje,
      oferta.estado,
    ],
  );
};

export const updateOfertaEstadoIfCurrent = async (
  id,
  currentEstado,
  nextEstado,
  executor,
) => {
  const db = getExecutor(executor);
  const [result] = await db.execute(
    `UPDATE ofertas
     SET estado = ?
     WHERE id = ?
       AND estado = ?`,
    [nextEstado, id, currentEstado],
  );

  return result.affectedRows;
};

export const rejectPendingOfertasByPublicacionId = async (
  publicacionId,
  excludedOfertaId,
  executor,
) => {
  const db = getExecutor(executor);
  const [result] = await db.execute(
    `UPDATE ofertas
     SET estado = 'rechazada'
     WHERE publicacion_id = ?
       AND id <> ?
       AND estado = 'pendiente'`,
    [publicacionId, excludedOfertaId],
  );

  return result.affectedRows;
};

export const deleteOfertaIfPending = async (id, executor) => {
  const db = getExecutor(executor);
  const [result] = await db.execute(
    `DELETE FROM ofertas
     WHERE id = ?
       AND estado = 'pendiente'`,
    [id],
  );

  return result.affectedRows;
};
