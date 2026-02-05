-- ============================================================
-- altair_labs_db.sql
-- Labs Microservice Database (MVP compliant)
-- ============================================================

-- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ======================
-- TABLE: labs
-- ======================
CREATE TABLE labs (
  lab_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL,        -- référence logique vers Users MS
  name VARCHAR(255) NOT NULL,
  description TEXT,
  difficulty VARCHAR(50),
  category VARCHAR(100),
  template_path TEXT,
  lab_type VARCHAR(50) NOT NULL DEFAULT 'course',  
    -- course | ctf_terminal_guided | ctf_terminal_non_guided | ctf_web
  objectives TEXT,
  prerequisites TEXT,
  story TEXT,
  estimated_duration VARCHAR(50),
  created_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL
);

-- Indexes
CREATE INDEX idx_labs_creator
  ON labs(creator_id);

-- ======================
-- TABLE: lab_steps
-- ======================
CREATE TABLE lab_steps (
  step_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lab_id UUID NOT NULL,
  step_number INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  question TEXT,
  expected_answer TEXT,
  validation_type VARCHAR(50) NOT NULL DEFAULT 'exact_match',
    -- exact_match | regex | contains
  validation_pattern TEXT,
  points INT NOT NULL DEFAULT 10,
  created_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
  UNIQUE (lab_id, step_number),
  FOREIGN KEY (lab_id)
    REFERENCES labs(lab_id)
    ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_lab_steps_lab
  ON lab_steps(lab_id, step_number);

-- ======================
-- TABLE: lab_hints
-- ======================
CREATE TABLE lab_hints (
  hint_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  step_id UUID NOT NULL,
  hint_number INT NOT NULL,
  cost INT NOT NULL DEFAULT 0,
  text TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
  UNIQUE (step_id, hint_number),
  FOREIGN KEY (step_id)
    REFERENCES lab_steps(step_id)
    ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_lab_hints_step
  ON lab_hints(step_id, hint_number);
