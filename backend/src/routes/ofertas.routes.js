import { Router } from "express";
import {
  getOfertasByPublicacion,
  getOfertasEnviadasByUsuario,
  getOfertasRecibidasByUsuario,
  patchOferta,
  postOferta,
  removeOferta,
} from "../controllers/ofertas.controller.js";

const router = Router();

router.post("/ofertas", postOferta);
router.get("/publicaciones/:id/ofertas", getOfertasByPublicacion);
router.get("/usuarios/:id/ofertas-recibidas", getOfertasRecibidasByUsuario);
router.get("/usuarios/:id/ofertas-enviadas", getOfertasEnviadasByUsuario);
router.patch("/ofertas/:id", patchOferta);
router.delete("/ofertas/:id", removeOferta);

export default router;
