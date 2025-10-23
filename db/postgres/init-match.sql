-- =====================================================
-- match_db - Match Management Database
-- =====================================================
-- This database contains match and team data

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ====================
-- TABLA: teams (Equipos)
-- ====================
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100), -- 'profesional', 'amateur', 'juvenil'
    sport VARCHAR(50) NOT NULL CHECK (sport IN ('futbol', 'futsal')),
    logo_url TEXT,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
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
    referee_id UUID NOT NULL, -- Referencias referees de referee_db (sin FK cross-database)
    role VARCHAR(50) NOT NULL CHECK (role IN ('central', 'asistente_1', 'asistente_2', 'cuarto_arbitro')),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID, -- User ID from users_db
    status VARCHAR(50) DEFAULT 'asignado' CHECK (status IN ('asignado', 'confirmado', 'rechazado')),
    notes TEXT,
    UNIQUE(match_id, role), -- Un solo árbitro por rol por partido
    UNIQUE(match_id, referee_id) -- Un árbitro no puede tener múltiples roles en el mismo partido
);

-- ====================
-- TABLA: match_results (Resultados de Partidos)
-- ====================
CREATE TABLE match_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE UNIQUE,
    home_score INTEGER NOT NULL DEFAULT 0,
    away_score INTEGER NOT NULL DEFAULT 0,
    incidents JSONB, -- JSON con incidentes del partido
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ====================
-- ÍNDICES para Performance
-- ====================
CREATE INDEX idx_teams_sport ON teams(sport);
CREATE INDEX idx_teams_category ON teams(category);
CREATE INDEX idx_matches_date ON matches(match_date);
CREATE INDEX idx_matches_status ON matches(status);
CREATE INDEX idx_matches_sport ON matches(sport);
CREATE INDEX idx_matches_home_team ON matches(home_team_id);
CREATE INDEX idx_matches_away_team ON matches(away_team_id);
CREATE INDEX idx_match_assignments_match_id ON match_assignments(match_id);
CREATE INDEX idx_match_assignments_referee_id ON match_assignments(referee_id);
CREATE INDEX idx_match_assignments_status ON match_assignments(status);

-- ====================
-- DATOS INICIALES PARA TESTING
-- ====================

-- Equipos de prueba
INSERT INTO teams (name, category, sport, contact_email) VALUES
('Atlético Nacional', 'profesional', 'futbol', 'contacto@nacionalofc.com'),
('Millonarios FC', 'profesional', 'futbol', 'info@millonarios.com.co'),
('Deportivo Cali', 'profesional', 'futbol', 'contacto@deportivocali.com'),
('América de Cali', 'profesional', 'futbol', 'info@america.com.co'),
('Boca Juniors FS', 'profesional', 'futsal', 'info@bocajuniorsfs.com'),
('Real Madrid FS', 'profesional', 'futsal', 'contacto@realmadridfs.com');

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
  (SELECT id FROM teams WHERE name = 'América de Cali'),
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

-- Mensaje de confirmación
SELECT 'match_db initialized successfully!' as status;

