# FastAPI + uv Boilerplate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a ready-to-clone FastAPI boilerplate with `uv`-managed dependencies, a best-practice multi-stage Dockerfile (dev + prod), a compose-based dev workflow, and pre-wired quality tooling.

**Architecture:** A single packaged Python project (`app`) built by hatchling. `uv` manages dependencies and the lockfile. One multi-stage `Dockerfile` yields a `dev` target (dev tools + hot-reload, source bind-mounted via compose) and a `prod` target (slim, non-root, project installed into `.venv`). A `Makefile` exposes both a container path (`docker compose`) and a local path (`uv run …`).

**Tech Stack:** Python 3.13, uv 0.8.x, FastAPI, uvicorn[standard], Ruff, Mypy, Pytest, httpx (TestClient), pre-commit, Docker (multi-stage), Docker Compose.

## Global Constraints

- Python version: **3.13** (`requires-python = ">=3.13"`, `.python-version` = `3.13`, Docker `ARG PYTHON_VERSION=3.13`).
- Package name: **`app`**; FastAPI entrypoint: **`app.main:app`**; app port: **8000**.
- All `uv sync` invocations in Docker use `--locked` (fail on lockfile drift, never re-resolve).
- uv-in-Docker best practices are mandatory: pinned uv image `ghcr.io/astral-sh/uv:0.8.11`, `UV_COMPILE_BYTECODE=1`, `UV_LINK_MODE=copy`, `UV_PYTHON_DOWNLOADS=0`, cache mount `/root/.cache/uv`, bind-mounted `uv.lock`/`pyproject.toml` in the deps-only layer.
- prod image runs as a **non-root** user and copies **only** `/app/.venv` from the builder (project is installed non-editable into it).
- `pyproject.toml` MUST NOT set a `readme` field (the Docker build context excludes `*.md`, so a `readme` reference would break the wheel build).
- Do not commit `.env`; only `.env.example` is tracked.

---

## File Structure

- `pyproject.toml` — project metadata, runtime deps, dev dependency group, tool config (ruff/mypy/pytest), hatchling build.
- `.python-version` — `3.13` for local uv interpreter selection.
- `uv.lock` — generated, committed.
- `app/__init__.py` — marks the package.
- `app/main.py` — FastAPI app + `GET /health`.
- `tests/__init__.py` — marks the tests package.
- `tests/test_main.py` — TestClient test for `/health`.
- `Dockerfile` — multi-stage: `base` → `builder` → `prod` / `dev`.
- `.dockerignore` — trims the build context.
- `docker-compose.yml` — dev service (bind-mount source, named `venv` volume, port 8000, reload).
- `.env.example` — placeholder env for compose.
- `.pre-commit-config.yaml` — ruff + mypy hooks.
- `Makefile` — modify existing; keep `claude`, add compose + uv targets.
- `README.md` — modify existing; quickstart for both paths.
- `.gitignore` — verify it ignores `.env` and `.venv`; append if missing.

---

### Task 1: uv project scaffold + FastAPI health endpoint (TDD core)

Delivers the working, testable Python application: `uv sync` succeeds, `uv run pytest` passes, and ruff/mypy configs are valid.

**Files:**
- Create: `pyproject.toml`
- Create: `.python-version`
- Create: `app/__init__.py`
- Create: `app/main.py`
- Create: `tests/__init__.py`
- Create: `tests/test_main.py`
- Generated: `uv.lock` (by `uv sync`)

**Interfaces:**
- Consumes: nothing (first task).
- Produces:
  - Package `app` importable; module `app.main` exposing `app: fastapi.FastAPI`.
  - `GET /health` → `200`, JSON body `{"status": "ok"}`.
  - `uv.lock` committed at repo root (consumed by the Docker builds in Task 2/3).
  - Dev tools available via `uv run`: `ruff`, `mypy`, `pytest`.

- [ ] **Step 1: Create `pyproject.toml`**

```toml
[project]
name = "app"
version = "0.1.0"
description = "FastAPI + uv project boilerplate"
requires-python = ">=3.13"
dependencies = [
    "fastapi>=0.115",
    "uvicorn[standard]>=0.30",
]

[dependency-groups]
dev = [
    "ruff>=0.8",
    "mypy>=1.13",
    "pytest>=8",
    "httpx>=0.27",
    "pre-commit>=4",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["app"]

[tool.ruff]
line-length = 100
target-version = "py313"

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM"]

[tool.mypy]
python_version = "3.13"
strict = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-q"
```

- [ ] **Step 2: Create `.python-version`**

```
3.13
```

- [ ] **Step 3: Create the package marker `app/__init__.py`** (empty file so the editable install has a package to bind to)

```python
```

- [ ] **Step 4: Sync dependencies and generate the lockfile**

Run: `uv sync`
Expected: creates `.venv/` and `uv.lock`; installs fastapi, uvicorn, ruff, mypy, pytest, httpx, pre-commit, and the `app` project (editable). No errors.

- [ ] **Step 5: Create the tests package marker `tests/__init__.py`** (empty)

```python
```

- [ ] **Step 6: Write the failing test `tests/test_main.py`**

```python
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_returns_ok() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
```

- [ ] **Step 7: Run the test to verify it fails**

Run: `uv run pytest tests/test_main.py -v`
Expected: FAIL — collection/import error `ModuleNotFoundError: No module named 'app.main'`.

- [ ] **Step 8: Implement `app/main.py`**

```python
from fastapi import FastAPI

app = FastAPI(title="app")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
```

- [ ] **Step 9: Run the test to verify it passes**

Run: `uv run pytest tests/test_main.py -v`
Expected: PASS — `test_health_returns_ok`.

- [ ] **Step 10: Verify lint and type-check configs work**

Run: `uv run ruff check . && uv run ruff format --check . && uv run mypy .`
Expected: ruff reports "All checks passed!" and no format diffs; mypy reports "Success: no issues found". If ruff-format reports a diff, run `uv run ruff format .` and re-run.

- [ ] **Step 11: Commit**

```bash
git add pyproject.toml .python-version uv.lock app tests
git commit -m "feat: scaffold uv-managed FastAPI app with health endpoint and tests"
```

---

### Task 2: Multi-stage Dockerfile + .dockerignore

Delivers a production image that builds and serves `/health`, plus a `dev` target that builds.

**Files:**
- Create: `.dockerignore`
- Create: `Dockerfile`

**Interfaces:**
- Consumes: `pyproject.toml`, `uv.lock`, `app/` from Task 1.
- Produces:
  - Build targets `prod` and `dev` (referenced by compose in Task 3 and the Makefile in Task 4).
  - prod image serves `uvicorn app.main:app` on port 8000 as non-root.

- [ ] **Step 1: Create `.dockerignore`** (keep `pyproject.toml`, `uv.lock`, `app/`; exclude the rest)

```
.git
.gitignore
.venv
__pycache__/
*.py[cod]
.pytest_cache/
.mypy_cache/
.ruff_cache/
.env
docs/
*.md
Makefile
docker-compose.yml
.pre-commit-config.yaml
tests/
```

- [ ] **Step 2: Create `Dockerfile`**

```dockerfile
# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.13

# --- base: shared uv setup ------------------------------------------------
FROM python:${PYTHON_VERSION}-slim AS base
COPY --from=ghcr.io/astral-sh/uv:0.8.11 /uv /uvx /bin/
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0
WORKDIR /app

# --- builder: install deps then the project (non-editable) ----------------
FROM base AS builder
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-dev
COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev --no-editable

# --- prod: slim, non-root, only the venv ----------------------------------
FROM python:${PYTHON_VERSION}-slim AS prod
RUN groupadd --system app && useradd --system --gid app --home-dir /app app
WORKDIR /app
COPY --from=builder --chown=app:app /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
USER app
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# --- dev: full toolchain, hot-reload; source bind-mounted at runtime ------
FROM base AS dev
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project
ENV PATH="/app/.venv/bin:$PATH"
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

- [ ] **Step 3: Build the prod image**

Run: `docker build --target prod -t app:prod .`
Expected: build succeeds through all stages; final image tagged `app:prod`.

- [ ] **Step 4: Run the prod image and verify `/health`**

Run:
```bash
docker run --rm -d -p 8000:8000 --name app-prod-test app:prod
sleep 2
curl -s localhost:8000/health
docker stop app-prod-test
```
Expected: `curl` prints `{"status":"ok"}`.

- [ ] **Step 5: Build the dev target to confirm it compiles**

Run: `docker build --target dev -t app:dev .`
Expected: build succeeds.

- [ ] **Step 6: Commit**

```bash
git add Dockerfile .dockerignore
git commit -m "feat: add multi-stage uv Dockerfile (dev + prod targets)"
```

---

### Task 3: docker-compose dev service + .env.example

Delivers the primary dev workflow: `docker compose up` builds the dev target, mounts source, preserves the container venv, and serves with hot-reload.

**Files:**
- Create: `docker-compose.yml`
- Create: `.env.example`

**Interfaces:**
- Consumes: the `dev` build target from Task 2.
- Produces: an `app` compose service on port 8000 (used by Makefile `up`/`down`/`logs`/`shell`/`sync` in Task 4).

- [ ] **Step 1: Create `.env.example`**

```
# Copy to .env (`cp .env.example .env`). Loaded by docker compose.
# Add project environment variables here.
# APP_ENV=dev
# LOG_LEVEL=info
```

- [ ] **Step 2: Create `docker-compose.yml`**

```yaml
services:
  app:
    build:
      context: .
      target: dev
      args:
        PYTHON_VERSION: "${PYTHON_VERSION:-3.13}"
    ports:
      - "8000:8000"
    env_file:
      - path: .env
        required: false
    volumes:
      - .:/app
      - venv:/app/.venv
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

volumes:
  venv:
```

- [ ] **Step 3: Bring the dev service up and verify `/health`**

Run:
```bash
docker compose up --build -d
sleep 3
curl -s localhost:8000/health
```
Expected: `{"status":"ok"}`. (The named `venv` volume is seeded from the image, so `app.main` imports despite the `.:/app` bind mount.)

- [ ] **Step 4: Verify hot-reload picks up source edits**

Run:
```bash
docker compose logs --tail=5 app
```
Expected: logs show `Uvicorn running` with `reload` enabled (e.g. a "Started reloader process" line). Then tear down:
```bash
docker compose down -v
```

- [ ] **Step 5: Commit**

```bash
git add docker-compose.yml .env.example
git commit -m "feat: add docker compose dev service with hot-reload"
```

---

### Task 4: Makefile targets, pre-commit hooks, README, gitignore check

Delivers the developer interface (both paths), commit hooks, and documentation. Final integration task.

**Files:**
- Modify: `Makefile` (currently contains only a `claude` target)
- Create: `.pre-commit-config.yaml`
- Modify: `README.md` (currently `# python-project-boilerplate`)
- Modify: `.gitignore` (append only if `.env`/`.venv` not already ignored)

**Interfaces:**
- Consumes: uv targets from Task 1, Docker targets from Task 2, compose service from Task 3.
- Produces: `make` entrypoints; pre-commit config; user-facing docs.

- [ ] **Step 1: Confirm `.gitignore` ignores `.env` and `.venv`**

Run: `grep -nE '^\.env$|^\.venv|^venv/' .gitignore || echo "MISSING"`
Expected: matches for both `.env` and a venv entry. If `MISSING`, append this block to `.gitignore`:

```
# Local env and virtualenv
.env
.venv/
```

- [ ] **Step 2: Replace `Makefile` with the full target set (keeping `claude`)**

```makefile
.DEFAULT_GOAL := help
COMPOSE := docker compose

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
	docker build --target prod -t app:prod .

run-prod:  ## Run the production image on :8000
	docker run --rm -p 8000:8000 app:prod

## --- Agent ---
claude:  ## Run Claude Code with skipped permissions
	claude --dangerously-skip-permissions
```

- [ ] **Step 3: Verify the local quality gate passes via make**

Run: `make check`
Expected: ruff, mypy, and pytest all pass (same green results as Task 1 Step 10 + Step 9).

- [ ] **Step 4: Create `.pre-commit-config.yaml`**

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.6
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.14.1
    hooks:
      - id: mypy
        additional_dependencies: [fastapi]
```

- [ ] **Step 5: Verify pre-commit runs clean on all files**

Run: `uv run pre-commit run --all-files`
Expected: ruff, ruff-format, and mypy hooks all pass (may show "Passed"). If a hook auto-fixes formatting, re-run until clean, then `git add -A` the changes.

- [ ] **Step 6: Replace `README.md` with the quickstart**

```markdown
# python-project-boilerplate

A FastAPI project boilerplate with `uv`-managed dependencies and a best-practice
multi-stage Docker setup (dev + prod). Write your logic in `app/`; the runtime,
dependencies, containerization, and quality tooling are already wired.

## Requirements

- [uv](https://docs.astral.sh/uv/) (for the local path)
- Docker + Docker Compose (for the container path)

## Quickstart — container (recommended)

```bash
cp .env.example .env      # optional; compose runs without it too
make up                   # builds the dev image, serves on :8000 with hot-reload
curl localhost:8000/health   # -> {"status":"ok"}
```

Edit files in `app/`; uvicorn reloads automatically. `make down` stops it.

## Quickstart — local (uv, no Docker)

```bash
make install              # uv sync -> .venv
make test                 # pytest
uv run uvicorn app.main:app --reload
```

## Common tasks

| Command | What it does |
|---|---|
| `make help` | List all targets |
| `make check` | Ruff lint + Mypy + Pytest (CI gate) |
| `make lint` / `make format` | Ruff check / format |
| `make typecheck` | Mypy |
| `make hooks` | Install pre-commit hooks |
| `make up` / `make down` / `make logs` / `make shell` | Dev container lifecycle |
| `make sync` | Re-run `uv sync` inside the container after changing deps |
| `make build-prod` / `make run-prod` | Build / run the production image |
| `make claude` | Run Claude Code with skipped permissions |

## Layout

- `app/main.py` — FastAPI app + `GET /health`. Start here.
- `tests/` — pytest suite.
- `Dockerfile` — multi-stage (`dev`, `prod`).
- `docker-compose.yml` — dev service.
- `pyproject.toml` — deps + Ruff/Mypy/Pytest config.

## Changing the Python version

Update `.python-version`, `requires-python` in `pyproject.toml`, and build with
`--build-arg PYTHON_VERSION=3.xx` (or `PYTHON_VERSION=3.xx` in `.env` for compose).
```

- [ ] **Step 7: Commit**

```bash
git add Makefile .pre-commit-config.yaml README.md .gitignore
git commit -m "feat: add make targets, pre-commit hooks, and README quickstart"
```

---

## Self-Review

**1. Spec coverage:**
- Purpose / "just write logic in app/" → Task 1 (app scaffold) + Task 4 (README). ✓
- `uv`-managed clean runtime + `uv.lock` → Task 1. ✓
- Multi-stage Dockerfile, dev + prod → Task 2. ✓
- uv best practices (pinned image, cache/bind mounts, `--locked`, bytecode, link-mode, non-root, copy only `.venv`) → Task 2 Step 2 + Global Constraints. ✓
- Container path (compose + Makefile) → Task 3 + Task 4. ✓
- Local path (uv directly) → Task 1 + Makefile local targets + README. ✓
- Tooling: Ruff, Mypy, Pytest, pre-commit → Task 1 (config) + Task 4 (pre-commit). ✓
- `GET /health` app + sample test → Task 1. ✓
- Named `venv` volume to avoid host shadowing → Task 3 Step 2. ✓
- `.env.example` / `.dockerignore` / `.python-version` → Tasks 3/2/1. ✓
- Keep existing `claude` target → Task 4 Step 2. ✓
- Defaults: Python 3.13, port 8000, package `app` → Global Constraints. ✓

**2. Placeholder scan:** No TBD/TODO/"handle edge cases"; all code and commands are concrete. ✓

**3. Type consistency:** `app.main:app` (FastAPI instance) and `GET /health` → `{"status": "ok"}` are used identically across Task 1 (test + impl), Task 2 (Dockerfile CMD), Task 3 (compose command), and Task 4 (README). Build targets named `dev`/`prod` consistently in Dockerfile, compose, and Makefile. ✓
