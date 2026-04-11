import { Router } from "express";
import { createUsuario, getUsuarios } from "../controllers/usuarios.controller.js";

const router = Router();

router.get("/", getUsuarios);
router.post("/", createUsuario);

export default router;
