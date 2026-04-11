import {
  createJuego,
  deleteJuegoById,
  getJuegoByBarcodeDetail,
  getJuegoDetail,
  listJuegos,
  updateJuegoById,
} from "../services/juegos.service.js";
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

export const getJuegos = async (req, res) => {
  try {
    const juegos = await listJuegos();

    return sendSuccess(res, {
      message: "Juegos obtenidos correctamente",
      data: juegos,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error obteniendo juegos",
      "Error obteniendo juegos",
    );
  }
};

export const getJuegoById = async (req, res) => {
  try {
    const juego = await getJuegoDetail(req.params.id);

    return sendSuccess(res, {
      message: "Juego obtenido correctamente",
      data: juego,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error obteniendo el juego",
      "Error obteniendo el juego",
    );
  }
};

export const getJuegoByBarcode = async (req, res) => {
  try {
    const juego = await getJuegoByBarcodeDetail(req.params.codigo);

    return sendSuccess(res, {
      message: "Juego obtenido correctamente",
      data: juego,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error obteniendo el juego",
      "Error obteniendo el juego por código de barras",
    );
  }
};

export const postJuego = async (req, res) => {
  try {
    const juego = await createJuego(req.body);

    return sendSuccess(res, {
      statusCode: 201,
      message: "Juego creado correctamente",
      data: juego,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error creando el juego",
      "Error creando el juego",
    );
  }
};

export const putJuego = async (req, res) => {
  try {
    const juego = await updateJuegoById(req.params.id, req.body);

    return sendSuccess(res, {
      message: "Juego actualizado correctamente",
      data: juego,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error actualizando el juego",
      "Error actualizando el juego",
    );
  }
};

export const removeJuego = async (req, res) => {
  try {
    const result = await deleteJuegoById(req.params.id);

    return sendSuccess(res, {
      message: "Juego eliminado correctamente",
      data: result,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error eliminando el juego",
      "Error eliminando el juego",
    );
  }
};
