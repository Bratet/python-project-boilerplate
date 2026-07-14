.DEFAULT_GOAL := help
COMPOSE := docker compose
PYTHON_VERSION := $(shell cat .python-version 2>/dev/null || echo "3.13")
export PYTHON_VERSION

.PHONY: help install lint format typecheck test check hooks up down logs shell sync build-prod run-prod claude

help:  ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "} {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

## --- Local (uv) ---
install:  ## uv sync the local venv
	uv sync

lint:  ## Ruff lint
	uv run ruff check .

format:  ## Ruff format
	uv run ruff format .

typecheck:  ## Mypy type-check
	uv run mypy .

test:  ## Run pytest
	uv run pytest

check: lint typecheck test  ## Lint + type-check + test (CI gate)

hooks:  ## Install pre-commit hooks
	uv run pre-commit install

## --- Container (compose) ---
up:  ## Build + start the dev container on :8000 (hot reload)
	$(COMPOSE) up --build

down:  ## Stop the dev container and remove its volumes
	$(COMPOSE) down -v

logs:  ## Follow dev container logs
	$(COMPOSE) logs -f

shell:  ## Open a shell in the running dev container
	$(COMPOSE) exec app bash

sync:  ## Re-run uv sync inside the dev container (after dep changes)
	$(COMPOSE) exec app uv sync

## --- Production image ---
build-prod:  ## Build the production image
	docker build --target prod --build-arg PYTHON_VERSION=$(PYTHON_VERSION) -t app:prod .

run-prod:  ## Run the production image on :8000
	docker run --rm -p 8000:8000 app:prod

## --- Agent ---
claude:  ## Run Claude Code with skipped permissions
	claude --dangerously-skip-permissions
