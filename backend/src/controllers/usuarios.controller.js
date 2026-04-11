import { getPool } from "../config/db.js";
import { sendError, sendSuccess } from "../utils/response.js";

const ALLOWED_USER_TYPES = new Set(["normal", "tienda"]);
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const getUsuarios = async (req, res) => {
  try {
    const pool = getPool();
    const [rows] = await pool.query(
      "SELECT id, nombre, email, tipo, created_at FROM usuarios ORDER BY created_at DESC",
    );

    return sendSuccess(res, {
      message: "Usuarios obtenidos correctamente",
      data: rows,
    });
  } catch (error) {
    console.error("Error obteniendo usuarios:", error.message);

    return sendError(res, {
      statusCode: 500,
      message: "Error obteniendo usuarios",
      error: error.message,
    });
  }
};

export const createUsuario = async (req, res) => {
  try {
    if (!req.body || typeof req.body !== "object" || Array.isArray(req.body)) {
      return sendError(res, {
        statusCode: 400,
        message: "El cuerpo de la petición debe ser un JSON válido",
      });
    }

    const { nombre, email, password, tipo } = req.body;

    const normalizedNombre = typeof nombre === "string" ? nombre.trim() : "";
    const normalizedEmail = typeof email === "string" ? email.trim().toLowerCase() : "";
    const passwordValue = typeof password === "string" ? password : "";
    const normalizedTipo = typeof tipo === "string" ? tipo.trim().toLowerCase() : "";

    if (!normalizedNombre) {
      return sendError(res, {
        statusCode: 400,
        message: "El nombre es obligatorio",
      });
    }

    if (!normalizedEmail) {
      return sendError(res, {
        statusCode: 400,
        message: "El email es obligatorio",
      });
    }

    if (!EMAIL_REGEX.test(normalizedEmail)) {
      return sendError(res, {
        statusCode: 400,
        message: "El email no tiene un formato válido",
      });
    }

    if (!passwordValue.trim()) {
      return sendError(res, {
        statusCode: 400,
        message: "La password es obligatoria",
      });
    }

    if (!normalizedTipo) {
      return sendError(res, {
        statusCode: 400,
        message: "El tipo es obligatorio",
      });
    }

    if (!ALLOWED_USER_TYPES.has(normalizedTipo)) {
      return sendError(res, {
        statusCode: 400,
        message: "El tipo debe ser 'normal' o 'tienda'",
      });
    }

    const pool = getPool();
    const [uuidRows] = await pool.query("SELECT UUID() AS id");
    const userId = uuidRows[0]?.id;

    if (!userId) {
      throw new Error("No se pudo generar el identificador del usuario");
    }

    await pool.execute(
      `INSERT INTO usuarios (id, nombre, email, password, tipo)
       VALUES (?, ?, ?, ?, ?)`,
      [userId, normalizedNombre, normalizedEmail, passwordValue, normalizedTipo],
    );

    const [rows] = await pool.execute(
      `SELECT id, nombre, email, tipo, created_at
       FROM usuarios
       WHERE id = ?
       LIMIT 1`,
      [userId],
    );

    return sendSuccess(res, {
      statusCode: 201,
      message: "Usuario creado correctamente",
      data: rows[0] ?? null,
    });
  } catch (error) {
    console.error("Error creando usuario:", error.message);

    if (error.code === "ER_DUP_ENTRY") {
      return sendError(res, {
        statusCode: 409,
        message: "Ya existe un usuario con ese email",
      });
    }

    return sendError(res, {
      statusCode: 500,
      message: "Error creando usuario",
      error: error.message,
    });
  }
};
