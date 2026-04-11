import { AppError } from "../utils/app-error.js";

const ALLOWED_INVENTARIO_STATES = new Set(["coleccion", "visible", "en_venta"]);
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const PRICE_REGEX = /^\d+(\.\d{1,2})?$/;

const isPlainObject = (value) =>
  value !== null && typeof value === "object" && !Array.isArray(value);

const normalizeRequiredUuid = (value, requiredMessage, invalidMessage) => {
  if (typeof value !== "string") {
    throw new AppError(requiredMessage, 400);
  }

  const normalizedValue = value.trim();

  if (!normalizedValue) {
    throw new AppError(requiredMessage, 400);
  }

  if (!UUID_REGEX.test(normalizedValue)) {
    throw new AppError(invalidMessage, 400);
  }

  return normalizedValue;
};

const normalizeRequiredState = (value) => {
  if (typeof value !== "string") {
    throw new AppError("El estado es obligatorio", 400);
  }

  const normalizedValue = value.trim().toLowerCase();

  if (!normalizedValue) {
    throw new AppError("El estado es obligatorio", 400);
  }

  if (!ALLOWED_INVENTARIO_STATES.has(normalizedValue)) {
    throw new AppError(
      "El estado debe ser 'coleccion', 'visible' o 'en_venta'",
      400,
    );
  }

  return normalizedValue;
};

const normalizePrice = (value, estado) => {
  if (estado !== "en_venta") {
    return null;
  }

  if (value === undefined || value === null || value === "") {
    throw new AppError(
      "El precio es obligatorio cuando el estado es 'en_venta'",
      400,
    );
  }

  if (typeof value !== "string" && typeof value !== "number") {
    throw new AppError("El precio debe ser un número válido", 400);
  }

  const rawValue = String(value).trim();

  if (!rawValue || !PRICE_REGEX.test(rawValue)) {
    throw new AppError("El precio debe ser un número válido con hasta 2 decimales", 400);
  }

  const normalizedValue = Number(rawValue);

  if (!Number.isFinite(normalizedValue) || normalizedValue <= 0) {
    throw new AppError("El precio debe ser mayor que 0", 400);
  }

  return normalizedValue.toFixed(2);
};

export const validateInventarioId = (id) =>
  normalizeRequiredUuid(
    id,
    "El identificador del inventario es obligatorio",
    "El identificador del inventario no es válido",
  );

export const validateUsuarioId = (usuarioId) =>
  normalizeRequiredUuid(
    usuarioId,
    "El usuario_id es obligatorio",
    "El usuario_id no es válido",
  );

export const validateJuegoId = (juegoId) =>
  normalizeRequiredUuid(
    juegoId,
    "El juego_id es obligatorio",
    "El juego_id no es válido",
  );

export const validateInventarioPayload = (payload) => {
  if (!isPlainObject(payload)) {
    throw new AppError("El cuerpo de la petición debe ser un JSON válido", 400);
  }

  const usuarioId = validateUsuarioId(payload.usuario_id);
  const juegoId = validateJuegoId(payload.juego_id);
  const estado = normalizeRequiredState(payload.estado);

  return {
    usuario_id: usuarioId,
    juego_id: juegoId,
    estado,
    precio: normalizePrice(payload.precio, estado),
  };
};
