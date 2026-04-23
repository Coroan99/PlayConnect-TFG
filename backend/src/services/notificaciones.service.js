import { AppError } from "../utils/app-error.js";
import {
  countUnreadNotificacionesByUsuarioId,
  deleteNotificacion,
  ensureNotificacionesTable,
  findNotificacionById,
  findNotificacionByUserTypeAndReference,
  findNotificacionesByUsuarioId,
  findUsuarioReferenceById,
  generateNotificacionId,
  insertNotificacion,
  markAllNotificacionesAsReadByUsuarioId,
  markNotificacionAsReadById,
} from "../repositories/notificaciones.repository.js";
import {
  validateCreateNotificacionPayload,
  validateNotificacionId,
  validateUsuarioParamId,
} from "../validators/notificaciones.validator.js";

const DUPLICATE_ENTRY_ERROR_CODE = "ER_DUP_ENTRY";
const FOREIGN_KEY_ERROR_CODE = "ER_NO_REFERENCED_ROW_2";

const ensureUsuarioExists = async (usuarioId, executor) => {
  const usuario = await findUsuarioReferenceById(usuarioId, executor);

  if (!usuario) {
    throw new AppError("Usuario no encontrado", 404);
  }

  return usuario;
};

const mapPersistenceError = (error) => {
  if (error?.code === DUPLICATE_ENTRY_ERROR_CODE) {
    throw new AppError("La notificación ya existe para esa referencia", 409);
  }

  if (error?.code === FOREIGN_KEY_ERROR_CODE) {
    throw new AppError("El usuario indicado no existe", 404);
  }

  throw error;
};

const persistNotificacion = async (notificacion, executor) => {
  await ensureUsuarioExists(notificacion.usuario_id, executor);

  if (notificacion.emisor_id) {
    await ensureUsuarioExists(notificacion.emisor_id, executor);
  }

  const notificacionId = await generateNotificacionId(executor);

  if (!notificacionId) {
    throw new AppError(
      "No se pudo generar el identificador de la notificación",
      500,
    );
  }

  await insertNotificacion(
    {
      id: notificacionId,
      ...notificacion,
    },
    executor,
  );

  return findNotificacionById(notificacionId, executor);
};

export const createNotificacion = async (payload, executor) => {
  const normalizedNotificacion = validateCreateNotificacionPayload(payload);

  await ensureNotificacionesTable();

  try {
    return await persistNotificacion(normalizedNotificacion, executor);
  } catch (error) {
    mapPersistenceError(error);
  }
};

export const createNotificacionIfNotExists = async (payload, executor) => {
  const normalizedNotificacion = validateCreateNotificacionPayload(payload);

  if (
    !normalizedNotificacion.referencia_id ||
    !normalizedNotificacion.referencia_tipo
  ) {
    throw new AppError(
      "La creación idempotente requiere referencia_id y referencia_tipo",
      400,
    );
  }

  await ensureNotificacionesTable();

  const existingNotificacion = await findNotificacionByUserTypeAndReference(
    normalizedNotificacion.usuario_id,
    normalizedNotificacion.tipo,
    normalizedNotificacion.referencia_tipo,
    normalizedNotificacion.referencia_id,
    executor,
  );

  if (existingNotificacion) {
    return existingNotificacion;
  }

  try {
    return await persistNotificacion(normalizedNotificacion, executor);
  } catch (error) {
    if (error?.code === DUPLICATE_ENTRY_ERROR_CODE) {
      const duplicatedNotificacion = await findNotificacionByUserTypeAndReference(
        normalizedNotificacion.usuario_id,
        normalizedNotificacion.tipo,
        normalizedNotificacion.referencia_tipo,
        normalizedNotificacion.referencia_id,
        executor,
      );

      if (duplicatedNotificacion) {
        return duplicatedNotificacion;
      }
    }

    mapPersistenceError(error);
  }
};

export const listNotificacionesByUsuario = async (usuarioId) => {
  const normalizedUsuarioId = validateUsuarioParamId(usuarioId);

  await ensureNotificacionesTable();
  await ensureUsuarioExists(normalizedUsuarioId);

  return findNotificacionesByUsuarioId(normalizedUsuarioId);
};

export const getUnreadCountByUsuario = async (usuarioId) => {
  const normalizedUsuarioId = validateUsuarioParamId(usuarioId);

  await ensureNotificacionesTable();
  await ensureUsuarioExists(normalizedUsuarioId);

  const unreadCount = await countUnreadNotificacionesByUsuarioId(
    normalizedUsuarioId,
  );

  return {
    usuario_id: normalizedUsuarioId,
    unread_count: unreadCount,
  };
};

export const markNotificacionAsRead = async (id) => {
  const normalizedId = validateNotificacionId(id);

  await ensureNotificacionesTable();

  const existingNotificacion = await findNotificacionById(normalizedId);

  if (!existingNotificacion) {
    throw new AppError("Notificación no encontrada", 404);
  }

  if (!existingNotificacion.leida) {
    await markNotificacionAsReadById(normalizedId);
  }

  return findNotificacionById(normalizedId);
};

export const markAllNotificacionesAsRead = async (usuarioId) => {
  const normalizedUsuarioId = validateUsuarioParamId(usuarioId);

  await ensureNotificacionesTable();
  await ensureUsuarioExists(normalizedUsuarioId);

  const updatedCount = await markAllNotificacionesAsReadByUsuarioId(
    normalizedUsuarioId,
  );

  return {
    usuario_id: normalizedUsuarioId,
    updated_count: updatedCount,
  };
};

export const deleteNotificacionById = async (id) => {
  const normalizedId = validateNotificacionId(id);

  await ensureNotificacionesTable();

  const existingNotificacion = await findNotificacionById(normalizedId);

  if (!existingNotificacion) {
    throw new AppError("Notificación no encontrada", 404);
  }

  const affectedRows = await deleteNotificacion(normalizedId);

  if (affectedRows === 0) {
    throw new AppError("Notificación no encontrada", 404);
  }

  return {
    id: normalizedId,
  };
};
