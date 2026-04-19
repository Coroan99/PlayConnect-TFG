import { AppError } from "../utils/app-error.js";
import {
  deleteOfertaIfPending,
  ensureOfertasTable,
  findAcceptedOfertaByPublicacionId,
  findOfertaById,
  findOfertaStateById,
  findOfertasByPublicacionId,
  findOfertasReceivedByUsuarioId,
  findOfertasSentByUsuarioId,
  findPublicacionReferenceById,
  findUsuarioReferenceById,
  generateOfertaId,
  insertOferta,
  lockPublicacionById,
  rejectPendingOfertasByPublicacionId,
  runOfertasTransaction,
  updateOfertaEstadoIfCurrent,
} from "../repositories/ofertas.repository.js";
import {
  validateCreateOfertaPayload,
  validateOfertaId,
  validatePublicacionParamId,
  validateUpdateOfertaEstadoPayload,
  validateUsuarioParamId,
} from "../validators/ofertas.validator.js";

const FOREIGN_KEY_ERROR_CODE = "ER_NO_REFERENCED_ROW_2";
const ACCEPTED_OFFER_CONFLICT_MESSAGE =
  "La publicación ya tiene una oferta aceptada";

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
  if (error?.code === FOREIGN_KEY_ERROR_CODE) {
    throw new AppError("El usuario o la publicación indicada no existe", 404);
  }

  throw error;
};

export const createOferta = async (payload) => {
  const normalizedOferta = validateCreateOfertaPayload(payload);

  await ensureOfertasTable();

  const ofertaId = await generateOfertaId();

  if (!ofertaId) {
    throw new AppError("No se pudo generar el identificador de la oferta", 500);
  }

  return runOfertasTransaction(async (connection) => {
    const usuario = await ensureUsuarioExists(normalizedOferta.usuario_id, connection);
    const publicacion = await ensurePublicacionExists(
      normalizedOferta.publicacion_id,
      connection,
    );

    if (publicacion.propietario.id === usuario.id) {
      throw new AppError("No puedes hacer una oferta sobre tu propia publicación", 403);
    }

    const lockedPublicacion = await lockPublicacionById(publicacion.id, connection);

    if (!lockedPublicacion) {
      throw new AppError("Publicación no encontrada", 404);
    }

    const acceptedOferta = await findAcceptedOfertaByPublicacionId(
      publicacion.id,
      connection,
    );

    if (acceptedOferta) {
      throw new AppError(ACCEPTED_OFFER_CONFLICT_MESSAGE, 409);
    }

    try {
      await insertOferta(
        {
          id: ofertaId,
          ...normalizedOferta,
          estado: "pendiente",
        },
        connection,
      );
    } catch (error) {
      mapPersistenceError(error);
    }

    return findOfertaById(ofertaId, connection);
  });
};

export const listOfertasByPublicacion = async (publicacionId) => {
  const normalizedPublicacionId = validatePublicacionParamId(publicacionId);

  await ensureOfertasTable();
  await ensurePublicacionExists(normalizedPublicacionId);

  return findOfertasByPublicacionId(normalizedPublicacionId);
};

export const listOfertasReceivedByUsuario = async (usuarioId) => {
  const normalizedUsuarioId = validateUsuarioParamId(usuarioId);

  await ensureOfertasTable();
  await ensureUsuarioExists(normalizedUsuarioId);

  return findOfertasReceivedByUsuarioId(normalizedUsuarioId);
};

export const listOfertasSentByUsuario = async (usuarioId) => {
  const normalizedUsuarioId = validateUsuarioParamId(usuarioId);

  await ensureOfertasTable();
  await ensureUsuarioExists(normalizedUsuarioId);

  return findOfertasSentByUsuarioId(normalizedUsuarioId);
};

export const updateOfertaStatus = async (id, payload) => {
  const normalizedId = validateOfertaId(id);
  const { estado } = validateUpdateOfertaEstadoPayload(payload);

  await ensureOfertasTable();

  return runOfertasTransaction(async (connection) => {
    const ofertaSnapshot = await findOfertaStateById(normalizedId, connection);

    if (!ofertaSnapshot) {
      throw new AppError("Oferta no encontrada", 404);
    }

    if (estado === "aceptada") {
      const lockedPublicacion = await lockPublicacionById(
        ofertaSnapshot.publicacion_id,
        connection,
      );

      if (!lockedPublicacion) {
        throw new AppError("Publicación no encontrada", 404);
      }
    }

    const existingOferta = await findOfertaStateById(
      normalizedId,
      connection,
      { forUpdate: true },
    );

    if (!existingOferta) {
      throw new AppError("Oferta no encontrada", 404);
    }

    if (existingOferta.estado !== "pendiente") {
      throw new AppError("Solo se puede actualizar una oferta pendiente", 409);
    }

    if (estado === "aceptada") {
      const acceptedOferta = await findAcceptedOfertaByPublicacionId(
        existingOferta.publicacion_id,
        connection,
        { excludeOfertaId: normalizedId },
      );

      if (acceptedOferta) {
        throw new AppError(ACCEPTED_OFFER_CONFLICT_MESSAGE, 409);
      }
    }

    const affectedRows = await updateOfertaEstadoIfCurrent(
      normalizedId,
      "pendiente",
      estado,
      connection,
    );

    if (affectedRows === 0) {
      throw new AppError("Solo se puede actualizar una oferta pendiente", 409);
    }

    if (estado === "aceptada") {
      await rejectPendingOfertasByPublicacionId(
        existingOferta.publicacion_id,
        normalizedId,
        connection,
      );
    }

    return findOfertaById(normalizedId, connection);
  });
};

export const deleteOfertaById = async (id) => {
  const normalizedId = validateOfertaId(id);

  await ensureOfertasTable();

  const existingOferta = await findOfertaStateById(normalizedId);

  if (!existingOferta) {
    throw new AppError("Oferta no encontrada", 404);
  }

  if (existingOferta.estado !== "pendiente") {
    throw new AppError("Solo se puede eliminar una oferta pendiente", 409);
  }

  const affectedRows = await deleteOfertaIfPending(normalizedId);

  if (affectedRows === 0) {
    throw new AppError("Solo se puede eliminar una oferta pendiente", 409);
  }

  return {
    id: normalizedId,
  };
};
