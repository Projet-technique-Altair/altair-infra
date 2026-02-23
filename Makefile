# ============================================
# Altaïr Infra - Makefile
# ============================================

SHELL := /bin/sh

# Allow overriding ports from env/.env
GRAFANA_PORT ?= 4000
KEYCLOAK_PORT ?= 8080
PROMETHEUS_PORT ?= 9090
LOKI_PORT ?= 3100
CADVISOR_PORT ?= 8080
PROMTAIL_PORT ?= 9080

COMPOSE := docker compose
OBS := $(COMPOSE) --profile observability

.DEFAULT_GOAL := help

.PHONY: help up down restart ps status logs clean reset \
        obs-up obs-down obs-restart obs-ps obs-logs \
        health health-core health-obs

help:
	@echo "Altaïr Infra commands:"
	@echo ""
	@echo "Core stack:"
	@echo "  make up         - Start core services"
	@echo "  make down       - Stop core services"
	@echo "  make restart    - Restart core services"
	@echo "  make ps         - Show core container status"
	@echo "  make logs       - Follow core logs"
	@echo "  make clean      - Stop + remove volumes (DANGER: deletes data)"
	@echo "  make reset      - Clean then up"
	@echo ""
	@echo "Observability profile:"
	@echo "  make obs-up     - Start observability services (profile)"
	@echo "  make obs-down   - Stop observability services (profile)"
	@echo "  make obs-ps     - Show observability status"
	@echo "  make obs-logs   - Follow observability logs"
	@echo ""
	@echo "Health checks:"
	@echo "  make health     - Check core + observability endpoints"
	@echo "  make health-core- Check Grafana + Keycloak only"
	@echo "  make health-obs - Check Prometheus + Loki (+ optional cAdvisor/Promtail)"
	@echo ""

# ----------------------------
# Core stack
# ----------------------------

up:
	$(COMPOSE) up -d --remove-orphans

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

ps:
	$(COMPOSE) ps

status: ps

logs:
	$(COMPOSE) logs -f

clean:
	$(COMPOSE) down -v

reset: clean up

# ----------------------------
# Observability profile
# ----------------------------

obs-up:
	$(OBS) up -d --remove-orphans

obs-down:
	$(OBS) down

obs-restart:
	$(OBS) restart

obs-ps:
	$(OBS) ps

obs-logs:
	$(OBS) logs -f

# ----------------------------
# Health checks helpers
# ----------------------------

define wait_http_ok
	@name="$(1)"; url="$(2)"; \
	i=0; \
	while [ $$i -lt 30 ]; do \
		if curl -fsS "$$url" >/dev/null 2>&1; then \
			echo "$$name: OK"; \
			exit 0; \
		fi; \
		i=$$((i+1)); \
		sleep 2; \
	done; \
	echo "$$name: TIMEOUT ($$url)"; \
	exit 1
endef

health-core:
	@echo "== Docker services (core) =="
	@$(COMPOSE) ps
	@echo ""

	@echo "== Core endpoints =="
	$(call wait_http_ok,Grafana,http://localhost:$(GRAFANA_PORT)/api/health)
	@curl -fsS http://localhost:$(GRAFANA_PORT)/api/health | head -c 200 && echo
	@echo ""

	@echo "== Keycloak realm endpoints =="
	@i=0; \
	while [ $$i -lt 30 ]; do \
		code=$$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$(KEYCLOAK_PORT)/realms/master || echo 000); \
		if [ "$$code" = "200" ]; then \
			echo "Keycloak: OK"; \
			break; \
		fi; \
		i=$$((i+1)); \
		sleep 2; \
	done; \
	if [ $$i -ge 30 ]; then \
		echo "Keycloak: TIMEOUT"; \
		exit 1; \
	fi
	@curl -fsS -o /dev/null -w "master realm: %{http_code}\n" http://localhost:$(KEYCLOAK_PORT)/realms/master
	@curl -fsS -o /dev/null -w "altair realm: %{http_code}\n" http://localhost:$(KEYCLOAK_PORT)/realms/altair
	@echo ""

health-obs:
	@echo "== Docker services (observability) =="
	@$(OBS) ps || true
	@echo ""

	@echo "== Observability endpoints =="
	$(call wait_http_ok,Prometheus,http://localhost:$(PROMETHEUS_PORT)/-/ready)
	@curl -fsS http://localhost:$(PROMETHEUS_PORT)/-/ready && echo
	@echo ""

	$(call wait_http_ok,Loki,http://localhost:$(LOKI_PORT)/ready)
	@curl -fsS http://localhost:$(LOKI_PORT)/ready && echo
	@echo ""

	@echo "== Optional endpoints (won't fail if missing) =="
	@curl -fsS http://localhost:$(CADVISOR_PORT)/metrics >/dev/null 2>&1 && echo "cAdvisor: OK" || echo "cAdvisor: SKIP (not running)"
	@curl -fsS http://localhost:$(PROMTAIL_PORT)/ready >/dev/null 2>&1 && echo "Promtail: OK" || echo "Promtail: SKIP (not running)"
	@echo ""

health: health-core health-obs