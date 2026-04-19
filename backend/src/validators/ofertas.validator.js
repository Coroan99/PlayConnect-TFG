import { AppError } from "../utils/app-error.js";

const ALLOWED_STATUS_UPDATE_STATES = new Set([
  "aceptada",
  "rechazada",
  "cancelada",
]);
const MAX_MENSAJE_LENGTH = 1000;
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

const normalizePrecioOfrecido = (value) => {
  if (value === undefined || value === null || value === "") {
    throw new AppError("El campo precio_ofrecido es obligatorio", 400);
  }

  if (typeof value !== "string" && typeof value !== "number") {
    throw new AppError("El campo precio_ofrecido debe ser un número válido", 400);
  }

  const rawValue = String(value).trim();

  if (!rawValue || !PRICE_REGEX.test(rawValue)) {
    throw new AppError(
      "El campo precio_ofrecido debe ser un número válido con hasta 2 decimales",
      400,
    );
  }

  const normalizedValue = Number(rawValue);

  if (!Number.isFinite(normalizedValue) || normalizedValue <= 0) {
    throw new AppError("El campo precio_ofrecido debe ser mayor que 0", 400);
  }

  return normalizedValue.toFixed(2);
};

const normalizeMensaje = (value) => {
  if (value === undefined || value === null) {
    return null;
  }

  if (typeof value !== "string") {
    throw new AppError("El campo mensaje debe ser una cadena de texto válida", 400);
  }

  const normalizedValue = value.trim();

  if (normalizedValue.length > MAX_MENSAJE_LENGTH) {
    throw new AppError("El campo mensaje no puede superar los 1000 caracteres", 400);
  }

  return normalizedValue ? normalizedValue : null;
};

const normalizeEstado = (value, allowedStates, message) => {
  if (typeof value !== "string") {
    throw new AppError("El estado es obligatorio", 400);
  }

  const normalizedValue = value.trim().toLowerCase();

  if (!normalizedValue) {
    throw new AppError("El estado es obligatorio", 400);
  }

  if (!allowedStates.has(normalizedValue)) {
    throw new AppError(message, 400);
  }

  return normalizedValue;
};

export const validateOfertaId = (id) =>
  normalizeRequiredUuid(
    id,
    "El identificador de la oferta es obligatorio",
    "El identificador de la oferta no es válido",
  );

export const validateUsuarioId = (usuarioId) =>
  normalizeRequiredUuid(
    usuarioId,
    "El campo usuario_id es obligatorio",
    "El campo usuario_id no es válido",
  );

export const validatePublicacionId = (publicacionId) =>
  normalizeRequiredUuid(
    publicacionId,
    "El campo publicacion_id es obligatorio",
    "El campo publicacion_id no es válido",
  );

export const validateUsuarioParamId = (usuarioId) =>
  normalizeRequiredUuid(
    usuarioId,
    "El identificador del usuario es obligatorio",
    "El identificador del usuario no es válido",
  );

export const validatePublicacionParamId = (publicacionId) =>
  normalizeRequiredUuid(
    publicacionId,
    "El identificador de la publicación es obligatorio",
    "El identificador de la publicación no es válido",
  );

export const validateCreateOfertaPayload = (payload) => {
  if (!isPlainObject(payload)) {
    throw new AppError("El cuerpo de la petición debe ser un JSON válido", 400);
  }

  return {
    usuario_id: validateUsuarioId(payload.usuario_id),
    publicacion_id: validatePublicacionId(payload.publicacion_id),
    precio_ofrecido: normalizePrecioOfrecido(payload.precio_ofrecido),
    mensaje: normalizeMensaje(payload.mensaje),
  };
};

export const validateUpdateOfertaEstadoPayload = (payload) => {
  if (!isPlainObject(payload)) {
    throw new AppError("El cuerpo de la petición debe ser un JSON válido", 400);
  }

  return {
    estado: normalizeEstado(
      payload.estado,
      ALLOWED_STATUS_UPDATE_STATES,
      "El estado solo puede actualizarse a 'aceptada', 'rechazada' o 'cancelada'",
    ),
  };
};
