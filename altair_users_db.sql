-- altair_users_db.sql
-- Users Microservice Database

-- ENUM corrigé
CREATE TYPE user_post AS ENUM ('learner','creator','admin');

-- USERS
CREATE TABLE users (
  user_id UUID PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  pseudo VARCHAR(64) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  mail VARCHAR(320) UNIQUE NOT NULL,
  post user_post NOT NULL,
  avatar TEXT,
  last_login TIMESTAMP,
  date_of_creation TIMESTAMP,
  updated_at TIMESTAMP
);

-- USER SESSIONS
CREATE TABLE user_sessions (
  session_id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  created_at TIMESTAMP,
  expires_at TIMESTAMP
);

-- USER ACHIEVEMENTS
CREATE TABLE user_achievements (
  user_id UUID NOT NULL,
  achievement_code VARCHAR(100) NOT NULL,
  earned_at TIMESTAMP,
  PRIMARY KEY (user_id, achievement_code)
);
