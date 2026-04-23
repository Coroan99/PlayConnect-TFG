import { AppError } from "../utils/app-error.js";

export const NOTIFICACION_TIPOS = Object.freeze({
  OFERTA_RECIBIDA: "OFERTA_RECIBIDA",
  OFERTA_ACEPTADA: "OFERTA_ACEPTADA",
  OFERTA_RECHAZADA: "OFERTA_RECHAZADA",
  INTERES_NUEVO: "INTERES_NUEVO",
  MUCHO_INTERES: "MUCHO_INTERES",
});

export const REFERENCIA_TIPOS = Object.freeze({
  OFERTA: "OFERTA",
  INTERES: "INTERES",
  PUBLICACION: "PUBLICACION",
  INVENTARIO: "INVENTARIO",
  JUEGO: "JUEGO",
  SISTEMA: "SISTEMA",
});

const ALLOWED_NOTIFICATION_TYPES = new Set(Object.values(NOTIFICACION_TIPOS));
const ALLOWED_REFERENCE_TYPES = new Set(Object.values(REFERENCIA_TIPOS));
const MAX_MENSAJE_LENGTH = 500;
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

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

const normalizeOptionalUuid = (value, invalidMessage) => {
  if (value === undefined || value === null) {
    return null;
  }

  if (typeof value !== "string") {
    throw new AppError(invalidMessage, 400);
  }

  const normalizedValue = value.trim();

  if (!normalizedValue || !UUID_REGEX.test(normalizedValue)) {
    throw new AppError(invalidMessage, 400);
  }

  return normalizedValue;
};

const normalizeTipo = (value) => {
  if (typeof value !== "string") {
    throw new AppError("El tipo de notificación es obligatorio", 400);
  }

  const normalizedValue = value.trim().toUpperCase();

  if (!normalizedValue) {
    throw new AppError("El tipo de notificación es obligatorio", 400);
  }

  if (!ALLOWED_NOTIFICATION_TYPES.has(normalizedValue)) {
    throw new AppError("El tipo de notificación no es válido", 400);
  }

  return normalizedValue;
};

const normalizeReferenciaTipo = (value) => {
  if (value === undefined || value === null) {
    return null;
  }

  if (typeof value !== "string") {
    throw new AppError("El tipo de referencia no es válido", 400);
  }

  const normalizedValue = value.trim().toUpperCase();

  if (!normalizedValue || !ALLOWED_REFERENCE_TYPES.has(normalizedValue)) {
    throw new AppError("El tipo de referencia no es válido", 400);
  }

  return normalizedValue;
};

const normalizeMensaje = (value) => {
  if (typeof value !== "string") {
    throw new AppError("El mensaje de la notificación es obligatorio", 400);
  }

  const normalizedValue = value.trim();

  if (!normalizedValue) {
    throw new AppError("El mensaje de la notificación es obligatorio", 400);
  }

  if (normalizedValue.length > MAX_MENSAJE_LENGTH) {
    throw new AppError(
      "El mensaje de la notificación no puede superar los 500 caracteres",
      400,
    );
  }

  return normalizedValue;
};

const normalizeMetadata = (value) => {
  if (value === undefined || value === null) {
    return null;
  }

  if (!isPlainObject(value)) {
    throw new AppError("El campo metadata debe ser un objeto JSON válido", 400);
  }

  try {
    JSON.stringify(value);
  } catch (error) {
    throw new AppError("El campo metadata debe ser serializable a JSON", 400);
  }

  return value;
};

export const validateNotificacionId = (id) =>
  normalizeRequiredUuid(
    id,
    "El identificador de la notificación es obligatorio",
    "El identificador de la notificación no es válido",
  );

export const validateUsuarioId = (usuarioId) =>
  normalizeRequiredUuid(
    usuarioId,
    "El campo usuario_id es obligatorio",
    "El campo usuario_id no es válido",
  );

export const validateUsuarioParamId = (usuarioId) =>
  normalizeRequiredUuid(
    usuarioId,
    "El identificador del usuario es obligatorio",
    "El identificador del usuario no es válido",
  );

export const validateCreateNotificacionPayload = (payload) => {
  if (!isPlainObject(payload)) {
    throw new AppError("El cuerpo de la petición debe ser un JSON válido", 400);
  }

  const referenciaId = normalizeOptionalUuid(
    payload.referencia_id,
    "El campo referencia_id no es válido",
  );
  const referenciaTipo = normalizeReferenciaTipo(payload.referencia_tipo);

  if ((referenciaId && !referenciaTipo) || (!referenciaId && referenciaTipo)) {
    throw new AppError(
      "Los campos referencia_id y referencia_tipo deben enviarse juntos",
      400,
    );
  }

  return {
    usuario_id: validateUsuarioId(payload.usuario_id),
    tipo: normalizeTipo(payload.tipo),
    mensaje: normalizeMensaje(payload.mensaje),
    referencia_id: referenciaId,
    referencia_tipo: referenciaTipo,
    emisor_id: normalizeOptionalUuid(
      payload.emisor_id,
      "El campo emisor_id no es válido",
    ),
    metadata: normalizeMetadata(payload.metadata),
  };
};
