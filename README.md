### 1. Lancer postegre
sudo -i -u postgres
psql


### 2. Créer les db
CREATE DATABASE altair_users_db;
CREATE DATABASE altair_labs_db;
CREATE DATABASE altair_sessions_db;
CREATE DATABASE altair_starpaths_db;
CREATE DATABASE altair_groups_db;


### 3. Se connecter à la db
\c altair_users_db
\i {path}altair_users_db.sql


### 3.5 Si permission non accordée
chmod o+r /home/laura/Documents/ALTAIR/DB/altair_users_db.sql
Refaire le 3
