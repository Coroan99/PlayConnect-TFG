import { Router } from "express";
import {
  getJuegoByBarcode,
  getJuegoById,
  getJuegos,
  postJuego,
  putJuego,
  removeJuego,
} from "../controllers/juegos.controller.js";

const router = Router();

router.get("/", getJuegos);
router.get("/barcode/:codigo", getJuegoByBarcode);
router.get("/:id", getJuegoById);
router.post("/", postJuego);
router.put("/:id", putJuego);
router.delete("/:id", removeJuego);

export default router;
