# Configuration
DOCKER_COMPOSE := $(shell if command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; else echo "docker compose"; fi)
DATA_PATH := /var/lib/supershy/data
ENV_FILE := srcs/.env

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
	@bash init_project.sh

clean: down
	@docker system prune --all --force

fclean: clean
	@docker system prune --all --force --volumes
	@docker network prune --force
	@docker volume prune --force
	@sudo rm -rf $(DATA_PATH)/*

.PHONY: all build down re clean fclean dir