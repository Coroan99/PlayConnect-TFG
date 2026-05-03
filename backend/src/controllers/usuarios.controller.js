import {
  createUsuario,
  listUsuarios,
  updateUsuarioCityById,
} from "../services/usuarios.service.js";
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

export const getUsuarios = async (req, res) => {
  try {
    const usuarios = await listUsuarios();

    return sendSuccess(res, {
      message: "Usuarios obtenidos correctamente",
      data: usuarios,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error obteniendo usuarios",
      "Error obteniendo usuarios",
    );
  }
};

export const postUsuario = async (req, res) => {
  try {
    const usuario = await createUsuario(req.body);

    return sendSuccess(res, {
      statusCode: 201,
      message: "Usuario creado correctamente",
      data: usuario,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error creando usuario",
      "Error creando usuario",
    );
  }
};

export const putUsuario = async (req, res) => {
  try {
    const usuario = await updateUsuarioCityById(req.params.id, req.body);

    return sendSuccess(res, {
      message: "Usuario actualizado correctamente",
      data: usuario,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error actualizando usuario",
      "Error actualizando usuario",
    );
  }
};
