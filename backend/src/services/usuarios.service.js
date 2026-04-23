import bcrypt from "bcryptjs";
import { AppError } from "../utils/app-error.js";
import { validateUsuarioPayload } from "../validators/usuarios.validator.js";
import {
  ensureUsuariosTable,
  findAllUsuarios,
  findUsuarioById,
  generateUsuarioId,
  insertUsuario,
} from "../repositories/usuarios.repository.js";

const DUPLICATE_ENTRY_ERROR_CODE = "ER_DUP_ENTRY";
const PASSWORD_SALT_ROUNDS = 12;

const mapDuplicateEmailError = (error) => {
  if (error?.code === DUPLICATE_ENTRY_ERROR_CODE) {
    throw new AppError("Ya existe un usuario con ese email", 409);
  }

  throw error;
};

export const listUsuarios = async () => {
  await ensureUsuariosTable();
  return findAllUsuarios();
};

export const getUsuarioDetail = async (id) => {
  await ensureUsuariosTable();

  const usuario = await findUsuarioById(id);

  if (!usuario) {
    throw new AppError("Usuario no encontrado", 404);
  }

  return usuario;
};

export const createUsuario = async (payload) => {
  const normalizedUsuario = validateUsuarioPayload(payload);

  await ensureUsuariosTable();

  const usuarioId = await generateUsuarioId();

  if (!usuarioId) {
    throw new AppError("No se pudo generar el identificador del usuario", 500);
  }

  const hashedPassword = await bcrypt.hash(
    normalizedUsuario.password,
    PASSWORD_SALT_ROUNDS,
  );

  try {
    await insertUsuario({
      id: usuarioId,
      nombre: normalizedUsuario.nombre,
      email: normalizedUsuario.email,
      password: hashedPassword,
      tipo: normalizedUsuario.tipo,
    });
  } catch (error) {
    mapDuplicateEmailError(error);
  }

  return getUsuarioDetail(usuarioId);
};
