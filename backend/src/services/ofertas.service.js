import { AppError } from "../utils/app-error.js";
import { ensureNotificacionesTable } from "../repositories/notificaciones.repository.js";
import {
  deleteOfertaIfPending,
  ensureOfertasTable,
  findAcceptedOfertaByPublicacionId,
  findOfertaById,
  findOfertaStateById,
  findOfertasByPublicacionId,
  findOfertasReceivedByUsuarioId,
  findOfertasSentByUsuarioId,
  findPendingOfertaStatesByPublicacionId,
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
  createNotificacion,
  createNotificacionIfNotExists,
} from "./notificaciones.service.js";
import {
  NOTIFICACION_TIPOS,
  REFERENCIA_TIPOS,
} from "../validators/notificaciones.validator.js";
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

const formatPrice = (price) => `${Number(price).toFixed(2)} €`;

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

const createOfertaRecibidaNotification = async (
  { ofertaId, oferta, ofertante, publicacion },
  executor,
) =>
  createNotificacion(
    {
      usuario_id: publicacion.propietario.id,
      emisor_id: ofertante.id,
      tipo: NOTIFICACION_TIPOS.OFERTA_RECIBIDA,
      mensaje: `${ofertante.nombre} ha enviado una oferta de ${formatPrice(
        oferta.precio_ofrecido,
      )} por tu publicación.`,
      referencia_id: ofertaId,
      referencia_tipo: REFERENCIA_TIPOS.OFERTA,
      metadata: {
        publicacion_id: publicacion.id,
        precio_ofrecido: oferta.precio_ofrecido,
      },
    },
    executor,
  );

const createOfertaResultadoNotification = async (
  oferta,
  estado,
  executor,
  metadata = {},
) => {
  const isAccepted = estado === "aceptada";

  return createNotificacionIfNotExists(
    {
      usuario_id: oferta.usuario.id,
      emisor_id: oferta.publicacion.propietario.id,
      tipo: isAccepted
        ? NOTIFICACION_TIPOS.OFERTA_ACEPTADA
        : NOTIFICACION_TIPOS.OFERTA_RECHAZADA,
      mensaje: `Tu oferta de ${formatPrice(oferta.precio_ofrecido)} por "${
        oferta.publicacion.juego.nombre
      }" ha sido ${isAccepted ? "aceptada" : "rechazada"}.`,
      referencia_id: oferta.id,
      referencia_tipo: REFERENCIA_TIPOS.OFERTA,
      metadata: {
        publicacion_id: oferta.publicacion.id,
        estado,
        ...metadata,
      },
    },
    executor,
  );
};

const createOfertaAutoRechazadaNotification = async (
  oferta,
  rejectedOferta,
  executor,
) =>
  createNotificacionIfNotExists(
    {
      usuario_id: rejectedOferta.usuario_id,
      emisor_id: oferta.publicacion.propietario.id,
      tipo: NOTIFICACION_TIPOS.OFERTA_RECHAZADA,
      mensaje: `Tu oferta por "${oferta.publicacion.juego.nombre}" ha sido rechazada porque otra oferta fue aceptada.`,
      referencia_id: rejectedOferta.id,
      referencia_tipo: REFERENCIA_TIPOS.OFERTA,
      metadata: {
        publicacion_id: oferta.publicacion.id,
        estado: "rechazada",
        motivo: "otra_oferta_aceptada",
      },
    },
    executor,
  );

export const createOferta = async (payload) => {
  const normalizedOferta = validateCreateOfertaPayload(payload);

  await ensureOfertasTable();
  await ensureNotificacionesTable();

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

    await createOfertaRecibidaNotification(
      {
        ofertaId,
        oferta: normalizedOferta,
        ofertante: usuario,
        publicacion,
      },
      connection,
    );

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
  await ensureNotificacionesTable();

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

    let pendingOfertasToReject = [];

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

      pendingOfertasToReject = await findPendingOfertaStatesByPublicacionId(
        existingOferta.publicacion_id,
        normalizedId,
        connection,
        { forUpdate: true },
      );
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

    const updatedOferta = await findOfertaById(normalizedId, connection);

    if (estado === "aceptada" || estado === "rechazada") {
      await createOfertaResultadoNotification(updatedOferta, estado, connection);
    }

    if (estado === "aceptada") {
      for (const rejectedOferta of pendingOfertasToReject) {
        await createOfertaAutoRechazadaNotification(
          updatedOferta,
          rejectedOferta,
          connection,
        );
      }
    }

    return updatedOferta;
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
