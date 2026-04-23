import {
  deleteNotificacionById,
  getUnreadCountByUsuario,
  listNotificacionesByUsuario,
  markAllNotificacionesAsRead,
  markNotificacionAsRead,
} from "../services/notificaciones.service.js";
import { sendSuccess } from "../utils/response.js";

export const getNotificacionesByUsuario = async (req, res, next) => {
  try {
    const notificaciones = await listNotificacionesByUsuario(
      req.params.usuarioId,
    );

    return sendSuccess(res, {
      message: "Notificaciones del usuario obtenidas correctamente",
      data: notificaciones,
    });
  } catch (error) {
    return next(error);
  }
};

export const getUnreadCount = async (req, res, next) => {
  try {
    const result = await getUnreadCountByUsuario(req.params.usuarioId);

    return sendSuccess(res, {
      message: "Contador de notificaciones no leídas obtenido correctamente",
      data: result,
    });
  } catch (error) {
    return next(error);
  }
};

export const patchNotificacionRead = async (req, res, next) => {
  try {
    const notificacion = await markNotificacionAsRead(req.params.id);

    return sendSuccess(res, {
      message: "Notificación marcada como leída correctamente",
      data: notificacion,
    });
  } catch (error) {
    return next(error);
  }
};

export const patchNotificacionesReadAll = async (req, res, next) => {
  try {
    const result = await markAllNotificacionesAsRead(req.params.usuarioId);

    return sendSuccess(res, {
      message: "Notificaciones marcadas como leídas correctamente",
      data: result,
    });
  } catch (error) {
    return next(error);
  }
};

export const removeNotificacion = async (req, res, next) => {
  try {
    const result = await deleteNotificacionById(req.params.id);

    return sendSuccess(res, {
      message: "Notificación eliminada correctamente",
      data: result,
    });
  } catch (error) {
    return next(error);
  }
};
