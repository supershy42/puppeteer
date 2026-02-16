# Configuration
DOCKER_COMPOSE := $(shell if command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; else echo "docker compose"; fi)
ENV_FILE="$(shell pwd)/.env"

# Docker Compose targets
all: dir
	@$(DOCKER_COMPOSE) -f ./docker-compose.yml up -d

build: dir
	@$(DOCKER_COMPOSE) -f ./docker-compose.yml up -d --build

down:
	@$(DOCKER_COMPOSE) -f ./docker-compose.yml down -v

re: clean
	@$(DOCKER_COMPOSE) -f ./docker-compose.yml up -d

# Directory and environment setup
dir:
	@chmod +x init_project.sh
	@bash ./init_project.sh

clean: down
	@echo "Stopped project containers and removed project volumes."

fclean: clean
	@rm -rf $(ENV_FILE).bak 2>/dev/null || true
	@echo "Cleaning database bind mount directories..."
	@DATA_DIR="$$HOME/supershy/data"; \
	if [ -d "$$DATA_DIR" ]; then \
		echo "Removing data directories at $$DATA_DIR..."; \
		rm -rf "$$DATA_DIR/user" "$$DATA_DIR/chat" "$$DATA_DIR/game"; \
		echo "Database directories cleaned!"; \
	else \
		echo "No data directories found."; \
	fi

.PHONY: all build down re clean fclean dir
