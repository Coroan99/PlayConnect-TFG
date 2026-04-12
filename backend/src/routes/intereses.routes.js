import { Router } from "express";
import {
  getInteresesByPublicacion,
  getInteresesByUsuario,
  postInteres,
  removeInteres,
} from "../controllers/intereses.controller.js";

const router = Router();

router.post("/intereses", postInteres);
router.get("/publicaciones/:id/intereses", getInteresesByPublicacion);
router.get("/usuarios/:id/intereses", getInteresesByUsuario);
router.delete("/intereses/:id", removeInteres);

export default router;
