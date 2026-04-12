import { AppError } from "../utils/app-error.js";
import { findInventarioById } from "../repositories/inventario.repository.js";
import {
  deletePublicacion,
  ensurePublicacionesTable,
  findAllPublicaciones,
  findPublicacionById,
  generatePublicacionId,
  insertPublicacion,
} from "../repositories/publicaciones.repository.js";
import {
  validatePublicacionId,
  validatePublicacionPayload,
} from "../validators/publicaciones.validator.js";

const DUPLICATE_ENTRY_ERROR_CODE = "ER_DUP_ENTRY";
const FOREIGN_KEY_ERROR_CODE = "ER_NO_REFERENCED_ROW_2";

const ensureInventarioExists = async (inventarioId) => {
  const inventario = await findInventarioById(inventarioId);

  if (!inventario) {
    throw new AppError("El inventario indicado no existe", 404);
  }
};

const mapPersistenceError = (error) => {
  if (error?.code === DUPLICATE_ENTRY_ERROR_CODE) {
    throw new AppError("Ya existe una publicación para ese inventario", 409);
  }

  if (error?.code === FOREIGN_KEY_ERROR_CODE) {
    throw new AppError("El inventario indicado no existe", 404);
  }

  throw error;
};

export const listPublicaciones = async () => {
  await ensurePublicacionesTable();
  return findAllPublicaciones();
};

export const getPublicacionDetail = async (id) => {
  const normalizedId = validatePublicacionId(id);

  await ensurePublicacionesTable();

  const publicacion = await findPublicacionById(normalizedId);

  if (!publicacion) {
    throw new AppError("Publicación no encontrada", 404);
  }

  return publicacion;
};

export const createPublicacion = async (payload) => {
  const normalizedPublicacion = validatePublicacionPayload(payload);

  await ensurePublicacionesTable();
  await ensureInventarioExists(normalizedPublicacion.inventario_id);

  const publicacionId = await generatePublicacionId();

  if (!publicacionId) {
    throw new AppError(
      "No se pudo generar el identificador de la publicación",
      500,
    );
  }

  try {
    await insertPublicacion({
      id: publicacionId,
      ...normalizedPublicacion,
    });
  } catch (error) {
    mapPersistenceError(error);
  }

  return getPublicacionDetail(publicacionId);
};

export const deletePublicacionById = async (id) => {
  const normalizedId = validatePublicacionId(id);

  await ensurePublicacionesTable();

  const existingPublicacion = await findPublicacionById(normalizedId);

  if (!existingPublicacion) {
    throw new AppError("Publicación no encontrada", 404);
  }

  const affectedRows = await deletePublicacion(normalizedId);

  if (affectedRows === 0) {
    throw new AppError("Publicación no encontrada", 404);
  }

  return {
    id: normalizedId,
  };
};
