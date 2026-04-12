import {
  createInteres,
  deleteInteresById,
  listInteresesByPublicacion,
  listInteresesByUsuario,
} from "../services/intereses.service.js";
import { sendSuccess } from "../utils/response.js";

export const postInteres = async (req, res, next) => {
  try {
    const interes = await createInteres(req.body);

    return sendSuccess(res, {
      statusCode: 201,
      message: "Interés registrado correctamente",
      data: interes,
    });
  } catch (error) {
    return next(error);
  }
};

export const getInteresesByPublicacion = async (req, res, next) => {
  try {
    const intereses = await listInteresesByPublicacion(req.params.id);

    return sendSuccess(res, {
      message: "Intereses de la publicación obtenidos correctamente",
      data: intereses,
    });
  } catch (error) {
    return next(error);
  }
};

export const getInteresesByUsuario = async (req, res, next) => {
  try {
    const intereses = await listInteresesByUsuario(req.params.id);

    return sendSuccess(res, {
      message: "Intereses del usuario obtenidos correctamente",
      data: intereses,
    });
  } catch (error) {
    return next(error);
  }
};

export const removeInteres = async (req, res, next) => {
  try {
    const result = await deleteInteresById(req.params.id);

    return sendSuccess(res, {
      message: "Interés eliminado correctamente",
      data: result,
    });
  } catch (error) {
    return next(error);
  }
};
