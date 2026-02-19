.PHONY: up down restart ps status logs reset clean health

up:
	docker compose up -d --remove-orphans

down:
	docker compose down

restart:
	docker compose restart

ps:
	docker compose ps

status: ps

logs:
	docker compose logs -f
clean:
	docker compose down -v
reset:
	docker compose down -v
	docker compose up -d --remove-orphans

health:
	@echo "== Docker services =="
	@docker compose ps
	@echo ""

	@echo "== Waiting for Grafana =="
	@i=0; \
	while [ $$i -lt 30 ]; do \
		if curl -fsS http://localhost:$${GRAFANA_PORT:-4000}/api/health >/dev/null 2>&1; then \
			echo "Grafana: OK"; \
			break; \
		fi; \
		i=$$((i+1)); \
		sleep 2; \
	done; \
	if [ $$i -ge 30 ]; then \
		echo "Grafana: TIMEOUT"; \
		exit 1; \
	fi
	@curl -fsS http://localhost:$${GRAFANA_PORT:-4000}/api/health | head -c 200 && echo
	@echo ""

	@echo "== Waiting for Keycloak (realm endpoints) =="
	@i=0; \
	while [ $$i -lt 30 ]; do \
		code=$$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$${KEYCLOAK_PORT:-8080}/realms/master || echo 000); \
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
	@curl -fsS -o /dev/null -w "master realm: %{http_code}\n" http://localhost:$${KEYCLOAK_PORT:-8080}/realms/master
	@curl -fsS -o /dev/null -w "altair realm: %{http_code}\n" http://localhost:$${KEYCLOAK_PORT:-8080}/realms/altair
