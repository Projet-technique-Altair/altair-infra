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
  -- created | in_progress | completed
  current_runtime_id UUID,

  created_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
  completed_at TIMESTAMP,
  last_activity_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,

  CONSTRAINT chk_lab_sessions_status
    CHECK (status IN ('created', 'in_progress', 'completed'))
);

-- Indexes
CREATE INDEX idx_lab_sessions_user
  ON lab_sessions(user_id);

CREATE INDEX idx_lab_sessions_lab
  ON lab_sessions(lab_id);

CREATE INDEX idx_lab_sessions_status
  ON lab_sessions(status);

CREATE UNIQUE INDEX idx_lab_sessions_one_active_per_user_lab
  ON lab_sessions(user_id, lab_id)
  WHERE status IN ('created', 'in_progress');

-- ======================
-- TABLE: lab_session_runtimes
-- ======================
CREATE TABLE lab_session_runtimes (
  runtime_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL,

  container_id TEXT UNIQUE,
  runtime_kind TEXT NOT NULL,
  -- terminal | web
  status VARCHAR(50) NOT NULL DEFAULT 'created',
  -- created | starting | running | stopped | expired | error

  namespace TEXT NOT NULL,
  webshell_url TEXT,
  app_url TEXT,

  created_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
  last_seen_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  stopped_at TIMESTAMP,
  restart_index INT NOT NULL DEFAULT 1,

  CONSTRAINT fk_lab_session_runtimes_session
    FOREIGN KEY (session_id)
    REFERENCES lab_sessions(session_id)
    ON DELETE CASCADE,

  CONSTRAINT chk_lab_session_runtimes_kind
    CHECK (runtime_kind IN ('terminal', 'web')),

  CONSTRAINT chk_lab_session_runtimes_status
    CHECK (status IN ('created', 'starting', 'running', 'stopped', 'expired', 'error'))
);

ALTER TABLE lab_sessions
  ADD CONSTRAINT fk_lab_sessions_current_runtime
  FOREIGN KEY (current_runtime_id)
  REFERENCES lab_session_runtimes(runtime_id)
  ON DELETE SET NULL;

CREATE INDEX idx_lab_session_runtimes_session
  ON lab_session_runtimes(session_id);

CREATE INDEX idx_lab_session_runtimes_status
  ON lab_session_runtimes(status);

CREATE UNIQUE INDEX idx_lab_session_runtimes_one_active_per_session
  ON lab_session_runtimes(session_id)
  WHERE status IN ('created', 'starting', 'running');

CREATE UNIQUE INDEX idx_lab_session_runtimes_restart_index
  ON lab_session_runtimes(session_id, restart_index);

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
-- - lab_sessions tracks pedagogical state
-- - lab_session_runtimes tracks runtime history
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
