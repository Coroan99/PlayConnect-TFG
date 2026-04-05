-- =====================================================
-- PLAYCONNECT - ESQUEMA INICIAL DE BASE DE DATOS
-- Motor recomendado: PostgreSQL
-- =====================================================

-- =========================
-- TABLA: ubicacion
-- =========================
CREATE TABLE ubicacion (
    id UUID PRIMARY KEY,
    ciudad VARCHAR(100) NOT NULL,
    provincia VARCHAR(100) NOT NULL,
    comunidad VARCHAR(100) NOT NULL
);

-- =========================
-- TABLA: usuario
-- =========================
CREATE TABLE usuario (
    id UUID PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('normal', 'tienda')),
    ubicacion_id UUID NOT NULL,
    CONSTRAINT fk_usuario_ubicacion
        FOREIGN KEY (ubicacion_id) REFERENCES ubicacion(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =========================
-- TABLA: tienda
-- =========================
CREATE TABLE tienda (
    id UUID PRIMARY KEY,
    usuario_id UUID NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    direccion VARCHAR(200) NOT NULL,
    CONSTRAINT fk_tienda_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =========================
-- TABLA: juego
-- =========================
CREATE TABLE juego (
    id UUID PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    codigo_barras VARCHAR(50) UNIQUE,
    imagen TEXT,
    jugadores_min INT CHECK (jugadores_min > 0),
    jugadores_max INT CHECK (jugadores_max >= jugadores_min),
    duracion_min INT CHECK (duracion_min > 0)
);

-- =========================
-- TABLA: inventario
-- =========================
CREATE TABLE inventario (
    id UUID PRIMARY KEY,
    usuario_id UUID NOT NULL,
    juego_id UUID NOT NULL,
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('coleccion', 'visible', 'en_venta')),
    CONSTRAINT fk_inventario_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_inventario_juego
        FOREIGN KEY (juego_id) REFERENCES juego(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =========================
-- TABLA: publicacion
-- =========================
CREATE TABLE publicacion (
    id UUID PRIMARY KEY,
    inventario_id UUID NOT NULL UNIQUE,
    descripcion TEXT,
    fecha DATE NOT NULL,
    CONSTRAINT fk_publicacion_inventario
        FOREIGN KEY (inventario_id) REFERENCES inventario(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =========================
-- TABLA: interes
-- =========================
CREATE TABLE interes (
    id UUID PRIMARY KEY,
    usuario_interesado_id UUID NOT NULL,
    publicacion_id UUID NOT NULL,
    precio_ofrecido NUMERIC(10,2) CHECK (precio_ofrecido >= 0),
    mensaje TEXT,
    CONSTRAINT fk_interes_usuario
        FOREIGN KEY (usuario_interesado_id) REFERENCES usuario(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_interes_publicacion
        FOREIGN KEY (publicacion_id) REFERENCES publicacion(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =========================
-- TABLA: notificacion
-- =========================
CREATE TABLE notificacion (
    id UUID PRIMARY KEY,
    usuario_id UUID NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    mensaje TEXT NOT NULL,
    leida BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_notificacion_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
