import { AppError } from "../utils/app-error.js";
import {
  validateBarcodeParam,
  validateJuegoId,
  validateJuegoPayload,
} from "../validators/juegos.validator.js";
import {
  deleteJuego,
  ensureJuegosTable,
  findAllJuegos,
  findJuegoByBarcode,
  findJuegoById,
  generateJuegoId,
  insertJuego,
  updateJuego,
} from "../repositories/juegos.repository.js";

const DUPLICATE_ENTRY_ERROR_CODE = "ER_DUP_ENTRY";

const mapDuplicateBarcodeError = (error) => {
  if (error?.code === DUPLICATE_ENTRY_ERROR_CODE) {
    throw new AppError("Ya existe un juego con ese código de barras", 409);
  }

  throw error;
};

export const listJuegos = async () => {
  await ensureJuegosTable();
  return findAllJuegos();
};

export const getJuegoDetail = async (id) => {
  const normalizedId = validateJuegoId(id);

  await ensureJuegosTable();

  const juego = await findJuegoById(normalizedId);

  if (!juego) {
    throw new AppError("Juego no encontrado", 404);
  }

  return juego;
};

export const getJuegoByBarcodeDetail = async (codigo) => {
  const normalizedBarcode = validateBarcodeParam(codigo);

  await ensureJuegosTable();

  const juego = await findJuegoByBarcode(normalizedBarcode);

  if (!juego) {
    throw new AppError("Juego no encontrado", 404);
  }

  return juego;
};

export const createJuego = async (payload) => {
  const normalizedJuego = validateJuegoPayload(payload);

  await ensureJuegosTable();

  const juegoId = await generateJuegoId();

  if (!juegoId) {
    throw new AppError("No se pudo generar el identificador del juego", 500);
  }

  try {
    await insertJuego({
      id: juegoId,
      ...normalizedJuego,
    });
  } catch (error) {
    mapDuplicateBarcodeError(error);
  }

  return getJuegoDetail(juegoId);
};

export const updateJuegoById = async (id, payload) => {
  const normalizedId = validateJuegoId(id);
  const normalizedJuego = validateJuegoPayload(payload);

  await ensureJuegosTable();

  const existingJuego = await findJuegoById(normalizedId);

  if (!existingJuego) {
    throw new AppError("Juego no encontrado", 404);
  }

  try {
    await updateJuego(normalizedId, normalizedJuego);
  } catch (error) {
    mapDuplicateBarcodeError(error);
  }

  return getJuegoDetail(normalizedId);
};

export const deleteJuegoById = async (id) => {
  const normalizedId = validateJuegoId(id);

  await ensureJuegosTable();

  const existingJuego = await findJuegoById(normalizedId);

  if (!existingJuego) {
    throw new AppError("Juego no encontrado", 404);
  }

  const affectedRows = await deleteJuego(normalizedId);

  if (affectedRows === 0) {
    throw new AppError("Juego no encontrado", 404);
  }

  return {
    id: normalizedId,
  };
};
