import { AppError } from "../utils/app-error.js";
import {
  validateInventarioId,
  validateInventarioPayload,
  validateUsuarioId,
} from "../validators/inventario.validator.js";
import {
  deleteInventario,
  findAllInventario,
  findInventarioById,
  findInventarioByUsuarioId,
  findInventarioEnVenta,
  findJuegoReferenceById,
  findUsuarioReferenceById,
  generateInventarioId,
  insertInventario,
  updateInventario,
} from "../repositories/inventario.repository.js";
import {
  ensurePublicacionesTable,
  generatePublicacionId,
  insertPublicacion,
} from "../repositories/publicaciones.repository.js";

const DUPLICATE_ENTRY_ERROR_CODE = "ER_DUP_ENTRY";
const FOREIGN_KEY_ERROR_CODE = "ER_NO_REFERENCED_ROW_2";
const PUBLIC_INVENTARIO_STATES = new Set(["visible", "en_venta"]);

const ensureUsuarioExists = async (usuarioId) => {
  const usuario = await findUsuarioReferenceById(usuarioId);

  if (!usuario) {
    throw new AppError("Usuario no encontrado", 404);
  }
};

const ensureJuegoExists = async (juegoId) => {
  const juego = await findJuegoReferenceById(juegoId);

  if (!juego) {
    throw new AppError("Juego no encontrado", 404);
  }
};

const mapPersistenceError = (error) => {
  if (error?.code === DUPLICATE_ENTRY_ERROR_CODE) {
    throw new AppError("Ese usuario ya tiene ese juego en su inventario", 409);
  }

  if (error?.code === FOREIGN_KEY_ERROR_CODE) {
    throw new AppError("El usuario o el juego indicado no existe", 404);
  }

  throw error;
};

const buildAutoPublicacionDescription = (inventario) => {
  const gameName = inventario.juego?.nombre?.trim() || "Juego";
  const platform = inventario.juego?.plataforma?.trim();
  const subject = platform ? `${gameName} para ${platform}` : gameName;

  if (inventario.estado === "en_venta") {
    const rawPrice = inventario.precio == null ? null : Number(inventario.precio);
    const priceLabel = Number.isFinite(rawPrice)
      ? ` por ${rawPrice.toFixed(2)} EUR`
      : "";

    return `${subject} en venta en PlayConnect${priceLabel}.`;
  }

  return `${subject} disponible para intercambio en PlayConnect.`;
};

const ensurePublicacionForInventario = async (inventario) => {
  if (
    !inventario ||
    inventario.publicacion ||
    !PUBLIC_INVENTARIO_STATES.has(inventario.estado)
  ) {
    return;
  }

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
      inventario_id: inventario.id,
      descripcion: buildAutoPublicacionDescription(inventario),
    });
  } catch (error) {
    if (error?.code === DUPLICATE_ENTRY_ERROR_CODE) {
      return;
    }

    throw error;
  }
};

export const listInventario = async () => {
  await ensurePublicacionesTable();
  return findAllInventario();
};

export const getInventarioDetail = async (id) => {
  const normalizedId = validateInventarioId(id);

  await ensurePublicacionesTable();

  const inventario = await findInventarioById(normalizedId);

  if (!inventario) {
    throw new AppError("Registro de inventario no encontrado", 404);
  }

  return inventario;
};

export const listInventarioByUsuario = async (usuarioId) => {
  const normalizedUsuarioId = validateUsuarioId(usuarioId);

  await ensurePublicacionesTable();
  await ensureUsuarioExists(normalizedUsuarioId);

  return findInventarioByUsuarioId(normalizedUsuarioId);
};

export const listInventarioItemsEnVenta = async () => {
  await ensurePublicacionesTable();
  return findInventarioEnVenta();
};

export const createInventarioItem = async (payload) => {
  const normalizedInventario = validateInventarioPayload(payload);

  await ensurePublicacionesTable();
  await ensureUsuarioExists(normalizedInventario.usuario_id);
  await ensureJuegoExists(normalizedInventario.juego_id);

  const inventarioId = await generateInventarioId();

  if (!inventarioId) {
    throw new AppError("No se pudo generar el identificador del inventario", 500);
  }

  try {
    await insertInventario({
      id: inventarioId,
      ...normalizedInventario,
    });
  } catch (error) {
    mapPersistenceError(error);
  }

  const createdInventario = await getInventarioDetail(inventarioId);
  await ensurePublicacionForInventario(createdInventario);

  return getInventarioDetail(inventarioId);
};

export const updateInventarioItem = async (id, payload) => {
  const normalizedId = validateInventarioId(id);
  const normalizedInventario = validateInventarioPayload(payload);

  await ensurePublicacionesTable();

  const existingInventario = await findInventarioById(normalizedId);

  if (!existingInventario) {
    throw new AppError("Registro de inventario no encontrado", 404);
  }

  await ensureUsuarioExists(normalizedInventario.usuario_id);
  await ensureJuegoExists(normalizedInventario.juego_id);

  try {
    await updateInventario(normalizedId, normalizedInventario);
  } catch (error) {
    mapPersistenceError(error);
  }

  const updatedInventario = await getInventarioDetail(normalizedId);
  await ensurePublicacionForInventario(updatedInventario);

  return getInventarioDetail(normalizedId);
};

export const deleteInventarioItem = async (id) => {
  const normalizedId = validateInventarioId(id);

  await ensurePublicacionesTable();

  const existingInventario = await findInventarioById(normalizedId);

  if (!existingInventario) {
    throw new AppError("Registro de inventario no encontrado", 404);
  }

  const affectedRows = await deleteInventario(normalizedId);

  if (affectedRows === 0) {
    throw new AppError("Registro de inventario no encontrado", 404);
  }

  return {
    id: normalizedId,
  };
};
