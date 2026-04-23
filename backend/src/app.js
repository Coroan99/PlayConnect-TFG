import dotenv from "dotenv";
import cors from "cors";
import express from "express";
import { getPool } from "./config/db.js";
import { ensureInventarioTable } from "./repositories/inventario.repository.js";
import { ensureJuegosTable } from "./repositories/juegos.repository.js";
import { ensureInteresesTable } from "./repositories/intereses.repository.js";
import { ensureNotificacionesTable } from "./repositories/notificaciones.repository.js";
import { ensureOfertasTable } from "./repositories/ofertas.repository.js";
import { ensurePublicacionesTable } from "./repositories/publicaciones.repository.js";
import { ensureUsuariosTable } from "./repositories/usuarios.repository.js";
import inventarioRoutes from "./routes/inventario.routes.js";
import interesesRoutes from "./routes/intereses.routes.js";
import juegosRoutes from "./routes/juegos.routes.js";
import notificacionesRoutes from "./routes/notificaciones.routes.js";
import ofertasRoutes from "./routes/ofertas.routes.js";
import publicacionesRoutes from "./routes/publicaciones.routes.js";
import usuariosRoutes from "./routes/usuarios.routes.js";
import { AppError } from "./utils/app-error.js";
import { sendError, sendSuccess } from "./utils/response.js";

dotenv.config({ quiet: true });

const app = express();
const PORT = process.env.PORT || 3000;

app.disable("x-powered-by");
app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  return sendSuccess(res, {
    message: "PlayConnect API funcionando correctamente",
    data: {
      name: "PlayConnect API",
      status: "online",
    },
  });
});

app.get("/db-test", async (req, res) => {
  try {
    const pool = getPool();
    const [rows] = await pool.query("SELECT NOW() AS now");

    return sendSuccess(res, {
      message: "Conexión a MySQL correcta",
      data: {
        now: rows[0].now,
      },
    });
  } catch (error) {
    console.error("Error conectando con MySQL:", error);

    return sendError(res, {
      statusCode: 500,
      message: "Error conectando con MySQL",
      error: error.message,
    });
  }
});

app.use("/usuarios", usuariosRoutes);
app.use("/api/usuarios", usuariosRoutes);
app.use("/api/juegos", juegosRoutes);
app.use("/api/inventario", inventarioRoutes);
app.use("/api/publicaciones", publicacionesRoutes);
app.use("/api", interesesRoutes);
app.use("/api", ofertasRoutes);
app.use("/api", notificacionesRoutes);

app.use((req, res) => {
  return sendError(res, {
    statusCode: 404,
    message: "Ruta no encontrada",
  });
});

app.use((error, req, res, next) => {
  if (error instanceof SyntaxError && error.status === 400 && "body" in error) {
    return sendError(res, {
      statusCode: 400,
      message: "JSON inválido en el cuerpo de la petición",
    });
  }

  if (error instanceof AppError) {
    return sendError(res, {
      statusCode: error.statusCode,
      message: error.message,
    });
  }

  console.error("Error interno no controlado:", error);

  return sendError(res, {
    statusCode: 500,
    message: "Error interno del servidor",
    error: error.message,
  });
});

const startServer = async () => {
  try {
    await ensureUsuariosTable();
    await ensureJuegosTable();
    await ensureInventarioTable();
    await ensurePublicacionesTable();
    await ensureInteresesTable();
    await ensureOfertasTable();
    await ensureNotificacionesTable();

    app.listen(PORT, () => {
      console.log(`Servidor en http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error("Error iniciando la aplicación:", error);
    process.exit(1);
  }
};

startServer();
