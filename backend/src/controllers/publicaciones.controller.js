import {
  createPublicacion,
  deletePublicacionById,
  getPublicacionDetail,
  listPublicaciones,
  updatePublicacionById,
} from "../services/publicaciones.service.js";
import { isAppError } from "../utils/app-error.js";
import { sendError, sendSuccess } from "../utils/response.js";

const handleControllerError = (res, error, defaultMessage, logLabel) => {
  if (isAppError(error)) {
    return sendError(res, {
      statusCode: error.statusCode,
      message: error.message,
    });
  }

  console.error(`${logLabel}:`, error.message);

  return sendError(res, {
    statusCode: 500,
    message: defaultMessage,
    error: error.message,
  });
};

export const getPublicaciones = async (req, res) => {
  try {
    const publicaciones = await listPublicaciones();

    return sendSuccess(res, {
      message: "Publicaciones obtenidas correctamente",
      data: publicaciones,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error obteniendo publicaciones",
      "Error obteniendo publicaciones",
    );
  }
};

export const getPublicacionById = async (req, res) => {
  try {
    const publicacion = await getPublicacionDetail(req.params.id);

    return sendSuccess(res, {
      message: "Publicación obtenida correctamente",
      data: publicacion,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error obteniendo la publicación",
      "Error obteniendo la publicación",
    );
  }
};

export const postPublicacion = async (req, res) => {
  try {
    const publicacion = await createPublicacion(req.body);

    return sendSuccess(res, {
      statusCode: 201,
      message: "Publicación creada correctamente",
      data: publicacion,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error creando la publicación",
      "Error creando la publicación",
    );
  }
};

export const removePublicacion = async (req, res) => {
  try {
    const result = await deletePublicacionById(req.params.id);

    return sendSuccess(res, {
      message: "Publicación eliminada correctamente",
      data: result,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error eliminando la publicación",
      "Error eliminando la publicación",
    );
  }
};

export const putPublicacion = async (req, res) => {
  try {
    const publicacion = await updatePublicacionById(req.params.id, req.body);

    return sendSuccess(res, {
      message: "Publicación actualizada correctamente",
      data: publicacion,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error actualizando la publicación",
      "Error actualizando la publicación",
    );
  }
};
