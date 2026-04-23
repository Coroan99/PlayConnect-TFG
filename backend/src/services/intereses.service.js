import { AppError } from "../utils/app-error.js";
import { ensureNotificacionesTable } from "../repositories/notificaciones.repository.js";
import {
  countInteresesByPublicacionId,
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
  runInteresesTransaction,
} from "../repositories/intereses.repository.js";
import {
  createNotificacion,
  createNotificacionIfNotExists,
} from "./notificaciones.service.js";
import {
  NOTIFICACION_TIPOS,
  REFERENCIA_TIPOS,
} from "../validators/notificaciones.validator.js";
import {
  validateCreateInteresPayload,
  validateInteresId,
  validatePublicacionParamId,
  validateUsuarioParamId,
} from "../validators/intereses.validator.js";

const DUPLICATE_ENTRY_ERROR_CODE = "ER_DUP_ENTRY";
const FOREIGN_KEY_ERROR_CODE = "ER_NO_REFERENCED_ROW_2";
const HIGH_INTEREST_THRESHOLD = 3;

const ensureUsuarioExists = async (usuarioId, executor) => {
  const usuario = await findUsuarioReferenceById(usuarioId, executor);

  if (!usuario) {
    throw new AppError("Usuario no encontrado", 404);
  }

  return usuario;
};

const ensurePublicacionExists = async (publicacionId, executor) => {
  const publicacion = await findPublicacionReferenceById(publicacionId, executor);

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

const createInteresNuevoNotification = async (
  { interesId, usuario, publicacion },
  executor,
) =>
  createNotificacion(
    {
      usuario_id: publicacion.propietario.id,
      emisor_id: usuario.id,
      tipo: NOTIFICACION_TIPOS.INTERES_NUEVO,
      mensaje: `${usuario.nombre} ha mostrado interés en tu publicación.`,
      referencia_id: interesId,
      referencia_tipo: REFERENCIA_TIPOS.INTERES,
      metadata: {
        publicacion_id: publicacion.id,
      },
    },
    executor,
  );

const createMuchoInteresNotification = async (
  { publicacion, totalIntereses },
  executor,
) =>
  createNotificacionIfNotExists(
    {
      usuario_id: publicacion.propietario.id,
      tipo: NOTIFICACION_TIPOS.MUCHO_INTERES,
      mensaje: `Tu publicación acumula ${totalIntereses} intereses. Podría ser buen momento para revisar la venta.`,
      referencia_id: publicacion.id,
      referencia_tipo: REFERENCIA_TIPOS.PUBLICACION,
      metadata: {
        publicacion_id: publicacion.id,
        total_intereses: totalIntereses,
        umbral: HIGH_INTEREST_THRESHOLD,
      },
    },
    executor,
  );

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
  await ensureNotificacionesTable();

  return runInteresesTransaction(async (connection) => {
    const [usuario, publicacion] = await Promise.all([
      ensureUsuarioExists(normalizedInteres.usuario_id, connection),
      ensurePublicacionExists(normalizedInteres.publicacion_id, connection),
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
      connection,
    );

    if (existingInteres) {
      throw new AppError(
        "El usuario ya ha mostrado interés por esta publicación",
        409,
      );
    }

    const interesId = await generateInteresId(connection);

    if (!interesId) {
      throw new AppError("No se pudo generar el identificador del interés", 500);
    }

    try {
      await insertInteres(
        {
          id: interesId,
          ...normalizedInteres,
        },
        connection,
      );
    } catch (error) {
      mapPersistenceError(error);
    }

    await createInteresNuevoNotification(
      {
        interesId,
        usuario,
        publicacion,
      },
      connection,
    );

    const totalIntereses = await countInteresesByPublicacionId(
      publicacion.id,
      connection,
    );

    if (totalIntereses >= HIGH_INTEREST_THRESHOLD) {
      await createMuchoInteresNotification(
        {
          publicacion,
          totalIntereses,
        },
        connection,
      );
    }

    return findInteresById(interesId, connection);
  });
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
