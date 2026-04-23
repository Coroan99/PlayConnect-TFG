import { AppError } from "../utils/app-error.js";

const DEFAULT_JWT_EXPIRES_IN = "7d";

export const getJwtSecret = () => {
  const secret = process.env.JWT_SECRET?.trim();

  if (!secret) {
    throw new AppError("JWT_SECRET no está configurado", 500);
  }

  return secret;
};

export const getJwtExpiresIn = () =>
  process.env.JWT_EXPIRES_IN?.trim() || DEFAULT_JWT_EXPIRES_IN;
