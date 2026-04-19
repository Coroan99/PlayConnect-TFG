import {
  createOferta,
  deleteOfertaById,
  listOfertasByPublicacion,
  listOfertasReceivedByUsuario,
  listOfertasSentByUsuario,
  updateOfertaStatus,
} from "../services/ofertas.service.js";
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

export const postOferta = async (req, res) => {
  try {
    const oferta = await createOferta(req.body);

    return sendSuccess(res, {
      statusCode: 201,
      message: "Oferta creada correctamente",
      data: oferta,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error creando la oferta",
      "Error creando la oferta",
    );
  }
};

export const getOfertasByPublicacion = async (req, res) => {
  try {
    const ofertas = await listOfertasByPublicacion(req.params.id);

    return sendSuccess(res, {
      message: "Ofertas de la publicación obtenidas correctamente",
      data: ofertas,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error obteniendo las ofertas de la publicación",
      "Error obteniendo las ofertas de la publicación",
    );
  }
};

export const getOfertasRecibidasByUsuario = async (req, res) => {
  try {
    const ofertas = await listOfertasReceivedByUsuario(req.params.id);

    return sendSuccess(res, {
      message: "Ofertas recibidas obtenidas correctamente",
      data: ofertas,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error obteniendo las ofertas recibidas",
      "Error obteniendo las ofertas recibidas",
    );
  }
};

export const getOfertasEnviadasByUsuario = async (req, res) => {
  try {
    const ofertas = await listOfertasSentByUsuario(req.params.id);

    return sendSuccess(res, {
      message: "Ofertas enviadas obtenidas correctamente",
      data: ofertas,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error obteniendo las ofertas enviadas",
      "Error obteniendo las ofertas enviadas",
    );
  }
};

export const patchOferta = async (req, res) => {
  try {
    const oferta = await updateOfertaStatus(req.params.id, req.body);

    return sendSuccess(res, {
      message: "Estado de la oferta actualizado correctamente",
      data: oferta,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error actualizando el estado de la oferta",
      "Error actualizando el estado de la oferta",
    );
  }
};

export const removeOferta = async (req, res) => {
  try {
    const result = await deleteOfertaById(req.params.id);

    return sendSuccess(res, {
      message: "Oferta eliminada correctamente",
      data: result,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error eliminando la oferta",
      "Error eliminando la oferta",
    );
  }
};
