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
  visibility VARCHAR(16) NOT NULL DEFAULT 'private',
  content_status TEXT NOT NULL DEFAULT 'active',
  template_path TEXT NOT NULL,
  lab_type VARCHAR(50) NOT NULL DEFAULT 'ctf_terminal_guided',
    -- legacy type derived from lab_family + lab_delivery
  lab_family VARCHAR(50) NOT NULL DEFAULT 'guided',
    -- course | guided | non_guided
  lab_delivery VARCHAR(50) NOT NULL DEFAULT 'terminal',
    -- terminal | web | complex
  runtime JSONB NOT NULL DEFAULT '{"app_port": null, "services": [], "entrypoints": []}'::jsonb,
  objectives TEXT,
  prerequisites TEXT,
  story TEXT,
  estimated_duration VARCHAR(50),
  created_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL
);

-- Indexes
CREATE INDEX idx_labs_creator
  ON labs(creator_id);

ALTER TABLE labs ADD CONSTRAINT labs_content_status_check
  CHECK (content_status IN ('active', 'archived'));

CREATE INDEX idx_labs_content_status
  ON labs(content_status);

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
