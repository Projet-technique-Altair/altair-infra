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
  runtime_kind TEXT,
  webshell_url TEXT,
  app_url TEXT,

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

-- ======================
-- TABLE: learner_lab_status
-- ======================
-- Product-level learner tracking for dashboard and explorer follow state.
-- This is intentionally separate from lab_sessions:
-- - lab_sessions tracks runtime lifecycle
-- - learner_lab_status tracks the learner's relationship to a lab
CREATE TABLE learner_lab_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  lab_id UUID NOT NULL,

  status VARCHAR(50) NOT NULL DEFAULT 'todo',
  -- todo | in_progress | finished

  followed_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
  started_at TIMESTAMP,
  finished_at TIMESTAMP,
  last_activity_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
  -- We keep a pointer to the latest relevant runtime session so dashboard progress can stay
  -- session-centric for now without duplicating progress rows here.
  last_session_id UUID,

  UNIQUE (user_id, lab_id),
  FOREIGN KEY (last_session_id)
    REFERENCES lab_sessions(session_id)
    ON DELETE SET NULL
);

CREATE INDEX idx_learner_lab_status_user
  ON learner_lab_status(user_id);

CREATE INDEX idx_learner_lab_status_lab
  ON learner_lab_status(lab_id);

CREATE INDEX idx_learner_lab_status_status
  ON learner_lab_status(status);

CREATE INDEX idx_learner_lab_status_last_activity
  ON learner_lab_status(last_activity_at DESC);
