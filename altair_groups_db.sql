-- ============================================================
-- altair_groups_db.sql
-- Groups Microservice Database
-- ============================================================

-- ======================
-- TABLE: groups
-- ======================
CREATE TABLE groups (
  group_id UUID PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  created_by UUID NOT NULL,   -- référence logique vers Users MS
  created_at TIMESTAMP
);

-- ======================
-- TABLE: group_members
-- ======================
CREATE TABLE group_members (
  group_id UUID NOT NULL,
  user_id UUID NOT NULL,      -- référence logique vers Users MS
  role VARCHAR(50) DEFAULT 'member',
  joined_at TIMESTAMP,
  PRIMARY KEY (group_id, user_id),
  FOREIGN KEY (group_id) REFERENCES groups(group_id) ON DELETE CASCADE
);

-- ======================
-- TABLE: group_labs
-- ======================
CREATE TABLE group_labs (
  group_id UUID NOT NULL,
  lab_id UUID NOT NULL,       -- référence logique vers Labs MS
  assigned_at TIMESTAMP,
  PRIMARY KEY (group_id, lab_id),
  FOREIGN KEY (group_id) REFERENCES groups(group_id) ON DELETE CASCADE
);

-- ======================
-- TABLE: group_starpaths
-- ======================
CREATE TABLE group_starpaths (
  group_id UUID NOT NULL,
  starpath_id UUID NOT NULL,  -- référence logique vers Starpaths MS
  assigned_at TIMESTAMP,
  PRIMARY KEY (group_id, starpath_id),
  FOREIGN KEY (group_id) REFERENCES groups(group_id) ON DELETE CASCADE
);

-- ======================
-- INDEXES
-- ======================
CREATE INDEX idx_group_members_user ON group_members(user_id);
