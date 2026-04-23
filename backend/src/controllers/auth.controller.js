import { loginUsuario } from "../services/auth.service.js";
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

export const postLogin = async (req, res) => {
  try {
    const authSession = await loginUsuario(req.body);

    return sendSuccess(res, {
      message: "Login realizado correctamente",
      data: authSession,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error realizando login",
      "Error realizando login",
    );
  }
};
