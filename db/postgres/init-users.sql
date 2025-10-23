-- =====================================================
-- users_db - Auth Service Database
-- =====================================================
-- This database contains user authentication data

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ====================
-- TABLA: users (Usuarios del sistema)
-- ====================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('arbitro', 'administrador', 'presidente')),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ====================
-- ÍNDICES para Performance
-- ====================
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_is_active ON users(is_active);

-- ====================
-- DATOS INICIALES PARA TESTING
-- ====================

-- Usuarios de prueba (Passwords: admin=admin123, others=password)
INSERT INTO users (email, password_hash, role, first_name, last_name, phone) VALUES
('admin@sgad.com', '$2b$10$/4Cqro6EiOtNVQcFEFjW/OMk0OtUQQoNwZUTPgZhADZRMjEU9qlUG', 'administrador', 'Carlos', 'Administrador', '3001234567'),
('arbitro1@sgad.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'arbitro', 'Juan', 'Pérez', '3007654321'),
('arbitro2@sgad.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'arbitro', 'María', 'López', '3007654322'),
('presidente@sgad.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'presidente', 'María', 'González', '3001111111');

-- Mensaje de confirmación
SELECT 'users_db initialized successfully!' as status;

