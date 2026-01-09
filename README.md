# Altair Infra – Proof of Concept Infrastructure

This repository contains the Docker-based infrastructure for the Altaïr platform PoC (Proof of Concept).
It bundles the following components:

- **Lab API Service (mock)** – A Rust microservice that simulates lab creation / destruction.
- **Grafana** – A monitoring dashboard using the built-in TestData datasource.
- **Docker Compose stack** – A simple local environment replicating the overall structure of the Altaïr backend.

This PoC does **not** spawn real containers.  
It is designed to demonstrate the *architecture, observability, and service integration* expected in the full project.

---

## 📦 Project Structure

altair-infra/
│
├── docker-compose.yml # Orchestration for the entire PoC
├── grafana/
│ └── provisioning/
│ ├── datasources/ # Provisioned fake datasource (TestData)
│ │ └── datasource.yml
│ └── dashboards/ # Pre-created dashboard for PoC
│ ├── dashboard.yml
│ └── altair-poc.json
│
└── README.md



The companion repository used in this stack is:
../altair-lab-api-service



Ensure both repositories are located side-by-side in your filesystem.

---

## 🚀 Running the Stack

Inside this folder:

```bash
docker compose up --build
```

This command will:

Build the Rust service from altair-lab-api-service/

Start the mock Lab API service on http://localhost:8085

Start Grafana on http://localhost:3000


Grafana credentials:
user: admin
password: admin


## 🧪 Testing the Lab API Service
Health check:
curl http://localhost:8085/health

Spawn lab:
curl -X POST http://localhost:8085/spawn \
  -H "Content-Type: application/json" \
  -d '{"lab_id": "intro-linux"}'

Stop lab:
curl -X POST http://localhost:8085/spawn/stop \
  -H "Content-Type: application/json" \
  -d '{"container_id": "mock-container"}'


## FOR NOW 📊 Grafana Dashboard

Grafana loads a pre-built dashboard automatically at startup.
It is available under the folder "Altaïr" inside the Grafana UI.

Panels included:

Spawn Attempts (fake)

Active Sessions (fake)

These values use Grafana's TestData DB datasource to simulate metrics.

This allows the project to demonstrate observability and monitoring with zero backend dependencies.

## 🛠️ Notes for Developers
Repository layout expected:
~/.../GitHub/
    altair-infra/
    altair-lab-api-service/


If placed elsewhere, update this path inside docker-compose.yml:

context: ../altair-lab-api-service

Rebuild without cache:
docker builder prune -af
docker compose up --build --no-cache

### 1. Lancer l’infra
cd altair-infra
docker compose up -d

### 2. Lancer la gateway
cd ../altair-gateway
cargo run

### 3. Lancer le frontend
cd ../altair-frontend
npm run dev
