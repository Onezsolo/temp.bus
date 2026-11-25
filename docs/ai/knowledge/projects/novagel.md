# novagel - central project knowledge

> Verified summary. Code, git and executed test evidence are authoritative. Read the actual files before changing them. Do not use this file as a substitute for source inspection.

## Identity

- Type: Laravel
- Repository: https://github.com/Onezsolo/novagel.git
- Current branch: patu/program-f99758f5
- Current HEAD: ee0f6c8
- Last commit: 2026-11-19T05:58:39Z - test: remove credential-like literals; docs: remove decorative build mark
- Workspace state at bootstrap: 0 changed path(s)

## Stack and architecture

Laravel monolith: routes in `routes/`, controllers in `app/Http/Controllers`, Blade views in `resources/views`, tests in `tests/`.

## Key paths

- `app`
- `routes`
- `resources`
- `database`
- `tests`
- `docs`
- `public`

## Rules and memory sources

- `AGENTS.md`
- `CLAUDE.md`

## Project documentation and memory

- `README.md`
- `AGENTS.md`
- `CLAUDE.md`

## Verification commands

- `vendor/bin/pint --test`
- `vendor/bin/phpstan analyse --memory-limit=256M`
- `php artisan test`

## Verified state

See `docs/ai/knowledge/VERIFIED_STATE.json` and `docs/ai/knowledge/CHANGELOG.md`. A checkpoint is not verified until tests or equivalent evidence are recorded.

## Architecture and decisions

Maintained by the knowledge-scribe after verified changes. Record decisions, constraints and important implementation references here; never invent a decision.

## Outstanding work and known issues

- Not yet recorded in central knowledge. Update from verified task handovers and project memory.