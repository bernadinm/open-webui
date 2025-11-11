
ifneq ($(shell which docker-compose 2>/dev/null),)
    DOCKER_COMPOSE := docker-compose
else
    DOCKER_COMPOSE := docker compose
endif

install:
	$(DOCKER_COMPOSE) up -d
	@echo "Waiting for service to be healthy and serving traffic..."
	@timeout=45; \
	while [ $$timeout -gt 0 ]; do \
		container_status=$$($(DOCKER_COMPOSE) ps --format json | jq -r '.[] | select(.Service=="open-webui") | .State'); \
		if [ "$$container_status" = "exited" ]; then \
			echo "✗ Container exited/crashed"; \
			$(DOCKER_COMPOSE) ps; \
			$(DOCKER_COMPOSE) logs; \
			exit 1; \
		fi; \
		if curl -f -s http://localhost:3001/ > /dev/null 2>&1; then \
			echo "✓ Service is healthy and serving traffic"; \
			$(DOCKER_COMPOSE) ps; \
			exit 0; \
		fi; \
		echo "Waiting... ($$timeout seconds remaining)"; \
		sleep 2; \
		timeout=$$((timeout-2)); \
	done; \
	echo "✗ Service failed to become healthy within 45 seconds"; \
	$(DOCKER_COMPOSE) ps; \
	$(DOCKER_COMPOSE) logs; \
	exit 1

remove:
	@chmod +x confirm_remove.sh
	@./confirm_remove.sh

start:
	$(DOCKER_COMPOSE) start
startAndBuild: 
	$(DOCKER_COMPOSE) up -d --build

stop:
	$(DOCKER_COMPOSE) stop

logs:
	$(DOCKER_COMPOSE) logs -f

update:
	# Calls the LLM update script
	chmod +x update_ollama_models.sh
	@./update_ollama_models.sh
	#@git pull
	$(DOCKER_COMPOSE) down
	# Make sure the ollama-webui container is stopped before rebuilding
	@docker stop open-webui || true
	$(DOCKER_COMPOSE) up --build -d
	$(DOCKER_COMPOSE) start

