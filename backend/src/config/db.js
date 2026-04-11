import mysql from "mysql2/promise";

let pool;

const validateDbConfig = () => {
  const requiredEnvVars = ["DB_NAME", "DB_USER"];
  const missingEnvVars = requiredEnvVars.filter(
    (envVar) => !process.env[envVar]?.trim(),
  );

  if (missingEnvVars.length > 0) {
    throw new Error(
      `Faltan variables de entorno de la base de datos: ${missingEnvVars.join(", ")}`,
    );
  }
};

export const getPool = () => {
  if (!pool) {
    validateDbConfig();

    const parsedPort = Number(process.env.DB_PORT);

    pool = mysql.createPool({
      host: process.env.DB_HOST || "localhost",
      port: Number.isNaN(parsedPort) ? 3306 : parsedPort,
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      charset: "utf8mb4",
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
    });
  }

  return pool;
};

export default getPool;
