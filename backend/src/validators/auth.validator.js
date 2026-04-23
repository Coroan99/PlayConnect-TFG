import { AppError } from "../utils/app-error.js";

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

export const validateLoginPayload = (payload) => {
  if (!isPlainObject(payload)) {
    throw new AppError("El cuerpo de la petición debe ser un JSON válido", 400);
  }

  const email = normalizeRequiredString(
    payload.email,
    "El email es obligatorio",
  ).toLowerCase();

  if (!EMAIL_REGEX.test(email)) {
    throw new AppError("El email no tiene un formato válido", 400);
  }

  return {
    email,
    password: normalizeRequiredString(
      payload.password,
      "La password es obligatoria",
    ),
  };
};
