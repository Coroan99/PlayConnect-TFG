import { Router } from "express";
import {
  getNotificacionesByUsuario,
  getUnreadCount,
  patchNotificacionRead,
  patchNotificacionesReadAll,
  removeNotificacion,
} from "../controllers/notificaciones.controller.js";

const router = Router();

router.get("/usuarios/:usuarioId/notificaciones/unread-count", getUnreadCount);
router.get("/usuarios/:usuarioId/notificaciones", getNotificacionesByUsuario);
router.patch("/notificaciones/:id/read", patchNotificacionRead);
router.patch(
  "/usuarios/:usuarioId/notificaciones/read-all",
  patchNotificacionesReadAll,
);
router.delete("/notificaciones/:id", removeNotificacion);

export default router;
