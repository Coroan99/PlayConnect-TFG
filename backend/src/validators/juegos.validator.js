import { AppError } from "../utils/app-error.js";

const ALLOWED_GAME_TYPES = new Set(["videojuego", "juego_mesa"]);
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

const normalizeOptionalString = (value, fieldName) => {
  if (value === undefined || value === null) {
    return null;
  }

  if (typeof value !== "string") {
    throw new AppError(`El campo ${fieldName} debe ser una cadena de texto`, 400);
  }

  const normalizedValue = value.trim();
  return normalizedValue || null;
};

const normalizeOptionalUrl = (value, fieldName) => {
  const normalizedValue = normalizeOptionalString(value, fieldName);

  if (normalizedValue === null) {
    return null;
  }

  try {
    const parsedUrl = new URL(normalizedValue);

    if (
      parsedUrl.protocol !== "http:" &&
      parsedUrl.protocol !== "https:"
    ) {
      throw new Error("Invalid protocol");
    }

    return normalizedValue;
  } catch (_) {
    throw new AppError(
      `El campo ${fieldName} debe ser una URL válida`,
      400,
    );
  }
};

const normalizeBarcode = (value) => {
  if (value === undefined || value === null || value === "") {
    return null;
  }

  if (typeof value !== "string" && typeof value !== "number") {
    throw new AppError("El código de barras debe ser una cadena de texto válida", 400);
  }

  const normalizedValue = String(value).trim().replace(/\s+/g, "");
  return normalizedValue || null;
};

const normalizeNullableInteger = (value, fieldName, { min = 0 } = {}) => {
  if (value === undefined || value === null || value === "") {
    return null;
  }

  const parsedValue =
    typeof value === "string" && value.trim() !== "" ? Number(value) : value;

  if (!Number.isInteger(parsedValue)) {
    throw new AppError(`El campo ${fieldName} debe ser un número entero`, 400);
  }

  if (parsedValue < min) {
    throw new AppError(
      `El campo ${fieldName} no puede ser menor que ${min}`,
      400,
    );
  }

  return parsedValue;
};

export const validateJuegoId = (id) => {
  const normalizedId = typeof id === "string" ? id.trim() : "";

  if (!UUID_REGEX.test(normalizedId)) {
    throw new AppError("El identificador del juego no es válido", 400);
  }

  return normalizedId;
};

export const validateBarcodeParam = (codigo) => {
  const normalizedBarcode = normalizeBarcode(codigo);

  if (!normalizedBarcode) {
    throw new AppError("El código de barras es obligatorio", 400);
  }

  return normalizedBarcode;
};

export const validateJuegoPayload = (payload) => {
  if (!isPlainObject(payload)) {
    throw new AppError("El cuerpo de la petición debe ser un JSON válido", 400);
  }

  const nombre = normalizeRequiredString(
    payload.nombre,
    "El nombre es obligatorio",
  );
  const tipoJuego = normalizeRequiredString(
    payload.tipo_juego,
    "El tipo_juego es obligatorio",
  ).toLowerCase();

  if (!ALLOWED_GAME_TYPES.has(tipoJuego)) {
    throw new AppError(
      "El tipo_juego debe ser 'videojuego' o 'juego_mesa'",
      400,
    );
  }

  const jugadoresMin = normalizeNullableInteger(
    payload.jugadores_min,
    "jugadores_min",
    { min: 1 },
  );
  const jugadoresMax = normalizeNullableInteger(
    payload.jugadores_max,
    "jugadores_max",
    { min: 1 },
  );
  const duracionMinutos = normalizeNullableInteger(
    payload.duracion_minutos,
    "duracion_minutos",
    { min: 1 },
  );

  if (
    jugadoresMin !== null &&
    jugadoresMax !== null &&
    jugadoresMin > jugadoresMax
  ) {
    throw new AppError(
      "jugadores_min no puede ser mayor que jugadores_max",
      400,
    );
  }

  return {
    nombre,
    codigo_barras: normalizeBarcode(payload.codigo_barras),
    imagen_url: normalizeOptionalUrl(payload.imagen_url, "imagen_url"),
    tipo_juego: tipoJuego,
    plataforma: normalizeOptionalString(payload.plataforma, "plataforma"),
    jugadores_min: jugadoresMin,
    jugadores_max: jugadoresMax,
    duracion_minutos: duracionMinutos,
    descripcion: normalizeOptionalString(payload.descripcion, "descripcion"),
    manual_url: normalizeOptionalUrl(payload.manual_url, "manual_url"),
  };
};
