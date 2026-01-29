-- ============================================================
-- altair_starpaths_db.sql
-- Starpaths Microservice Database (MVP compliant)
-- ============================================================

-- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ======================
-- TABLE: starpaths
-- ======================
CREATE TABLE starpaths (
  starpath_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL,     -- référence logique vers Users MS

  name VARCHAR(255) NOT NULL,
  description TEXT,
  difficulty VARCHAR(50),

  created_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL
);

-- Indexes
CREATE INDEX idx_starpaths_creator
  ON starpaths(creator_id);

-- ======================
-- TABLE: starpath_labs
-- ======================
CREATE TABLE starpath_labs (
  starpath_id UUID NOT NULL,
  lab_id UUID NOT NULL,         -- référence logique vers Labs MS
  position INT NOT NULL,

  PRIMARY KEY (starpath_id, lab_id),

  FOREIGN KEY (starpath_id)
    REFERENCES starpaths(starpath_id)
    ON DELETE CASCADE
);

-- Unicité de la position dans un starpath
CREATE UNIQUE INDEX idx_starpath_labs_unique_position
  ON starpath_labs(starpath_id, position);


-- ======================
-- TABLE: user_starpath_progress
-- ======================
CREATE TABLE user_starpath_progress (
  user_id UUID NOT NULL,        -- référence logique vers Users MS
  starpath_id UUID NOT NULL,

  current_position INT NOT NULL DEFAULT 0,
  status VARCHAR(50) NOT NULL DEFAULT 'in_progress',
  -- in_progress | completed | abandoned

  started_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
  completed_at TIMESTAMP,

  PRIMARY KEY (user_id, starpath_id),

  FOREIGN KEY (starpath_id)
    REFERENCES starpaths(starpath_id)
    ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_user_starpath_progress_user
  ON user_starpath_progress(user_id);
