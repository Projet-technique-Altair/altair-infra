-- ============================================================
-- altair_groups_db.sql
-- Groups Microservice Database (MVP compliant)
-- ============================================================

-- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ======================
-- TABLE: groups
-- ======================
CREATE TABLE groups (
  group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL,   -- référence logique vers Users MS
  name VARCHAR(255) NOT NULL,
  description TEXT,
  created_by UUID NOT NULL,
  created_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL
);

-- Indexes
CREATE INDEX idx_groups_creator
  ON groups(creator_id);

-- ======================
-- TABLE: group_members
-- ======================
CREATE TABLE group_members (
  group_id UUID NOT NULL,
  user_id UUID NOT NULL,      -- référence logique vers Users MS
  role VARCHAR(50) NOT NULL DEFAULT 'member', -- member | moderator
  joined_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
  PRIMARY KEY (group_id, user_id),
  FOREIGN KEY (group_id)
    REFERENCES groups(group_id)
    ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_group_members_user
  ON group_members(user_id);

-- ======================
-- TABLE: group_labs
-- ======================
CREATE TABLE group_labs (
  group_id UUID NOT NULL,
  lab_id UUID NOT NULL,       -- référence logique vers Labs MS
  assigned_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
  due_date TIMESTAMP,
  PRIMARY KEY (group_id, lab_id),
  FOREIGN KEY (group_id)
    REFERENCES groups(group_id)
    ON DELETE CASCADE
);


-- ======================
-- TABLE: group_starpaths
-- ======================
CREATE TABLE group_starpaths (
  group_id UUID NOT NULL,
  starpath_id UUID NOT NULL,  -- référence logique vers Starpaths MS
  assigned_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
  PRIMARY KEY (group_id, starpath_id),
  FOREIGN KEY (group_id)
    REFERENCES groups(group_id)
    ON DELETE CASCADE
);


