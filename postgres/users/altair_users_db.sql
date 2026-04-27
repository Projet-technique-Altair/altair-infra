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
  account_status TEXT NOT NULL DEFAULT 'active',

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

ALTER TABLE users ADD CONSTRAINT users_account_status_check
  CHECK (account_status IN ('active', 'suspended', 'banned'));

CREATE INDEX idx_users_account_status
  ON users(account_status);

-- ======================
-- TABLE: user_sanctions
-- ======================
CREATE TABLE user_sanctions (
  sanction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  actor_user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  action TEXT NOT NULL CHECK (action IN ('warn', 'suspend', 'ban')),
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved')),
  expires_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMP
);

CREATE INDEX idx_user_sanctions_user_id
  ON user_sanctions(user_id);

CREATE INDEX idx_user_sanctions_actor_user_id
  ON user_sanctions(actor_user_id);

CREATE INDEX idx_user_sanctions_created_at
  ON user_sanctions(created_at DESC);

-- ======================
-- TABLE: user_audit_logs
-- ======================
CREATE TABLE user_audit_logs (
  audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
  target_user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_audit_logs_actor_user_id
  ON user_audit_logs(actor_user_id);

CREATE INDEX idx_user_audit_logs_target_user_id
  ON user_audit_logs(target_user_id);

CREATE INDEX idx_user_audit_logs_created_at
  ON user_audit_logs(created_at DESC);

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
