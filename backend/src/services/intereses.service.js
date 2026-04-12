import { AppError } from "../utils/app-error.js";
import {
  deleteInteres,
  ensureInteresesTable,
  findInteresById,
  findInteresByUsuarioAndPublicacion,
  findInteresesByPublicacionId,
  findInteresesByUsuarioId,
  findPublicacionReferenceById,
  findUsuarioReferenceById,
  generateInteresId,
  insertInteres,
} from "../repositories/intereses.repository.js";
import {
  validateCreateInteresPayload,
  validateInteresId,
  validatePublicacionParamId,
  validateUsuarioParamId,
} from "../validators/intereses.validator.js";

const DUPLICATE_ENTRY_ERROR_CODE = "ER_DUP_ENTRY";
const FOREIGN_KEY_ERROR_CODE = "ER_NO_REFERENCED_ROW_2";

const ensureUsuarioExists = async (usuarioId) => {
  const usuario = await findUsuarioReferenceById(usuarioId);

  if (!usuario) {
    throw new AppError("Usuario no encontrado", 404);
  }

  return usuario;
};

const ensurePublicacionExists = async (publicacionId) => {
  const publicacion = await findPublicacionReferenceById(publicacionId);

  if (!publicacion) {
    throw new AppError("Publicación no encontrada", 404);
  }

  return publicacion;
};

const mapPersistenceError = (error) => {
  if (error?.code === DUPLICATE_ENTRY_ERROR_CODE) {
    throw new AppError(
      "El usuario ya ha mostrado interés por esta publicación",
      409,
    );
  }

  if (error?.code === FOREIGN_KEY_ERROR_CODE) {
    throw new AppError("El usuario o la publicación indicada no existe", 404);
  }

  throw error;
};

export const listInteresesByPublicacion = async (publicacionId) => {
  const normalizedPublicacionId = validatePublicacionParamId(publicacionId);

  await ensureInteresesTable();
  await ensurePublicacionExists(normalizedPublicacionId);

  return findInteresesByPublicacionId(normalizedPublicacionId);
};

export const listInteresesByUsuario = async (usuarioId) => {
  const normalizedUsuarioId = validateUsuarioParamId(usuarioId);

  await ensureInteresesTable();
  await ensureUsuarioExists(normalizedUsuarioId);

  return findInteresesByUsuarioId(normalizedUsuarioId);
};

export const createInteres = async (payload) => {
  const normalizedInteres = validateCreateInteresPayload(payload);

  await ensureInteresesTable();

  const [usuario, publicacion] = await Promise.all([
    ensureUsuarioExists(normalizedInteres.usuario_id),
    ensurePublicacionExists(normalizedInteres.publicacion_id),
  ]);

  if (publicacion.propietario.id === usuario.id) {
    // El interés representa una señal entre usuarios distintos y se reutilizará
    // en notificaciones, ofertas y conversaciones; el auto-interés no aporta valor.
    throw new AppError(
      "No puedes mostrar interés por tu propia publicación",
      403,
    );
  }

  const existingInteres = await findInteresByUsuarioAndPublicacion(
    normalizedInteres.usuario_id,
    normalizedInteres.publicacion_id,
  );

  if (existingInteres) {
    throw new AppError(
      "El usuario ya ha mostrado interés por esta publicación",
      409,
    );
  }

  const interesId = await generateInteresId();

  if (!interesId) {
    throw new AppError("No se pudo generar el identificador del interés", 500);
  }

  try {
    await insertInteres({
      id: interesId,
      ...normalizedInteres,
    });
  } catch (error) {
    mapPersistenceError(error);
  }

  return findInteresById(interesId);
};

export const deleteInteresById = async (id) => {
  const normalizedId = validateInteresId(id);

  await ensureInteresesTable();

  const existingInteres = await findInteresById(normalizedId);

  if (!existingInteres) {
    throw new AppError("Interés no encontrado", 404);
  }

  const affectedRows = await deleteInteres(normalizedId);

  if (affectedRows === 0) {
    throw new AppError("Interés no encontrado", 404);
  }

  return {
    id: normalizedId,
  };
};
