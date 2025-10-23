-- =====================================================
-- referee_db - Referee Management & Availability Database
-- =====================================================
-- This database contains referee and availability data

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ====================
-- TABLA: referees (Árbitros)
-- ====================
CREATE TABLE referees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- Referencias users de users_db (sin FK cross-database)
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
-- TABLA: availability (Disponibilidad de Árbitros)
-- ====================
CREATE TABLE availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referee_id UUID REFERENCES referees(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    is_available BOOLEAN DEFAULT true,
    time_slots JSONB, -- Slots de tiempo disponibles
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(referee_id, date)
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
CREATE INDEX idx_referees_user_id ON referees(user_id);
CREATE INDEX idx_referees_license_number ON referees(license_number);
CREATE INDEX idx_referees_is_available ON referees(is_available);
CREATE INDEX idx_availability_referee_id ON availability(referee_id);
CREATE INDEX idx_availability_date ON availability(date);
CREATE INDEX idx_tariffs_sport_role ON tariffs(sport, role);
CREATE INDEX idx_billing_periods_referee_id ON billing_periods(referee_id);
CREATE INDEX idx_billing_periods_status ON billing_periods(status);

-- ====================
-- DATOS INICIALES PARA TESTING
-- ====================

-- Nota: Los user_id deben corresponder con IDs reales de users_db
-- Para desarrollo, usaremos UUIDs de ejemplo

-- Árbitros de prueba
INSERT INTO referees (id, user_id, license_number, specialties, certification_level, bank_account, bank_name, account_holder, is_available) VALUES
(uuid_generate_v4(), uuid_generate_v4(), 'LIC-2024-001', ARRAY['futbol', 'futsal'], 'nacional', 'ES1234567890123456789012', 'Banco Santander', 'Juan Pérez', true),
(uuid_generate_v4(), uuid_generate_v4(), 'LIC-2024-002', ARRAY['futbol'], 'internacional', 'ES9876543210987654321098', 'BBVA', 'María López', true);

-- Tarifas básicas
INSERT INTO tariffs (sport, role, category, base_amount, valid_from) VALUES
('futbol', 'central', 'profesional', 150000.00, '2024-01-01'),
('futbol', 'asistente_1', 'profesional', 120000.00, '2024-01-01'),
('futbol', 'asistente_2', 'profesional', 120000.00, '2024-01-01'),
('futbol', 'cuarto_arbitro', 'profesional', 100000.00, '2024-01-01'),
('futsal', 'central', 'profesional', 120000.00, '2024-01-01'),
('futsal', 'asistente_1', 'profesional', 100000.00, '2024-01-01');

-- Mensaje de confirmación
SELECT 'referee_db initialized successfully!' as status;

