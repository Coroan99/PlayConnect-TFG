import { readFile } from "node:fs/promises";
import { getPool } from "../config/db.js";

const JUEGOS_TABLE_SQL_URL = new URL(
  "../../sql/create_juegos_table.sql",
  import.meta.url,
);

const COLUMN_MIGRATIONS = [
  {
    name: "imagen_url",
    definition: "ADD COLUMN imagen_url VARCHAR(500) NULL AFTER codigo_barras",
  },
  {
    name: "jugadores_min",
    definition: "ADD COLUMN jugadores_min INT UNSIGNED NULL AFTER plataforma",
  },
  {
    name: "jugadores_max",
    definition:
      "ADD COLUMN jugadores_max INT UNSIGNED NULL AFTER jugadores_min",
  },
  {
    name: "duracion_minutos",
    definition:
      "ADD COLUMN duracion_minutos INT UNSIGNED NULL AFTER jugadores_max",
  },
  {
    name: "descripcion",
    definition: "ADD COLUMN descripcion TEXT NULL AFTER duracion_minutos",
  },
  {
    name: "manual_url",
    definition: "ADD COLUMN manual_url VARCHAR(500) NULL AFTER descripcion",
  },
];

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
    manual_url,
    created_at,
    updated_at
  FROM juegos
`;

let ensureTablePromise;

export const ensureJuegosTable = async () => {
  if (!ensureTablePromise) {
    const pool = getPool();

    ensureTablePromise = (async () => {
      const createTableSql = await readFile(JUEGOS_TABLE_SQL_URL, "utf8");
      await pool.query(createTableSql);

      for (const migration of COLUMN_MIGRATIONS) {
        const [columns] = await pool.query(
          `SHOW COLUMNS FROM juegos LIKE ?`,
          [migration.name],
        );

        if (columns.length === 0) {
          await pool.query(
            `ALTER TABLE juegos ${migration.definition}`,
          );
        }
      }
    })().catch((error) => {
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
      descripcion,
      manual_url
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
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
      juego.manual_url,
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
       descripcion = ?,
       manual_url = ?
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
      juego.manual_url,
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
