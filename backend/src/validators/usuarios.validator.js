import { AppError } from "../utils/app-error.js";

const ALLOWED_USER_TYPES = new Set(["normal", "tienda"]);
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

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

export const validateUsuarioPayload = (payload) => {
  if (!isPlainObject(payload)) {
    throw new AppError("El cuerpo de la petición debe ser un JSON válido", 400);
  }

  return {
    nombre: normalizeRequiredString(payload.nombre, "El nombre es obligatorio"),
    email: normalizeEmail(payload.email),
    password: normalizePassword(payload.password),
    tipo: normalizeUserType(payload.tipo),
  };
};
