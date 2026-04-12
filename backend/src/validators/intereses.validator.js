import { AppError } from "../utils/app-error.js";

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

export const validateInteresId = (id) =>
  normalizeRequiredUuid(
    id,
    "El identificador del interés es obligatorio",
    "El identificador del interés no es válido",
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

export const validateCreateInteresPayload = (payload) => {
  if (!isPlainObject(payload)) {
    throw new AppError("El cuerpo de la petición debe ser un JSON válido", 400);
  }

  return {
    usuario_id: validateUsuarioId(payload.usuario_id),
    publicacion_id: validatePublicacionId(payload.publicacion_id),
  };
};
