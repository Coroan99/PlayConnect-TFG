import { readFile } from "node:fs/promises";
import { getPool } from "../config/db.js";

const USUARIOS_TABLE_SQL_URL = new URL(
  "../../sql/create_usuarios_table.sql",
  import.meta.url,
);

const BASE_PUBLIC_SELECT = `
  SELECT
    id,
    nombre,
    email,
    tipo,
    created_at,
    updated_at
  FROM usuarios
`;

const BASE_AUTH_SELECT = `
  SELECT
    id,
    nombre,
    email,
    password,
    tipo,
    created_at,
    updated_at
  FROM usuarios
`;

let ensureTablePromise;

export const ensureUsuariosTable = async () => {
  if (!ensureTablePromise) {
    const pool = getPool();

    ensureTablePromise = (async () => {
      const createTableSql = await readFile(USUARIOS_TABLE_SQL_URL, "utf8");
      await pool.query(createTableSql);
    })().catch((error) => {
      ensureTablePromise = null;
      throw error;
    });
  }

  await ensureTablePromise;
};

export const generateUsuarioId = async () => {
  const pool = getPool();
  const [rows] = await pool.query("SELECT UUID() AS id");

  return rows[0]?.id ?? null;
};

export const findAllUsuarios = async () => {
  const pool = getPool();
  const [rows] = await pool.query(
    `${BASE_PUBLIC_SELECT} ORDER BY created_at DESC`,
  );

  return rows;
};

export const findUsuarioById = async (id) => {
  const pool = getPool();
  const [rows] = await pool.execute(
    `${BASE_PUBLIC_SELECT} WHERE id = ? LIMIT 1`,
    [id],
  );

  return rows[0] ?? null;
};

export const findUsuarioWithPasswordByEmail = async (email) => {
  const pool = getPool();
  const [rows] = await pool.execute(
    `${BASE_AUTH_SELECT} WHERE email = ? LIMIT 1`,
    [email],
  );

  return rows[0] ?? null;
};

export const insertUsuario = async (usuario) => {
  const pool = getPool();

  await pool.execute(
    `INSERT INTO usuarios (
      id,
      nombre,
      email,
      password,
      tipo
    ) VALUES (?, ?, ?, ?, ?)`,
    [
      usuario.id,
      usuario.nombre,
      usuario.email,
      usuario.password,
      usuario.tipo,
    ],
  );
};

export const updateUsuarioPassword = async (id, password) => {
  const pool = getPool();
  const [result] = await pool.execute(
    `UPDATE usuarios
     SET password = ?
     WHERE id = ?`,
    [password, id],
  );

  return result.affectedRows;
};
