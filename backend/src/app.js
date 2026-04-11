import express from "express";
import dotenv from "dotenv";
import pool from "./config/db.js";

dotenv.config();

const app = express();
app.use(express.json());

app.get("/", (req, res) => {
  res.send("PlayConnect API funcionando 🚀");
});

app.get("/db-test", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT NOW() AS now");

    res.json({
      ok: true,
      message: "Conexión a MySQL correcta",
      time: rows[0].now,
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      ok: false,
      message: "Error conectando con MySQL",
      error: error.message,
    });
  }
});

app.get("/usuarios", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT id, nombre, email, tipo, created_at FROM usuarios",
    );
    res.json({
      ok: true,
      data: rows,
    });
  } catch (error) {
    console.error("Error obteniendo usuarios:", error.message);
    res.status(500).json({
      ok: false,
      message: "Error obteniendo usuarios",
      error: error.message,
    });
  }
});

app.post("/usuarios", async (req, res) => {
  try {
    const { nombre, email, password, tipo } = req.body;

    if (!nombre || !email || !password) {
      return res.status(400).json({
        ok: false,
        message: "Nombre, email y password son obligatorios",
      });
    }

    const userType = tipo || "normal";

    await pool.query(
      `INSERT INTO usuarios (id, nombre, email, password, tipo)
       VALUES (UUID(), ?, ?, ?, ?)`,
      [nombre, email, password, userType],
    );

    res.status(201).json({
      ok: true,
      message: "Usuario creado correctamente",
    });
  } catch (error) {
    console.error("Error creando usuario:", error.message);
    res.status(500).json({
      ok: false,
      message: "Error creando usuario",
      error: error.message,
    });
  }
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Servidor en http://localhost:${PORT}`);
});
