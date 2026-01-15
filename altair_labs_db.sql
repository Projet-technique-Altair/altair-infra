-- ============================================================
-- altair_labs_db.sql
-- Labs Microservice Database
-- ============================================================

-- ======================
-- TABLE: labs
-- ======================
CREATE TABLE labs (
  lab_id UUID PRIMARY KEY,
  creator_id UUID NOT NULL,        -- référence logique vers Users MS
  name VARCHAR(255) NOT NULL,
  description TEXT,
  difficulty VARCHAR(50),
  category VARCHAR(100),
  template_path TEXT,
  lab_type VARCHAR(50) DEFAULT 'course',  -- course | ctf_terminal_guided | ctf_terminal_non_guided | ctf_web
  objectives TEXT,
  prerequisites TEXT,
  story TEXT,
  estimated_duration VARCHAR(50),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- ======================
-- TABLE: lab_steps
-- ======================
CREATE TABLE lab_steps (
  step_id UUID PRIMARY KEY,
  lab_id UUID NOT NULL,
  step_number INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  question TEXT,
  expected_answer TEXT,
  validation_type VARCHAR(50) DEFAULT 'exact_match', -- exact_match | regex | contains
  validation_pattern TEXT,
  points INT DEFAULT 10,
  created_at TIMESTAMP,
  UNIQUE (lab_id, step_number),
  FOREIGN KEY (lab_id) REFERENCES labs(lab_id) ON DELETE CASCADE
);

-- ======================
-- TABLE: lab_hints
-- ======================
CREATE TABLE lab_hints (
  hint_id UUID PRIMARY KEY,
  step_id UUID NOT NULL,
  hint_number INT NOT NULL,
  cost INT DEFAULT 0,
  text TEXT NOT NULL,
  created_at TIMESTAMP,
  UNIQUE (step_id, hint_number),
  FOREIGN KEY (step_id) REFERENCES lab_steps(step_id) ON DELETE CASCADE
);

-- ======================
-- INDEXES
-- ======================
CREATE INDEX idx_lab_steps_lab ON lab_steps(lab_id, step_number);
CREATE INDEX idx_lab_hints_step ON lab_hints(step_id, hint_number);
