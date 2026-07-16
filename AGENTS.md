# AGENTS.md

## This is a template repo

This repository is a **FastAPI + uv project boilerplate** intended to be cloned/copied as
the starting point for new Python web service projects. When you begin work on a real
project, you **must** update the following files to match the new project's identity:

| File | What to update |
|------|---------------|
| `pyproject.toml` | `name`, `version`, `description`, `requires-python`, dependencies |
| `README.md` | Replace entirely with project-specific documentation |
| `AGENTS.md` | Replace entirely with project-specific agent instructions |
| `.python-version` | Set the target Python version for the project |
| `LICENSE` | Update the copyright holder |
| `.env.example` | Add project-specific environment variables |
| `app/main.py` | Replace boilerplate `/health` endpoint with actual application logic |
| `app/config.py` | Extend `Settings` with project-specific config fields |
| `tests/` | Replace sample tests with tests for the actual project |

## Commands

Prefer the local uv workflow for development — it's faster than the container. Use the
container to verify runtime behavior.

| Task | Command |
|------|---------|
| Install/sync deps | `make install` (= `uv sync`) |
| Lint | `make lint` (= `uv run ruff check .`) |
| Format | `make format` (= `uv run ruff format .`) |
| Typecheck | `make typecheck` (= `uv run mypy .`) |
| All tests | `make test` (= `uv run pytest`) |
| Single test | `uv run pytest tests/test_main.py::test_health_returns_ok` |
| **Quality gate** | `make check` (lint + typecheck + test; must pass before committing) |
| Dev server (local) | `uv run uvicorn app.main:app --reload` |
| Dev container | `make up` / `make down` / `make logs` / `make shell` |
| Prod image | `make build-prod` / `make run-prod` |

Pytest is configured with `-q` in `pyproject.toml`; add `-v` explicitly if you need
verbose output.

## Conventions

- **uv** manages everything. Never `pip install`; run tools via `uv run <tool>`.
  `uv.lock` is committed and enforces reproducible installs.
- All tool config lives in `pyproject.toml`: Ruff (`E`, `F`, `I`, `UP`, `B`, `SIM` rules,
  line length 100), Mypy (**strict mode**), Pytest (`testpaths = ["tests"]`).
- Mypy strict applies to `tests/` too — annotate every test function (`-> None`).
- Imports are sorted by Ruff's `I` rule; `make format` + `make lint` fix most style issues.
- No comments unless truly necessary — code should be self-documenting.
- Tests mirror the `app/` package structure, use `fastapi.testclient.TestClient` for
  endpoints and `unittest.mock.patch` / `patch.dict` for mocking.

## Adding or removing a dependency

1. `uv add <pkg>` (or `uv add --dev <pkg>` for tooling) — this updates `pyproject.toml`
   and `uv.lock`; commit both.
2. If application code imports the package, **also add it to the mypy hook's
   `additional_dependencies` in `.pre-commit-config.yaml`** — the pre-commit mypy runs in
   an isolated env and will otherwise fail with missing-import errors on commit.
3. If the dev container is running, run `make sync` — the container's venv lives in a
   named volume, so host-side `uv sync` does not update it.

## Gotchas

- **`.env` leaks into tests.** `Settings` reads `.env` at instantiation and
  `app/config.py` creates a module-level `settings` singleton at import time. Tests
  assert the default values (`app_env == "dev"` etc.), so a local `.env` with non-default
  values will break them. Never commit `.env`; use `patch.dict(os.environ, ...)` in tests.
- **Python version lives in four places.** `.python-version` is the source of truth (the
  Makefile reads it and passes it to Docker as a build arg), but `requires-python`,
  `[tool.ruff] target-version`, and `[tool.mypy] python_version` in `pyproject.toml` must
  be updated to match.
- **Pre-commit hooks modify files.** Ruff runs with `--fix` on commit; if a hook changes a
  file, re-stage and commit again.
- **`make down` deletes the container venv** (`docker compose down -v` removes the named
  `venv` volume) — the next `make up` reinstalls from scratch.

## Docker layout

- `Dockerfile` is multi-stage: `base` → `builder` → `prod` / `dev`.
- **dev** target: full toolchain, hot reload; source is bind-mounted by compose, venv kept
  in a named volume.
- **prod** target: non-root user, only `.venv` copied from builder, `HEALTHCHECK` against
  `/health`.

## When making changes

1. Write or update tests first (`tests/`).
2. Implement in `app/`.
3. Run `make check` — lint, typecheck, and tests must all pass.
4. For dependency changes, follow the checklist above (lockfile + pre-commit mypy deps).
5. Do **not** commit `.env` files or secrets.
