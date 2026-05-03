import { Router } from "express";
import {
  getUsuarios,
  postUsuario,
  putUsuario,
} from "../controllers/usuarios.controller.js";

const router = Router();

router.get("/", getUsuarios);
router.post("/", postUsuario);
router.put("/:id", putUsuario);

export default router;
