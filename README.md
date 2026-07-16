# python-project-boilerplate

> **This is a template repository.** Clone it as the starting point for a new project,
> then update `pyproject.toml`, `README.md`, `AGENTS.md`, `LICENSE`, `.python-version`,
> and `.env.example` to match your project's identity. See `AGENTS.md` for the full
> checklist.

A FastAPI project boilerplate with `uv`-managed dependencies and a best-practice
multi-stage Docker setup (dev + prod). Write your logic in `app/`; the runtime,
dependencies, containerization, and quality tooling are already wired.

## Requirements

- [uv](https://docs.astral.sh/uv/) (for the local path)
- Docker + Docker Compose CLI **v2.24+** (for the container path — the compose
  file uses the `env_file: required: false` long-form, which needs v2.24 or later)

## Quickstart — container (recommended)

```bash
cp .env.example .env      # optional; compose runs without it too
make up                   # builds the dev image, serves on :8000 with hot-reload
curl localhost:8000/health   # -> {"status":"ok"}
```

Edit files in `app/`; uvicorn reloads automatically. `make down` stops it.

The published host port defaults to `8000` but can be overridden with
`APP_PORT` if that port is already taken — e.g. `APP_PORT=8001 make up`, or set
`APP_PORT=8001` in `.env`.

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

> `make down` runs `docker compose down -v`, which also removes the named
> `venv` volume — the next `make up` will reinstall dependencies from scratch.

## Layout

- `app/main.py` — FastAPI app + `GET /health`. Start here.
- `tests/` — pytest suite.
- `Dockerfile` — multi-stage (`dev`, `prod`).
- `docker-compose.yml` — dev service.
- `pyproject.toml` — deps + Ruff/Mypy/Pytest config.

## Changing the Python version

Update `.python-version`, `requires-python` in `pyproject.toml`, and build with
`--build-arg PYTHON_VERSION=3.xx` (or `PYTHON_VERSION=3.xx` in `.env` for compose).
