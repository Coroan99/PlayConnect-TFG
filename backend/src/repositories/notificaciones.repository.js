import { readFile } from "node:fs/promises";
import { getPool } from "../config/db.js";
import { ensureUsuariosTable } from "./usuarios.repository.js";

const BASE_SELECT = `
  SELECT
    n.id,
    n.tipo,
    n.mensaje,
    n.leida,
    n.referencia_id,
    n.referencia_tipo,
    n.metadata,
    n.created_at,
    n.read_at,
    u.id AS usuario_id,
    u.nombre AS usuario_nombre,
    em.id AS emisor_id,
    em.nombre AS emisor_nombre
  FROM notificaciones n
  INNER JOIN usuarios u ON u.id = n.usuario_id
  LEFT JOIN usuarios em ON em.id = n.emisor_id
`;

const NOTIFICACIONES_TABLE_SQL_URL = new URL(
  "../../sql/create_notificaciones_table.sql",
  import.meta.url,
);

let ensureTablePromise;

const getExecutor = (executor) => executor ?? getPool();

const parseMetadata = (metadata) => {
  if (metadata === undefined || metadata === null) {
    return null;
  }

  if (typeof metadata === "object") {
    return metadata;
  }

  if (typeof metadata !== "string") {
    return null;
  }

  const normalizedMetadata = metadata.trim();

  if (!normalizedMetadata) {
    return null;
  }

  try {
    return JSON.parse(normalizedMetadata);
  } catch (error) {
    return null;
  }
};

const mapNotificacionRow = (row) => ({
  id: row.id,
  tipo: row.tipo,
  mensaje: row.mensaje,
  leida: Boolean(row.leida),
  created_at: row.created_at,
  read_at: row.read_at,
  usuario: {
    id: row.usuario_id,
    nombre: row.usuario_nombre,
  },
  emisor: row.emisor_id
    ? {
        id: row.emisor_id,
        nombre: row.emisor_nombre,
      }
    : null,
  referencia: row.referencia_id
    ? {
        id: row.referencia_id,
        tipo: row.referencia_tipo,
      }
    : null,
  metadata: parseMetadata(row.metadata),
});

export const ensureNotificacionesTable = async () => {
  if (!ensureTablePromise) {
    const pool = getPool();

    ensureTablePromise = (async () => {
      await ensureUsuariosTable();
      const createTableSql = await readFile(NOTIFICACIONES_TABLE_SQL_URL, "utf8");
      await pool.query(createTableSql);
    })().catch((error) => {
      ensureTablePromise = null;
      throw error;
    });
  }

  await ensureTablePromise;
};

export const generateNotificacionId = async (executor) => {
  const db = getExecutor(executor);
  const [rows] = await db.query("SELECT UUID() AS id");

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

export const findNotificacionById = async (id, executor) => {
  const db = getExecutor(executor);
  const [rows] = await db.execute(
    `${BASE_SELECT} WHERE n.id = ? LIMIT 1`,
    [id],
  );

  return rows[0] ? mapNotificacionRow(rows[0]) : null;
};

export const findNotificacionesByUsuarioId = async (usuarioId, executor) => {
  const db = getExecutor(executor);
  const [rows] = await db.execute(
    `${BASE_SELECT}
     WHERE n.usuario_id = ?
     ORDER BY n.created_at DESC, n.id DESC`,
    [usuarioId],
  );

  return rows.map(mapNotificacionRow);
};

export const countUnreadNotificacionesByUsuarioId = async (
  usuarioId,
  executor,
) => {
  const db = getExecutor(executor);
  const [rows] = await db.execute(
    `SELECT COUNT(*) AS total
     FROM notificaciones
     WHERE usuario_id = ?
       AND leida = 0`,
    [usuarioId],
  );

  return Number(rows[0]?.total ?? 0);
};

export const findNotificacionByUserTypeAndReference = async (
  usuarioId,
  tipo,
  referenciaTipo,
  referenciaId,
  executor,
) => {
  const db = getExecutor(executor);
  const [rows] = await db.execute(
    `${BASE_SELECT}
     WHERE n.usuario_id = ?
       AND n.tipo = ?
       AND n.referencia_tipo = ?
       AND n.referencia_id = ?
     LIMIT 1`,
    [usuarioId, tipo, referenciaTipo, referenciaId],
  );

  return rows[0] ? mapNotificacionRow(rows[0]) : null;
};

export const insertNotificacion = async (notificacion, executor) => {
  const db = getExecutor(executor);

  await db.execute(
    `INSERT INTO notificaciones (
      id,
      usuario_id,
      tipo,
      mensaje,
      referencia_id,
      referencia_tipo,
      emisor_id,
      metadata
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      notificacion.id,
      notificacion.usuario_id,
      notificacion.tipo,
      notificacion.mensaje,
      notificacion.referencia_id,
      notificacion.referencia_tipo,
      notificacion.emisor_id,
      notificacion.metadata ? JSON.stringify(notificacion.metadata) : null,
    ],
  );
};

export const markNotificacionAsReadById = async (id, executor) => {
  const db = getExecutor(executor);
  const [result] = await db.execute(
    `UPDATE notificaciones
     SET leida = 1,
         read_at = COALESCE(read_at, CURRENT_TIMESTAMP)
     WHERE id = ?
       AND leida = 0`,
    [id],
  );

  return result.affectedRows;
};

export const markAllNotificacionesAsReadByUsuarioId = async (
  usuarioId,
  executor,
) => {
  const db = getExecutor(executor);
  const [result] = await db.execute(
    `UPDATE notificaciones
     SET leida = 1,
         read_at = COALESCE(read_at, CURRENT_TIMESTAMP)
     WHERE usuario_id = ?
       AND leida = 0`,
    [usuarioId],
  );

  return result.affectedRows;
};

export const deleteNotificacion = async (id, executor) => {
  const db = getExecutor(executor);
  const [result] = await db.execute(
    "DELETE FROM notificaciones WHERE id = ?",
    [id],
  );

  return result.affectedRows;
};
