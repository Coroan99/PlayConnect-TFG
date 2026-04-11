import { Router } from "express";
import {
  getInventario,
  getInventarioById,
  getInventarioByUsuario,
  getInventarioEnVenta,
  postInventario,
  putInventario,
  removeInventario,
} from "../controllers/inventario.controller.js";

const router = Router();

router.get("/", getInventario);
router.get("/en-venta", getInventarioEnVenta);
router.get("/usuario/:usuarioId", getInventarioByUsuario);
router.get("/:id", getInventarioById);
router.post("/", postInventario);
router.put("/:id", putInventario);
router.delete("/:id", removeInventario);

export default router;
