import jwt from "jsonwebtoken";
import { getJwtSecret } from "../config/auth.js";
import { AppError } from "../utils/app-error.js";

const AUTH_HEADER_PREFIX = "Bearer ";

const extractToken = (authorizationHeader) => {
  if (!authorizationHeader) {
    throw new AppError("Token de autenticación requerido", 401);
  }

  if (!authorizationHeader.startsWith(AUTH_HEADER_PREFIX)) {
    throw new AppError("Formato del token inválido", 401);
  }

  const token = authorizationHeader.slice(AUTH_HEADER_PREFIX.length).trim();

  if (!token) {
    throw new AppError("Token de autenticación requerido", 401);
  }

  return token;
};

export const authenticateToken = (req, res, next) => {
  try {
    const token = extractToken(req.headers.authorization);
    const payload = jwt.verify(token, getJwtSecret());

    req.usuario = {
      id: payload.sub,
      email: payload.email,
      tipo: payload.tipo,
    };

    return next();
  } catch (error) {
    if (error instanceof AppError) {
      return next(error);
    }

    if (error instanceof jwt.TokenExpiredError) {
      return next(new AppError("Token expirado", 401));
    }

    if (error instanceof jwt.JsonWebTokenError) {
      return next(new AppError("Token inválido", 401));
    }

    return next(error);
  }
};
