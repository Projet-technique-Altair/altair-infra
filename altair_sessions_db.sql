-- ============================================================
-- altair_sessions_db.sql
-- Sessions Microservice Database
-- ============================================================

-- ======================
-- TABLE: lab_sessions
-- ======================
CREATE TABLE lab_sessions (
  session_id UUID PRIMARY KEY,
  user_id UUID NOT NULL,      -- référence logique vers Users MS
  lab_id UUID NOT NULL,       -- référence logique vers Labs MS
  status VARCHAR(50) DEFAULT 'RUNNING',
  webshell_url TEXT,
  pod_name VARCHAR(255),
  started_at TIMESTAMP,
  stopped_at TIMESTAMP,
  expires_at TIMESTAMP
);

-- ======================
-- TABLE: lab_progress
-- ======================
CREATE TABLE lab_progress (
  progress_id UUID PRIMARY KEY,
  session_id UUID NOT NULL,
  current_step INT NOT NULL DEFAULT 1,
  completed_steps INT[] DEFAULT '{}',
  hints_used JSONB DEFAULT '[]',
  attempts_per_step JSONB DEFAULT '{}',
  score INT DEFAULT 0,
  max_score INT DEFAULT 0,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  UNIQUE (session_id),
  FOREIGN KEY (session_id) REFERENCES lab_sessions(session_id) ON DELETE CASCADE
);

-- ======================
-- INDEXES
-- ======================
CREATE INDEX idx_lab_sessions_user ON lab_sessions(user_id);
CREATE INDEX idx_lab_progress_session ON lab_progress(session_id);
