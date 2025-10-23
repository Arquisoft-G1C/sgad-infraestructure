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
-- TABLA: referees (Árbitros)
-- ====================
CREATE TABLE referees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    license_number VARCHAR(50) UNIQUE,
    specialties TEXT[], -- Array: ['futbol', 'futsal']
    certification_level VARCHAR(50), -- 'nacional', 'internacional', etc.
    bank_account VARCHAR(50), -- Para QR de pagos
    bank_name VARCHAR(100),
    account_holder VARCHAR(255),
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ====================
-- TABLA: teams (Equipos)
-- ====================
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100), -- 'profesional', 'amateur', 'juvenil'
    sport VARCHAR(50) NOT NULL CHECK (sport IN ('futbol', 'futsal')),
    logo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ====================
-- TABLA: matches (Partidos)
-- ====================
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    home_team_id UUID REFERENCES teams(id),
    away_team_id UUID REFERENCES teams(id),
    match_date TIMESTAMP WITH TIME ZONE NOT NULL,
    venue VARCHAR(255) NOT NULL,
    sport VARCHAR(50) NOT NULL CHECK (sport IN ('futbol', 'futsal')),
    category VARCHAR(100),
    tournament VARCHAR(255),
    status VARCHAR(50) DEFAULT 'programado' CHECK (status IN ('programado', 'en_curso', 'finalizado', 'cancelado')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ====================
-- TABLA: match_assignments (Asignaciones de Árbitros)
-- ====================
CREATE TABLE match_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    referee_id UUID REFERENCES referees(id),
    role VARCHAR(50) NOT NULL CHECK (role IN ('central', 'asistente_1', 'asistente_2', 'cuarto_arbitro')),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID REFERENCES users(id),
    status VARCHAR(50) DEFAULT 'asignado' CHECK (status IN ('asignado', 'confirmado', 'rechazado')),
    UNIQUE(match_id, role), -- Un solo árbitro por rol por partido
    UNIQUE(match_id, referee_id) -- Un árbitro no puede tener múltiples roles en el mismo partido
);

-- ====================
-- TABLA: tariffs (Tarifas)
-- ====================
CREATE TABLE tariffs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sport VARCHAR(50) NOT NULL CHECK (sport IN ('futbol', 'futsal')),
    role VARCHAR(50) NOT NULL CHECK (role IN ('central', 'asistente_1', 'asistente_2', 'cuarto_arbitro')),
    category VARCHAR(100),
    base_amount DECIMAL(10,2) NOT NULL,
    weekend_multiplier DECIMAL(3,2) DEFAULT 1.0,
    night_multiplier DECIMAL(3,2) DEFAULT 1.0,
    valid_from DATE NOT NULL,
    valid_until DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ====================
-- TABLA: billing_periods (Períodos de Facturación)
-- ====================
CREATE TABLE billing_periods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referee_id UUID REFERENCES referees(id),
    year INTEGER NOT NULL,
    month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    total_matches INTEGER DEFAULT 0,
    total_amount DECIMAL(10,2) DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'pendiente' CHECK (status IN ('pendiente', 'generada', 'pagada')),
    generated_at TIMESTAMP WITH TIME ZONE,
    paid_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(referee_id, year, month)
);

-- ====================
-- ÍNDICES para Performance
-- ====================
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_referees_user_id ON referees(user_id);
CREATE INDEX idx_matches_date ON matches(match_date);
CREATE INDEX idx_matches_status ON matches(status);
CREATE INDEX idx_match_assignments_match_id ON match_assignments(match_id);
CREATE INDEX idx_match_assignments_referee_id ON match_assignments(referee_id);
CREATE INDEX idx_tariffs_sport_role ON tariffs(sport, role);

-- ====================
-- DATOS INICIALES PARA TESTING
-- ====================

-- Usuario Administrador (Passwords: admin=password123, others=password)
INSERT INTO users (email, password_hash, role, first_name, last_name, phone) VALUES
('admin@sgad.com', '$2b$10$UVHvr6xivkqO0AhRN/2caeWrcdC2DW.46xd0jj7HYKoN.30OD61Em', 'administrador', 'Carlos', 'Administrador', '3001234567'),
('arbitro1@sgad.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'arbitro', 'Juan', 'Pérez', '3007654321'),
('presidente@sgad.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'presidente', 'María', 'González', '3001111111');

-- Equipos de prueba
INSERT INTO teams (name, category, sport) VALUES
('Atlético Nacional', 'profesional', 'futbol'),
('Millonarios FC', 'profesional', 'futbol'),
('Deportivo Cali', 'profesional', 'futbol'),
('Boca Juniors FS', 'profesional', 'futsal'),
('Real Madrid FS', 'profesional', 'futsal');

-- Árbitros (vinculados a usuarios)
INSERT INTO referees (user_id, license_number, specialties, certification_level, bank_account, bank_name, account_holder, is_available)
SELECT 
  u.id,
  'LIC-2024-001',
  ARRAY['futbol', 'futsal'],
  'nacional',
  'ES1234567890123456789012',
  'Banco Santander',
  'Juan Pérez',
  true
FROM users u WHERE u.email = 'arbitro1@sgad.com';

-- Partidos de prueba
INSERT INTO matches (home_team_id, away_team_id, match_date, venue, sport, category, tournament, status)
SELECT 
  (SELECT id FROM teams WHERE name = 'Atlético Nacional'),
  (SELECT id FROM teams WHERE name = 'Millonarios FC'),
  CURRENT_TIMESTAMP + INTERVAL '3 days',
  'Estadio Atanasio Girardot',
  'futbol',
  'profesional',
  'Liga BetPlay',
  'programado'
UNION ALL
SELECT 
  (SELECT id FROM teams WHERE name = 'Deportivo Cali'),
  (SELECT id FROM teams WHERE name = 'Atlético Nacional'),
  CURRENT_TIMESTAMP + INTERVAL '5 days',
  'Estadio Deportivo Cali',
  'futbol',
  'profesional',
  'Liga BetPlay',
  'programado'
UNION ALL
SELECT 
  (SELECT id FROM teams WHERE name = 'Millonarios FC'),
  (SELECT id FROM teams WHERE name = 'Deportivo Cali'),
  CURRENT_TIMESTAMP + INTERVAL '7 days',
  'Estadio El Campín',
  'futbol',
  'profesional',
  'Copa Colombia',
  'programado'
UNION ALL
SELECT 
  (SELECT id FROM teams WHERE name = 'Boca Juniors FS'),
  (SELECT id FROM teams WHERE name = 'Real Madrid FS'),
  CURRENT_TIMESTAMP + INTERVAL '2 days',
  'Pabellón Municipal',
  'futsal',
  'profesional',
  'Liga de Futsal',
  'programado';

-- Tarifas básicas
INSERT INTO tariffs (sport, role, category, base_amount, valid_from) VALUES
('futbol', 'central', 'profesional', 150000.00, '2024-01-01'),
('futbol', 'asistente_1', 'profesional', 120000.00, '2024-01-01'),
('futbol', 'asistente_2', 'profesional', 120000.00, '2024-01-01'),
('futbol', 'cuarto_arbitro', 'profesional', 100000.00, '2024-01-01'),
('futsal', 'central', 'profesional', 120000.00, '2024-01-01'),
('futsal', 'asistente_1', 'profesional', 100000.00, '2024-01-01');

-- Mensaje de confirmación
SELECT 'SGAD Database initialized successfully!' as status;