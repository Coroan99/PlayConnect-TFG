import { AppError } from "../utils/app-error.js";

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const MAX_DESCRIPCION_LENGTH = 1000;

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

const normalizeDescription = (value) => {
  if (typeof value !== "string") {
    throw new AppError("La descripción es obligatoria", 400);
  }

  const normalizedValue = value.trim();

  if (!normalizedValue) {
    throw new AppError("La descripción es obligatoria", 400);
  }

  if (normalizedValue.length > MAX_DESCRIPCION_LENGTH) {
    throw new AppError(
      "La descripción no puede superar los 1000 caracteres",
      400,
    );
  }

  return normalizedValue;
};

export const validatePublicacionId = (id) =>
  normalizeRequiredUuid(
    id,
    "El identificador de la publicación es obligatorio",
    "El identificador de la publicación no es válido",
  );

export const validateInventarioId = (inventarioId) =>
  normalizeRequiredUuid(
    inventarioId,
    "El inventario_id es obligatorio",
    "El inventario_id no es válido",
  );

export const validatePublicacionPayload = (payload) => {
  if (!isPlainObject(payload)) {
    throw new AppError("El cuerpo de la petición debe ser un JSON válido", 400);
  }

  return {
    inventario_id: validateInventarioId(payload.inventario_id),
    descripcion: normalizeDescription(payload.descripcion),
  };
};
