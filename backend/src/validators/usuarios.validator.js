import { AppError } from "../utils/app-error.js";
import { findSpanishCity } from "../constants/spanish-cities.js";

const ALLOWED_USER_TYPES = new Set(["normal", "tienda"]);
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const isPlainObject = (value) =>
  value !== null && typeof value === "object" && !Array.isArray(value);

const normalizeRequiredString = (value, requiredMessage) => {
  if (typeof value !== "string") {
    throw new AppError(requiredMessage, 400);
  }

  const normalizedValue = value.trim();

  if (!normalizedValue) {
    throw new AppError(requiredMessage, 400);
  }

  return normalizedValue;
};

const normalizeEmail = (value) => {
  const normalizedEmail = normalizeRequiredString(
    value,
    "El email es obligatorio",
  ).toLowerCase();

  if (!EMAIL_REGEX.test(normalizedEmail)) {
    throw new AppError("El email no tiene un formato válido", 400);
  }

  return normalizedEmail;
};

const normalizePassword = (value) => {
  const password = normalizeRequiredString(
    value,
    "La password es obligatoria",
  );

  if (password.length < 6) {
    throw new AppError("La password debe tener al menos 6 caracteres", 400);
  }

  return password;
};

const normalizeUserType = (value) => {
  const tipo = normalizeRequiredString(
    value,
    "El tipo es obligatorio",
  ).toLowerCase();

  if (!ALLOWED_USER_TYPES.has(tipo)) {
    throw new AppError("El tipo debe ser 'normal' o 'tienda'", 400);
  }

  return tipo;
};

const normalizeOptionalCity = (value) => {
  if (value == null) {
    return null;
  }

  if (typeof value !== "string") {
    throw new AppError("La ciudad debe ser una ciudad española válida", 400);
  }

  const normalizedValue = value.trim();

  if (!normalizedValue) {
    return null;
  }

  const city = findSpanishCity(normalizedValue);

  if (city == null) {
    throw new AppError("La ciudad debe ser una ciudad española válida", 400);
  }

  return city;
};

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

export const validateUsuarioId = (id) =>
  normalizeRequiredUuid(
    id,
    "El identificador del usuario es obligatorio",
    "El identificador del usuario no es válido",
  );

export const validateUsuarioPayload = (payload) => {
  if (!isPlainObject(payload)) {
    throw new AppError("El cuerpo de la petición debe ser un JSON válido", 400);
  }

  return {
    nombre: normalizeRequiredString(payload.nombre, "El nombre es obligatorio"),
    email: normalizeEmail(payload.email),
    password: normalizePassword(payload.password),
    tipo: normalizeUserType(payload.tipo),
    ciudad: normalizeOptionalCity(payload.ciudad),
  };
};

export const validateUsuarioCityPayload = (payload) => {
  if (!isPlainObject(payload)) {
    throw new AppError("El cuerpo de la petición debe ser un JSON válido", 400);
  }

  return {
    ciudad: normalizeOptionalCity(payload.ciudad),
  };
};
