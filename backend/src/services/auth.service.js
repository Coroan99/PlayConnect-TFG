import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { getJwtExpiresIn, getJwtSecret } from "../config/auth.js";
import { AppError } from "../utils/app-error.js";
import { validateLoginPayload } from "../validators/auth.validator.js";
import {
  ensureUsuariosTable,
  findUsuarioWithPasswordByEmail,
  updateUsuarioPassword,
} from "../repositories/usuarios.repository.js";

const PASSWORD_SALT_ROUNDS = 12;
const BCRYPT_HASH_REGEX = /^\$2[aby]\$\d{2}\$/;

const sanitizeUsuario = (usuario) => {
  const { password, ...safeUsuario } = usuario;
  return safeUsuario;
};

const isBcryptHash = (password) =>
  typeof password === "string" && BCRYPT_HASH_REGEX.test(password);

const verifyPassword = async (plainPassword, usuario) => {
  if (!usuario?.password) {
    return false;
  }

  if (isBcryptHash(usuario.password)) {
    return bcrypt.compare(plainPassword, usuario.password);
  }

  const matchesLegacyPassword = plainPassword === usuario.password;

  if (matchesLegacyPassword) {
    const hashedPassword = await bcrypt.hash(
      plainPassword,
      PASSWORD_SALT_ROUNDS,
    );
    await updateUsuarioPassword(usuario.id, hashedPassword);
  }

  return matchesLegacyPassword;
};

const createAccessToken = (usuario) => {
  const payload = {
    sub: usuario.id,
    email: usuario.email,
    tipo: usuario.tipo,
  };

  return jwt.sign(payload, getJwtSecret(), {
    expiresIn: getJwtExpiresIn(),
  });
};

export const loginUsuario = async (payload) => {
  const credentials = validateLoginPayload(payload);

  await ensureUsuariosTable();

  const usuario = await findUsuarioWithPasswordByEmail(credentials.email);

  if (!usuario) {
    throw new AppError("Credenciales inválidas", 401);
  }

  const validPassword = await verifyPassword(credentials.password, usuario);

  if (!validPassword) {
    throw new AppError("Credenciales inválidas", 401);
  }

  const safeUsuario = sanitizeUsuario(usuario);

  return {
    token: createAccessToken(safeUsuario),
    usuario: safeUsuario,
  };
};
