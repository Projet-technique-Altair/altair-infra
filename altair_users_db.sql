-- ============================================================
-- altair_users_db.sql
-- Users Microservice Database (MVP compliant)
-- ============================================================

-- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ======================
-- TABLE: users
-- ======================
CREATE TABLE users (
  user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  keycloak_id VARCHAR(255) UNIQUE NOT NULL, -- lien avec Keycloak
  role VARCHAR(50) NOT NULL,                -- learner | creator | admin

  name VARCHAR(255) NOT NULL,
  pseudo VARCHAR(64) UNIQUE NOT NULL,
  email VARCHAR(320) UNIQUE NOT NULL,

  avatar TEXT,
  last_login TIMESTAMP,

  created_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL
);

-- ======================
-- INDEXES
-- ======================
CREATE INDEX idx_users_keycloak
  ON users(keycloak_id);

CREATE INDEX idx_users_email
  ON users(email);

CREATE INDEX idx_users_last_login
  ON users(last_login);

-- ============================================================
-- ⚠️ POST-MVP (commenté volontairement)
-- ============================================================

-- USER ACHIEVEMENTS (gamification → hors MVP)
-- CREATE TABLE user_achievements (
--   user_id UUID NOT NULL,
--   achievement_code VARCHAR(100) NOT NULL,
--   earned_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
--   PRIMARY KEY (user_id, achievement_code)
-- );
