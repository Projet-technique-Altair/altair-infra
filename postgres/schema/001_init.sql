-- ============================================================
-- ALTAÏR DATABASE SCHEMA (with enums, triggers & refinements)
-- ============================================================

-- ============================================================
-- ENUM TYPES
-- ============================================================

CREATE TYPE organization_type AS ENUM ('school','company','association','individual');
CREATE TYPE constellation_tier AS ENUM ('northern','southern','equatorial');
CREATE TYPE user_post AS ENUM ('student','creator','admin');
CREATE TYPE user_status AS ENUM ('active','blackhole','banned');
CREATE TYPE theme_type AS ENUM ('dark','light','system');
CREATE TYPE ai_scenario_status AS ENUM ('draft','generated','validated');
CREATE TYPE lab_visibility AS ENUM ('public','private');
CREATE TYPE lab_sub_status AS ENUM ('pending','graded','returned');
CREATE TYPE team_role AS ENUM ('member','leader');
CREATE TYPE event_visibility AS ENUM ('public','private');
CREATE TYPE stardust_reason AS ENUM ('lab_completed','lab_created','shop_purchase','achievement','admin_adjust');
CREATE TYPE shop_category AS ENUM ('constellation','badge','avatar_frame','theme');
CREATE TYPE notification_type AS ENUM ('lab_validated','review_flagged','help_used','trophy_earned','system');

-- ============================================================
-- TRIGGER FUNCTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.updated_at := timezone('UTC'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- USERS & ORGS
-- ============================================================

CREATE TABLE organizations
(
    organization_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255)                                          NOT NULL,
    type            organization_type                                     NOT NULL,
    domain          VARCHAR(255),
    logo_url        TEXT,
    description     TEXT,
    created_at      TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL
);

CREATE TABLE constellations
(
    constellation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name             VARCHAR(100)                                          NOT NULL,
    symbol           TEXT,
    description      TEXT,
    tier             constellation_tier                                    NOT NULL,
    color_theme      TEXT,
    badge_url        TEXT,
    created_at       TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    updated_at       TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL
);

CREATE TABLE users
(
    user_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name             VARCHAR(255)                                          NOT NULL,
    pseudo           VARCHAR(64) UNIQUE                                    NOT NULL,
    password         VARCHAR(255)                                          NOT NULL,
    mail             VARCHAR(320) UNIQUE                                   NOT NULL,
    post             user_post                                             NOT NULL,
    avatar           TEXT,
    last_login       TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    date_of_creation TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    updated_at       TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    stardust         INT              DEFAULT 0,
    constellation_id UUID                                                  REFERENCES constellations (constellation_id) ON DELETE SET NULL,
    status           user_status                                           NOT NULL DEFAULT 'active',
    bio              TEXT,
    organization_id  UUID                                                  REFERENCES organizations (organization_id) ON DELETE SET NULL
);

CREATE TABLE users_settings
(
    user_id               UUID PRIMARY KEY REFERENCES users (user_id) ON DELETE CASCADE,
    theme                 theme_type,
    language              VARCHAR(16),
    notifications_enabled BOOLEAN   DEFAULT TRUE,
    ai_help_enabled       BOOLEAN   DEFAULT TRUE,
    updated_at            TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL
);

-- ============================================================
-- LABS / PROGRESSION / REVIEW / AI
-- ============================================================

CREATE TABLE ai_scenario
(
    scenario_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name           VARCHAR(255)                                          NOT NULL,
    prompt         TEXT                                                  NOT NULL,
    generated_spec JSONB,
    created_by     UUID                                                  REFERENCES users (user_id) ON DELETE SET NULL,
    created_at     TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    status         ai_scenario_status                                    NOT NULL
);

CREATE TABLE labs
(
    lab_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id       UUID                                                  NOT NULL REFERENCES users (user_id),
    organization_id  UUID                                                  REFERENCES organizations (organization_id) ON DELETE SET NULL,
    scenario_id      UUID                                                  REFERENCES ai_scenario (scenario_id) ON DELETE SET NULL,
    name             VARCHAR(255)                                          NOT NULL,
    description      TEXT,
    difficulty       TEXT,          -- could later be an enum: beginner/intermediate/advanced
    visibility       lab_visibility                                        NOT NULL,
    path             VARCHAR(255),  -- logical path / slug
    image            TEXT,
    runtime_limit    INT,           -- in minutes or seconds
    tags             JSONB,
    estimated_time   INT,           -- in minutes
    validated        BOOLEAN          DEFAULT FALSE,
    version          INT              DEFAULT 1,
    note             NUMERIC(3, 2), -- average rating, e.g. 4.75
    date_of_creation TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    updated_at       TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL
);

CREATE TABLE lab_progress
(
    lab_progress_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_id           UUID                                                  NOT NULL REFERENCES labs (lab_id) ON DELETE CASCADE,
    user_id          UUID                                                  NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    start_time       TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    finish_time      TIMESTAMP,
    status           TEXT, -- e.g. in_progress / completed / abandoned
    attempts         INT              DEFAULT 0,
    last_update      TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    progress_percent INT CHECK (progress_percent BETWEEN 0 AND 100),
    checkpoint_data  JSONB,
    help_used        BOOLEAN          DEFAULT FALSE,
    xp_earned        INT              DEFAULT 0,
    UNIQUE (user_id, lab_id)
);

CREATE TABLE lab_attempts
(
    attempt_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_id      UUID                                                  NOT NULL REFERENCES labs (lab_id) ON DELETE CASCADE,
    user_id     UUID                                                  NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    status      TEXT, -- success / failed / timeout / etc.
    start_time  TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    finish_time TIMESTAMP,
    meta        JSONB,
    time_spent  INT,  -- seconds or ms
    success     BOOLEAN          DEFAULT FALSE
);

CREATE TABLE lab_sub
(
    submission_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_id         UUID                                                  NOT NULL REFERENCES labs (lab_id) ON DELETE CASCADE,
    user_id        UUID                                                  NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    submitted_at   TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    file_url       TEXT,          -- public URL
    storage_key    TEXT,          -- internal/bucket key
    ai_feedback    JSONB,
    human_feedback TEXT,
    score          NUMERIC(5, 2), -- 0-100 with decimals
    graded_by      UUID                                                  REFERENCES users (user_id) ON DELETE SET NULL,
    graded_at      TIMESTAMP,
    created_at     TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    status         lab_sub_status                                        NOT NULL
);

CREATE TABLE storage_files
(
    file_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id   UUID                                                  NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    lab_id     UUID REFERENCES labs (lab_id) ON DELETE CASCADE,
    file_path  TEXT                                                  NOT NULL,
    mime_type  VARCHAR(100),
    size_bytes BIGINT,
    meta       JSONB,
    created_at TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    access     TEXT                                                  NOT NULL CHECK (access IN ('private', 'public', 'team')),
    checksum   TEXT
);

CREATE TABLE review
(
    review_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_id     UUID                                                  NOT NULL REFERENCES labs (lab_id) ON DELETE CASCADE,
    user_id    UUID                                                  NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    note       INT                                                   NOT NULL CHECK (note BETWEEN 0 AND 5),
    message    TEXT,
    recommand  BOOLEAN,
    created_at TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    UNIQUE (user_id, lab_id)
);

CREATE TABLE lab_sessions (
                              session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                              user_id UUID NOT NULL,
                              lab_id UUID NOT NULL,
                              container_id TEXT,
                              status TEXT,
                              webshell_url TEXT,
                              created_at TIMESTAMP DEFAULT now(),
                              expires_at TIMESTAMP
);

-- ============================================================
-- PATHS
-- ============================================================

CREATE TABLE paths
(
    path_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id       UUID                                                  NOT NULL REFERENCES users (user_id),
    name             VARCHAR(255)                                          NOT NULL,
    description      TEXT,
    visibility       TEXT, -- could become enum
    difficulty       TEXT, -- could become enum
    note             NUMERIC(3, 2),
    review           TEXT,
    size             INT,  -- number of labs or "weight"
    date_of_creation TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    updated_at       TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    labs             JSONB -- ordered list [{lab_id, order},...]
);

-- ============================================================
-- TEAMS / EVENTS
-- ============================================================

CREATE TABLE team
(
    team_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name           VARCHAR(255)                                          NOT NULL,
    creator_id     UUID                                                  REFERENCES users (user_id) ON DELETE SET NULL,
    description    TEXT,
    logo_url       TEXT,
    total_stardust INT              DEFAULT 0,
    rank           INT,
    created_at     TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL,
    updated_at     TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL
);

CREATE TABLE team_members
(
    team_id   UUID                                           NOT NULL REFERENCES team (team_id) ON DELETE CASCADE,
    user_id   UUID                                           NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    joined_at TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
    role      team_role                                      NOT NULL,
    PRIMARY KEY (team_id, user_id)
);

CREATE TABLE events
(
    event_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           VARCHAR(255)     NOT NULL,
    description     TEXT,
    banner_url      TEXT,
    start_date      TIMESTAMP        NOT NULL,
    end_date        TIMESTAMP        NOT NULL,
    reward_stardust INT              DEFAULT 0,
    created_by      UUID             REFERENCES users (user_id) ON DELETE SET NULL,
    visibility      event_visibility NOT NULL
);

CREATE TABLE event_lab
(
    event_id UUID NOT NULL REFERENCES events (event_id) ON DELETE CASCADE,
    lab_id   UUID NOT NULL REFERENCES labs (lab_id) ON DELETE CASCADE,
    PRIMARY KEY (event_id, lab_id)
);

CREATE TABLE event_participants
(
    event_id UUID NOT NULL REFERENCES events (event_id) ON DELETE CASCADE,
    user_id  UUID NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    score    INT DEFAULT 0,
    rank     INT,
    PRIMARY KEY (event_id, user_id)
);

-- ============================================================
-- GAMIFICATION
-- ============================================================

CREATE TABLE achievements
(
    achievement_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(100) UNIQUE                                   NOT NULL, -- e.g. FIRST_LAB_COMPLETED
    title           VARCHAR(255)                                          NOT NULL,
    description     TEXT,
    icon_url        TEXT,
    reward_stardust INT              DEFAULT 0,
    created_at      TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL
);

CREATE TABLE user_achievements
(
    user_id        UUID                                           NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    achievement_id UUID                                           NOT NULL REFERENCES achievements (achievement_id) ON DELETE CASCADE,
    earned_at      TIMESTAMP DEFAULT timezone('UTC'::text, now()) NOT NULL,
    PRIMARY KEY (user_id, achievement_id)
);

CREATE TABLE stardust_log
(
    stardust_log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID                                                  NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    change          INT                                                   NOT NULL, -- +/- Stardust
    reason          stardust_reason                                       NOT NULL,
    lab_id          UUID                                                  REFERENCES labs (lab_id) ON DELETE SET NULL,
    created_at      TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL
);

CREATE TABLE shop_items
(
    item_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(255)  NOT NULL,
    description TEXT,
    price       INT           NOT NULL,
    category    shop_category NOT NULL,
    asset_url   TEXT,
    available   BOOLEAN          DEFAULT TRUE
);

CREATE TABLE purchases
(
    purchase_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID                                                  NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    item_id      UUID                                                  NOT NULL REFERENCES shop_items (item_id),
    purchased_at TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL
);

-- ============================================================
-- LOGGING / NOTIFICATIONS
-- ============================================================

CREATE TABLE logs
(
    log_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID                                                  REFERENCES users (user_id) ON DELETE SET NULL,
    action      TEXT                                                  NOT NULL,
    action_type TEXT, -- create_lab / login / grade_lab ...
    target_type TEXT, -- 'lab','user','file','path',...
    target_id   UUID, -- id of the polymorphic target
    lab_id      UUID                                                  REFERENCES labs (lab_id) ON DELETE SET NULL,
    ip_address  INET,
    user_agent  TEXT,
    meta        JSONB,
    created_at  TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL
);

CREATE TABLE notification
(
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID                                                  NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    type            notification_type                                     NOT NULL,
    message         TEXT                                                  NOT NULL,
    link            TEXT,
    is_read         BOOLEAN          DEFAULT FALSE,
    created_at      TIMESTAMP        DEFAULT timezone('UTC'::text, now()) NOT NULL
);

-- ============================================================
-- INDEXES (optimized)
-- ============================================================

-- Users & orgs
CREATE INDEX idx_users_org ON users (organization_id);
CREATE INDEX idx_users_constellation ON users (constellation_id);

-- Labs & progression
CREATE INDEX idx_labs_creator ON labs (creator_id);
CREATE INDEX idx_labs_org_visibility ON labs (organization_id, visibility);
CREATE INDEX idx_labs_visibility ON labs (visibility);
CREATE INDEX idx_labs_tags_gin ON labs USING GIN (tags);

CREATE INDEX idx_lab_progress_user_lab ON lab_progress (user_id, lab_id);
CREATE INDEX idx_lab_progress_lab_user ON lab_progress (lab_id, user_id);

CREATE INDEX idx_lab_sub_lab ON lab_sub (lab_id);
CREATE INDEX idx_lab_sub_user ON lab_sub (user_id);

CREATE INDEX idx_review_lab ON review (lab_id);
CREATE INDEX idx_review_user ON review (user_id);

-- Teams & events
CREATE INDEX idx_team_members_team ON team_members (team_id);
CREATE INDEX idx_team_members_user ON team_members (user_id);

CREATE INDEX idx_event_participants_event ON event_participants (event_id);
CREATE INDEX idx_event_participants_user ON event_participants (user_id);

-- Gamification
CREATE INDEX idx_stardust_log_user_created_at ON stardust_log (user_id, created_at DESC);

-- Notifications & logs
CREATE INDEX idx_notification_user_read ON notification (user_id, is_read, created_at DESC);
CREATE INDEX idx_logs_user_created_at ON logs (user_id, created_at DESC);
CREATE INDEX idx_logs_lab_created_at ON logs (lab_id, created_at DESC);

-- ============================================================
-- TRIGGERS (auto-update updated_at)
-- ============================================================

CREATE TRIGGER trg_update_constellations
    BEFORE UPDATE
    ON constellations
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_users_settings
    BEFORE UPDATE
    ON users_settings
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_team
    BEFORE UPDATE
    ON team
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_users
    BEFORE UPDATE
    ON users
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_labs
    BEFORE UPDATE
    ON labs
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_paths
    BEFORE UPDATE
    ON paths
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
