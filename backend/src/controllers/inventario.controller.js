import {
  createInventarioItem,
  deleteInventarioItem,
  getInventarioDetail,
  listInventario,
  listInventarioByUsuario,
  listInventarioItemsEnVenta,
  updateInventarioItem,
} from "../services/inventario.service.js";
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

export const getInventario = async (req, res) => {
  try {
    const inventario = await listInventario();

    return sendSuccess(res, {
      message: "Inventario obtenido correctamente",
      data: inventario,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error obteniendo inventario",
      "Error obteniendo inventario",
    );
  }
};

export const getInventarioById = async (req, res) => {
  try {
    const inventario = await getInventarioDetail(req.params.id);

    return sendSuccess(res, {
      message: "Registro de inventario obtenido correctamente",
      data: inventario,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error obteniendo el registro de inventario",
      "Error obteniendo el registro de inventario",
    );
  }
};

export const getInventarioByUsuario = async (req, res) => {
  try {
    const inventario = await listInventarioByUsuario(req.params.usuarioId);

    return sendSuccess(res, {
      message: "Inventario del usuario obtenido correctamente",
      data: inventario,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error obteniendo el inventario del usuario",
      "Error obteniendo el inventario del usuario",
    );
  }
};

export const getInventarioEnVenta = async (req, res) => {
  try {
    const inventario = await listInventarioItemsEnVenta();

    return sendSuccess(res, {
      message: "Juegos en venta obtenidos correctamente",
      data: inventario,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error obteniendo los juegos en venta",
      "Error obteniendo los juegos en venta",
    );
  }
};

export const postInventario = async (req, res) => {
  try {
    const inventario = await createInventarioItem(req.body);

    return sendSuccess(res, {
      statusCode: 201,
      message: "Registro de inventario creado correctamente",
      data: inventario,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error creando el registro de inventario",
      "Error creando el registro de inventario",
    );
  }
};

export const putInventario = async (req, res) => {
  try {
    const inventario = await updateInventarioItem(req.params.id, req.body);

    return sendSuccess(res, {
      message: "Registro de inventario actualizado correctamente",
      data: inventario,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error actualizando el registro de inventario",
      "Error actualizando el registro de inventario",
    );
  }
};

export const removeInventario = async (req, res) => {
  try {
    const result = await deleteInventarioItem(req.params.id);

    return sendSuccess(res, {
      message: "Registro de inventario eliminado correctamente",
      data: result,
    });
  } catch (error) {
    return handleControllerError(
      res,
      error,
      "Error eliminando el registro de inventario",
      "Error eliminando el registro de inventario",
    );
  }
};
