-- ============================================================
-- altair_sessions_db.sql
-- Sessions Microservice Database (MVP compliant)
-- ============================================================

-- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ======================
-- TABLE: lab_sessions
-- ======================
CREATE TABLE lab_sessions (
  session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,      -- référence logique vers Users MS
  lab_id UUID NOT NULL,       -- référence logique vers Labs MS

  status VARCHAR(50) NOT NULL DEFAULT 'created',
  -- created | running | stopped | expired | error

  container_id TEXT,
  webshell_url TEXT,

  created_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
  expires_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_lab_sessions_user
  ON lab_sessions(user_id);

CREATE INDEX idx_lab_sessions_lab
  ON lab_sessions(lab_id);

CREATE INDEX idx_lab_sessions_status
  ON lab_sessions(status);

-- ======================
-- TABLE: lab_progress
-- ======================
CREATE TABLE lab_progress (
  progress_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL,

  current_step INT NOT NULL DEFAULT 1,
  completed_steps INT[] NOT NULL DEFAULT '{}',

  hints_used JSONB NOT NULL DEFAULT '[]',
  attempts_per_step JSONB NOT NULL DEFAULT '{}',

  score INT NOT NULL DEFAULT 0,
  max_score INT NOT NULL DEFAULT 0,

  created_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,

  UNIQUE (session_id),
  FOREIGN KEY (session_id)
    REFERENCES lab_sessions(session_id)
    ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_lab_progress_session
  ON lab_progress(session_id);
