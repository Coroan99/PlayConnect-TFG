import { Router } from "express";
import { getUsuarios, postUsuario } from "../controllers/usuarios.controller.js";

const router = Router();

router.get("/", getUsuarios);
router.post("/", postUsuario);

export default router;
