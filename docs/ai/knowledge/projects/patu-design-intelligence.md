# patu-design-intelligence - central project knowledge

> Verified summary. Code, git and executed test evidence are authoritative. Read the actual files before changing them. Do not use this file as a substitute for source inspection.

## Identity

- Website group: **PATU Technologies** (`patu-studio`); role: **design**.

- Type: Python FastAPI + SvelteKit
- Repository: https://github.com/Onezsolo/patu-codes.git
- Current branch: design-intelligence
- Current HEAD: 8086b7b
- Last commit: 2026-11-21T10:07:30Z - docs: enforce WAF on patutrades and record evidence
- Workspace state at bootstrap: 0 changed path(s)

## Stack and architecture

FastAPI backend under `backend/app` with SQLAlchemy async and PostgreSQL/Redis; SvelteKit 2 + TypeScript frontend under `frontend/src`.

## Key paths

- `backend`
- `frontend`
- `worker`
- `companion`
- `docs`

## Rules and memory sources

- `AGENTS.md`

## Project documentation and memory

- `README.md`
- `AGENTS.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/ARCHITECTURE.md`
- `docs/LIMITATIONS.md`

## Verification commands

- `ruff check app tests`
- `mypy app`
- `pytest`
- `npm run check`
- `npm run build`

## Verified state

See `docs/ai/knowledge/VERIFIED_STATE.json` and `docs/ai/knowledge/CHANGELOG.md`. A checkpoint is not verified until tests or equivalent evidence are recorded.

## Architecture and decisions

Maintained by the knowledge-scribe after verified changes. Record decisions, constraints and important implementation references here; never invent a decision.

## Outstanding work and known issues

- Not yet recorded in central knowledge. Update from verified task handovers and project memory.