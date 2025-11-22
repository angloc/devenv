.PHONY: up down build shell logs

up:
	docker-compose -f .devcontainer/docker-compose.yml up -d

down:
	docker-compose -f .devcontainer/docker-compose.yml down

build:
	docker-compose -f .devcontainer/docker-compose.yml build

shell:
	docker-compose -f .devcontainer/docker-compose.yml exec dev bash

logs:
	docker-compose -f .devcontainer/docker-compose.yml logs -f
