import { Router } from "express";
import {
  getPublicacionById,
  getPublicaciones,
  postPublicacion,
  removePublicacion,
} from "../controllers/publicaciones.controller.js";

const router = Router();

router.post("/", postPublicacion);
router.get("/", getPublicaciones);
router.get("/:id", getPublicacionById);
router.delete("/:id", removePublicacion);

export default router;
