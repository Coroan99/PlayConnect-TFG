import { readFile } from "node:fs/promises";
import { getPool } from "../config/db.js";

const USUARIOS_TABLE_SQL_URL = new URL(
  "../../sql/create_usuarios_table.sql",
  import.meta.url,
);

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
