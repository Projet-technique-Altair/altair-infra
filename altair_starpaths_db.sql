-- ============================================================
-- altair_starpaths_db.sql
-- Starpaths Microservice Database
-- ============================================================

-- ======================
-- TABLE: starpaths
-- ======================
CREATE TABLE starpaths (
  starpath_id UUID PRIMARY KEY,
  creator_id UUID NOT NULL,     -- référence logique vers Users MS
  name VARCHAR(255) NOT NULL,
  description TEXT,
  difficulty VARCHAR(50),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- ======================
-- TABLE: starpath_labs
-- ======================
CREATE TABLE starpath_labs (
  starpath_id UUID NOT NULL,
  lab_id UUID NOT NULL,         -- référence logique vers Labs MS
  position INT NOT NULL,
  PRIMARY KEY (starpath_id, lab_id),
  FOREIGN KEY (starpath_id) REFERENCES starpaths(starpath_id) ON DELETE CASCADE
);

-- ======================
-- TABLE: user_starpath_progress
-- ======================
CREATE TABLE user_starpath_progress (
  user_id UUID NOT NULL,        -- référence logique vers Users MS
  starpath_id UUID NOT NULL,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  PRIMARY KEY (user_id, starpath_id),
  FOREIGN KEY (starpath_id) REFERENCES starpaths(starpath_id) ON DELETE CASCADE
);

-- ======================
-- INDEXES
-- ======================
CREATE INDEX idx_starpath_labs_position
  ON starpath_labs(starpath_id, position);
