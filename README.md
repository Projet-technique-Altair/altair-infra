# Altaïr Infrastructure

> **Local development infrastructure for the Altaïr learning platform**
> 

[![Docker Compose](https://img.shields.io/badge/docker-compose-2496ED)](https://docs.docker.com/compose/)

[![PostgreSQL](https://img.shields.io/badge/postgresql-16-336791)](https://www.postgresql.org/)

[![Keycloak](https://img.shields.io/badge/keycloak-26.5.0-blue)](https://www.keycloak.org/)

[![Grafana](https://img.shields.io/badge/grafana-latest-orange)](https://grafana.com/)

---

## Description

**Altaïr Infrastructure** provides a complete local development environment for the Altaïr platform. It orchestrates **7 containerized services** through Docker Compose:

- **5 PostgreSQL databases** (one per microservice: users, groups, starpaths, sessions, labs)
- **Keycloak** authentication server with custom realm and theme
- **Grafana** monitoring dashboard with provisioned datasources

This infrastructure follows a **strict separation pattern**: each microservice owns its dedicated PostgreSQL database with independent schemas, volumes, and ports. Cross-service references use logical UUIDs, not database-level foreign keys.

**Key characteristics:**

- Production-like architecture in local environment
- Automated schema initialization via SQL scripts
- Custom Keycloak theme and realm pre-configured
- Persistent data volumes for each database
- Observability ready with Grafana provisioning

---

## ⚠️ Important Notes

- **Database initialization only runs on first launch** (empty volumes). To reset schemas and data, remove Docker volumes (see Reset section).
- **Keycloak requires a `.env` file** (use `.env.example` as a template). Never commit `.env`.
- **Gateway and Frontend are NOT included** in this compose stack – they run separately.
- **Ports and credentials are dev defaults** and can be overridden via environment variables (see `.env.example`) for network isolation

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose Stack                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Keycloak    │  │   Grafana    │  │  PostgreSQL  │     │
│  │   :8080      │  │    :4000     │  │   (Users)    │     │
│  │              │  │              │  │    :5433     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ PostgreSQL   │  │  PostgreSQL  │  │  PostgreSQL  │     │
│  │  (Groups)    │  │ (Starpaths)  │  │  (Sessions)  │     │
│  │   :5434      │  │    :5435     │  │    :5436     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                             │
│  ┌──────────────┐                                          │
│  │ PostgreSQL   │                                          │
│  │   (Labs)     │                                          │
│  │   :5437      │                                          │
│  └──────────────┘                                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
         ▲                    ▲
         │                    │
  ┌──────┴─────┐      ┌──────┴──────┐
  │  Gateway   │      │  Frontend   │
  │ (separate) │      │  (separate) │
  └────────────┘      └─────────────┘
```

### Service Flow

1. **Frontend** authenticates users via **Keycloak** (port 8080)
2. **Gateway** validates JWT tokens and routes requests to microservices
3. **Microservices** access their dedicated PostgreSQL instances
4. **Grafana** provides monitoring dashboards (port 4000)

---

## Tech Stack

| Component | Technology | Version | Purpose |
| --- | --- | --- | --- |
| **Orchestration** | Docker Compose | - | Local multi-container environment |
| **Authentication** | Keycloak | 26.5.0 | Identity and access management |
| **Databases** | PostgreSQL | 14+ | Data persistence (5 instances) |
| **Monitoring** | Grafana | latest | Observability dashboards |
| **Base Image** | Alpine Linux | - | Lab container template |

---

## Requirements

### Development

- **Docker** 20.10+
- **Docker Compose** 2.0+
- **`.env` file** in the repository root (see below)

### Environment Variables

Create a `.env` file at the root of `altair-infra/` from the provided template:

```bash
cp .env.example .env
```

Then edit .env and set at least:
KC_BOOTSTRAP_ADMIN_USERNAME
KC_BOOTSTRAP_ADMIN_PASSWORD

**Do NOT commit .env to version control. Use .env.example as the source of truth.**

---

## Installation

### Quick Start

```bash
# 1) Enter the repository
cd altair-infra

# 2) Create your local environment file
cp .env.example .env
# Edit .env and set your Keycloak admin password

# 3) Start the stack
make up

# 4) Check readiness (waits for Grafana + Keycloak HTTP to respond)
make health
```

### First-Time Setup

On first launch, Docker Compose will:

1. Create 5 persistent volumes for PostgreSQL instances
2. Initialize database schemas from `postgres/*/altair_*_db.sql`
3. Import Keycloak realm from `keycloak/realms/altair-realm.json`
4. Load Grafana datasources and dashboards from `grafana/provisioning/`

**This initialization only happens once per volume.** To reset databases, see Troubleshooting section.

---

## Usage

### Starting the Infrastructure

```bash
cd altair-infra
docker compose up -d
```

**Services will be available at (default ports):**

- **Keycloak:** http://localhost:8080  
  Admin credentials are defined in `.env` (`KC_BOOTSTRAP_ADMIN_USERNAME` / `KC_BOOTSTRAP_ADMIN_PASSWORD`).
- **Grafana:** http://localhost:4000  
  Admin credentials are defined in `.env` (`GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD`).
- **PostgreSQL instances (host ports are configurable):**
  - Users DB: `localhost:5433`
  - Groups DB: `localhost:5434`
  - Starpaths DB: `localhost:5435`
  - Sessions DB: `localhost:5436`
  - Labs DB: `localhost:5437`

> If you have port collisions, override the `*_PORT` variables in `.env` (see `.env.example`).


### Starting Gateway and Frontend

The infrastructure must be running before starting these services:

```bash
# Terminal 2: Start the Gateway
cd ../altair-gateway
cargo run

# Terminal 3: Start the Frontend
cd ../altair-frontend
npm run dev
```

**Expected frontend URL:** http://localhost:5173

### Stopping the Infrastructure

```bash
# Stop containers (preserves volumes)
docker compose down

# Stop and remove volumes (DELETES ALL DATA)
docker compose down -v
```

### Viewing Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f keycloak
docker compose logs -f altair-postgres-users
```

---

## Database Schemas

Each microservice has a dedicated PostgreSQL database with isolated schemas.

### Users DB (port 5433)

**Database:** `altair_users_db`

**Table:** `users`

| Column | Type | Constraints | Description |
| --- | --- | --- | --- |
| `user_id` | UUID | PRIMARY KEY | Internal identifier (auto-generated) |
| `keycloak_id` | TEXT | UNIQUE, NOT NULL | External Keycloak identity |
| `role` | VARCHAR(50) | NOT NULL | User role: `learner`, `creator`, `admin` |
| `name` | TEXT |  | Display name |
| `pseudo` | TEXT | UNIQUE | Username/slug |
| `email` | TEXT | UNIQUE | Email address |
| `avatar` | TEXT |  | Avatar URL |
| `last_login` | TIMESTAMP |  | Last authentication timestamp |
| `created_at` | TIMESTAMP | NOT NULL | Account creation timestamp |

**Indexes:** `keycloak_id`, `email`, `last_login`

---

### Groups DB (port 5434)

**Database:** `altair_groups_db`

**Tables:**

- `groups` – Group metadata (creator_id, name, description, visibility)
- `group_members` – Many-to-many: group ↔ user (with role: `owner`, `admin`, `member`)
- `group_labs` – Labs assigned to groups
- `group_starpaths` – Starpaths assigned to groups

**Foreign Keys:** All child tables cascade delete when group is removed.

---

### Starpaths DB (port 5435)

**Database:** `altair_starpaths_db`

**Tables:**

- `starpaths` – Learning path metadata (creator_id, name, description, difficulty, tags, visibility)
- `starpath_labs` – Ordered labs within a starpath (composite PK: `starpath_id`, `lab_id`; unique `position`)
- `user_starpath_progress` – User progress tracking (composite PK: `user_id`, `starpath_id`)

**Key constraint:** `(starpath_id, position)` is unique – ensures no duplicate positions in a path.

---

### Sessions DB (port 5436)

**Database:** `altair_sessions_db`

**Tables:**

- `lab_sessions` – Pedagogical sessions (user_id, lab_id, status, current_runtime_id, completed_at, last_activity_at)
- `lab_session_runtimes` – Runtime history per session (container_id, runtime_kind, namespace, URLs, status, restart_index)
- `lab_progress` – Gamification data per session (completed_steps, hints_used, attempts_per_step, score)

**Session statuses:** `created`, `in_progress`, `completed`

**Runtime statuses:** `created`, `starting`, `running`, `stopped`, `expired`, `error`

**Foreign Key:** `lab_progress.session_id → lab_sessions.session_id` (cascade delete)

---

### Labs DB (port 5437)

**Database:** `altair_labs_db`

**Tables:**

- `labs` – Lab metadata (creator_id, name, difficulty, category, lab_type, template_path, story, objectives)
- `lab_steps` – Ordered steps within a lab (unique `step_number` per lab)
- `lab_hints` – Ordered hints per step (unique `hint_number` per step)

**Foreign Keys:** Cascade delete from `labs → lab_steps → lab_hints`

---

## Project Structure

```
altair-infra/
├── docker-compose.yml              # Main orchestration file (7 services)
├── .env                            # Environment variables (NOT committed)
├── .env.example                    # Template for .env
│
├── postgres/                       # Database initialization scripts
│   ├── users/
│   │   └── altair_users_db.sql
│   ├── groups/
│   │   └── altair_groups_db.sql
│   ├── starpaths/
│   │   └── altair_starpaths_db.sql
│   ├── sessions/
│   │   └── altair_sessions_db.sql
│   └── labs/
│       └── altair_labs_db.sql
│
├── keycloak/
│   ├── realms/
│   │   └── altair-realm.json       # Auto-imported realm config
│   ├── themes/
│   │   └── altair/
│   │       └── login/              # Custom login theme
│   │           ├── theme.properties
│   │           ├── login.ftl
│   │           ├── resources/css/style.css
│   │           └── resources/img/  # altair-star.png, titre.png
│   └── Dockerfile                  # (unused, reference only)
│
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── datasource.yml      # TestData datasource
│       └── dashboards/
│           ├── dashboard.yml
│           └── altair-poc.json     # Pre-built dashboard
│
└── lab-base/
    └── Dockerfile                   # Base Alpine image for labs
```

---

## Keycloak Configuration

### Issuer URLs (Public vs Internal)

When working with OAuth2/OIDC, the issuer URL must match the context:

- **Public issuer (host / browser / gateway on host):**  
  `KEYCLOAK_ISSUER_PUBLIC=http://localhost:${KEYCLOAK_PORT}/realms/altair`

- **Internal issuer (containers inside Docker network):**  
  `KEYCLOAK_ISSUER_INTERNAL=http://keycloak:8080/realms/altair`

This repository exposes both variables in `.env.example` to avoid ambiguity.


### Auto-Imported Realm

**Realm name:** `altair`

**Realm roles:**

- `admin` – Full platform access
- `creator` – Can create labs, starpaths, groups
- `learner` – Can consume learning content

**Pre-configured clients:**

| Client ID | Type | Redirect URIs | Purpose |
| --- | --- | --- | --- |
| `frontend` | Public | http://localhost:5173/* | Web application (PKCE flow) |
| `gateway` | Confidential | /* | Backend service authentication |

### Custom Theme

Keycloak uses the **Altaïr custom theme** for login pages:

- Custom CSS styling (`resources/css/style.css`)
- Branded logo (`resources/img/titre.png`, `altair-star.png`)
- Modified login template (`login.ftl`)

**Theme location:** `/opt/keycloak/themes/altair` (mounted from `./keycloak/themes/`)

### Admin Access

- **URL:** http://localhost:8080
- **Admin Console:** http://localhost:8080/admin
- **Credentials:** Defined in `.env` file (`KC_BOOTSTRAP_ADMIN_USERNAME` / `KC_BOOTSTRAP_ADMIN_PASSWORD`)

---

## Grafana Configuration

### Pre-Provisioned Datasources

- **TestData DB** (type: `testdata`) – Generates fake metrics for PoC dashboards

### Pre-Loaded Dashboard

**Dashboard:** "Altaïr PoC Dashboard"  

**Folder:** "Altaïr"

**Panels:**

- Spawn Attempts (simulated)
- Active Sessions (simulated)

**Purpose:** Demonstrate observability architecture without backend dependencies.

### Admin Access

- **URL:** http://localhost:4000
- **Credentials:** `admin` / `admin` (change on first login)

---

## Lab Base Image

The `lab-base/` directory contains a Dockerfile for building lab environment templates:

**Base:** Alpine Linux  

**Installed packages:** `bash`, `coreutils`, `curl`, `nano`  

**User:** Non-root user `student` (UID configurable)  

**Workdir:** `/home/student`  

**Entrypoint:** `bash`

**Build command:**

```bash
cd lab-base
docker build -t altair-lab-base:latest .
```

**Note:** This image is NOT started by `docker-compose.yml`. It serves as a parent image for lab-specific containers.

---

## Troubleshooting

### Reset Databases (Delete All Data)

```bash
# Stop services and remove volumes
docker compose down -v

# Restart (will re-initialize schemas)
docker compose up -d
```

### Force Rebuild Without Cache

```bash
docker builder prune -af
docker compose up --build --force-recreate
```

### Check Service Health

```bash
# View all container statuses
docker compose ps

# Wait for Grafana and Keycloak HTTP endpoints to respond
make health
```

### Connect to PostgreSQL

```bash
# Example: Connect to Users DB
psql -h localhost -p 5433 -U altair -d altair_users_db

# Password: altair
```

### Keycloak Not Starting

**Symptom:** Keycloak container exits immediately.

**Solution:** Ensure `.env` file exists with required variables:

```bash
KC_BOOTSTRAP_ADMIN_USERNAME=admin
KC_BOOTSTRAP_ADMIN_PASSWORD=admin
```

### Database Schema Not Initialized

**Symptom:** Tables are missing after first startup.

**Cause:** PostgreSQL only runs init scripts on **empty volumes**.

**Solution:**

```bash
# Remove volumes and restart
docker compose down -v
docker compose up -d
```

---

## Known Limitations

### 🟡 Current Constraints

- **Dev-mode Keycloak:** Uses embedded `dev-file` database (not production-ready)
- **No Prometheus/Loki:** Grafana uses TestData only (metrics collection not wired)
- **No automated backups:** Data persistence relies on Docker volumes
- **Ports:** Defaults are provided, but all exposed ports can be overridden via `.env` (see `.env.example`).


### 🟡 Security Notes

- **Default credentials** for all services (must change for production)
- **No TLS/SSL** – HTTP only (suitable for local dev only)
- **Permissive CORS** in Keycloak client configs

---

## Development Workflow

### Starting a Local Dev Session

```bash
# 1. Start infrastructure
cd altair-infra
docker compose up -d

# 2. Wait for services to be healthy (~30 seconds)
docker compose logs -f keycloak | grep "Running the server"

# 3. Start Gateway (separate terminal)
cd ../altair-gateway
cargo run

# 4. Start Frontend (separate terminal)
cd ../altair-frontend
npm run dev

# 5. Open browser
# Frontend: http://localhost:5173
# Keycloak: http://localhost:8080
# Grafana: http://localhost:4000
```

### Stopping the Stack

```bash
# Stop infrastructure (preserves data)
cd altair-infra
docker compose down

# Gateway and Frontend: Ctrl+C in their terminals
```

---

## CI/CD Notes

### Docker Compose in CI

This infrastructure can be used in GitHub Actions or GitLab CI:

```yaml
# Example: GitHub Actions
services:
  postgres-users:
    image: postgres:14
    env:
      POSTGRES_DB: altair_users_db
      POSTGRES_USER: altair
      POSTGRES_PASSWORD: altair
    ports:
      - 5433:5432
```

**Not recommended:** Running full `docker-compose.yml` in CI (too heavy). Use individual service definitions instead.

---

## Project Status

**✅ Current Status: Stable – Local Development Ready**

This infrastructure is **production-ready for local development** and provides a realistic environment for Altaïr platform development.

**Future Improvements:**

- [ ]  Add Prometheus/Loki for real metrics collection
- [ ]  Implement Keycloak with PostgreSQL backend (instead of `dev-file`)
- [ ]  Add automated backup scripts for PostgreSQL volumes
- [ ]  Create Kubernetes manifests for cloud deployment
- [ ]  Add health check endpoints for all services
- [ ]  Implement secrets management (Vault integration)

**Maintainers:** Altaïr Platform Team

---

## Related Repositories

This infrastructure is part of the Altaïr platform ecosystem:

- **altair-gateway** – API Gateway (Rust, not included in compose)
- **altair-frontend** – Web application (React/Vue, not included in compose)
- **altair-users-ms** – Users microservice
- **altair-groups-ms** – Groups microservice
- **altair-starpaths-ms** – Starpaths microservice
- **altair-sessions-ms** – Lab sessions microservice
- **altair-labs-ms** – Labs microservice

**Repository layout expectation:**

```
~/dev/altair/
├── altair-infra/          # This repository
├── altair-gateway/
├── altair-frontend/
└── altair-*-ms/           # Microservices
```

---

## License

Internal Altaïr Platform Infrastructure – Not licensed for external use.
