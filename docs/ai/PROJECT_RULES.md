# Project rules index (sanitized)

This is the house index of the AI rules that apply inside each child project. Project repositories remain the source of truth; agents must read the listed source files before working. Infrastructure credentials, secrets and customer data are deliberately not copied here.

## How to use this index

1. Read `../AGENTS.md` first.
2. Find the target project below.
3. Read every listed rule source inside the project, plus the project's `AGENTS.md`.
4. Follow the project's own verify commands from `projects.json`.
5. If a project rule changes, run `scripts/sync-rule-hashes.ps1` after reviewing the change so the audit lock matches.

`.claude/skills` entries are training sources, not just documentation. Activate the relevant `SKILL.md` when the task matches that domain.

## AFA-GHANA

- Repository: `https://github.com/Onezsolo/afa.git` (`main`)
- Rule sources: `AFA-GHANA/AGENTS.md`, `AFA-GHANA/CLAUDE.md`
- Claude skills (read the relevant `SKILL.md` when the task matches): `.claude/skills/deploying-to-cloud/`, `infer-conventions/`, `laravel-best-practices/`, `tailwindcss-development/`, `testing-best-practices/`.
- The `AGENTS.md` file is the Laravel Boost bootstrap: verify PHP/Composer and install/refresh Laravel Boost before application work.
- The `CLAUDE.md` file contains the Laravel Boost guidelines: follow Laravel conventions, reuse existing components, add tests for behaviour changes, do not create documentation unless requested, do not change dependencies without approval, and never commit secrets.
- Verify: `php artisan test`, `vendor/bin/pint --test`.

## datatem

- Repository: `https://github.com/Onezsolo/datatem.git` (`main`)
- Rule sources: none.
- This is the clean base clone. House rules apply. Do not confuse it with the working `one-system` checkout; do not merge or copy uncommitted work between them without explicit instruction.
- Verify: `php artisan test`.

## novagel

- Repository: `https://github.com/Onezsolo/novagel.git` (`patu/program-f99758f5`)
- Rule sources: `novagel/AGENTS.md`, `novagel/CLAUDE.md`
- Laravel 13, PHP 8.3, PSR-12.
- `vendor/bin/pint --test` and `vendor/bin/phpstan analyse --memory-limit=256M` must pass.
- Add feature tests for new behaviour; database changes require a migration, model updates and factory/seed coverage where applicable.
- Never commit secrets or real credentials; document variables in `.env.example` and the README.
- Admin and web authentication use separate guards.
- CI uses SQLite `:memory:` from `phpunit.xml`; keep local commands consistent.
- Do not push to `main` directly; work on a branch and open a pull request.

## one-system

- Repository: `https://github.com/Onezsolo/datatem.git` (`feat/one-system-foundation`)
- Rule sources: none.
- House rules apply. This is the active unified Laravel build; it is a separate checkout of the datatem remote, not a folder inside `datatem`.
- Verify: `php artisan test`, `npm run build` (Laragon Node path if `npm` is not on PATH).
- Public pages follow the house public page standard in `../AGENTS.md` section 8.

## patu-design-intelligence

- Repository: `https://github.com/Onezsolo/patu-codes.git` (`design-intelligence`)
- Rule sources: `patu-design-intelligence/AGENTS.md`
- Non-negotiable stack: Python 3.12+ FastAPI + SQLAlchemy 2.0 async; SvelteKit 2 + TypeScript + Svelte 5; PostgreSQL and Redis. No React, Vue, PHP, second ORM, second state library or second CSS framework.
- Verify: backend `ruff check app tests`, `ruff format --check app tests`, `mypy app`, `pytest`; frontend `npm run check`, `npm run build`; e2e `npm run test:e2e` with local API and dev server.
- Preserve tenant isolation: every workspace-owned query filters `workspace_id`; cross-tenant tests are mandatory for new resources.
- Never log or return provider API keys, JWTs, worker secrets or password hashes.
- Provider calls go through `app/services/ai/gateway.py`; never call a provider from a route.
- AI work must never be reported successful if the provider call failed.
- No destructive database, deployment or credential operation without an approval record for high/critical risk.
- Do not deploy to production, push migrations to production or restart existing VPS applications during development.
- Commits are made per milestone only after tests pass.
- Design tokens live in `frontend/src/lib/styles/tokens.css`; do not hardcode colours in components.
- `docs/specs/` contains approved implementation references; see `docs/IMPLEMENTATION_STATUS.md` before expanding scope.

## patu-research

- Repository: `https://github.com/Onezsolo/patu-research.git` (`main`)
- Rule sources: `patu-research/AGENTS.md`
- Stack: Python 3.13 FastAPI + asyncpg, PostgreSQL and Redis; Next.js/TypeScript frontend under `frontend/`.
- Read `README.md`, `PATU_CONTEXT.md`, `PRE_LAUNCH.md`, `PRODUCTION_READINESS.md` and `SECURITY_SELFCHECK.md` before changing code.
- Verify: `pytest`; in `frontend/`, `npm run build` and `npm run lint`.
- Never commit `.env*` values, API keys or credentials.

## patu-technologies

- Repository: `https://github.com/Onezsolo/patu-codes.git` (`main`)
- Rule sources: `patu-technologies/AGENTS.md`
- The stack, commands, tenant isolation, provider gateway, no-secret, destructive-operation, deployment, milestone-commit, token and roadmap rules are the same as `patu-design-intelligence`.
- Additional takeover rule: an agent taking over a session, worktree, branch or task must finish the unfinished work before closing. Inspect `git status`, recent commits, failing tests, TODOs and partial state; complete or explicitly hand over every modified/untracked item, skipped verification and known breakage; leave a coherent state and report what remains. Never abandon modified/untracked source, skipped tests or a known broken build silently.

## PATUchat

- Repository: `https://github.com/Onezsolo/PATUchat.git` (`main`)
- Rule sources: `PATUchat/AGENTS.md`, `PATUchat/CLAUDE.md`
- Claude skills: `.claude/skills/deploying-to-cloud/`, `infer-conventions/`, `laravel-best-practices/`, `tailwindcss-development/`, `testing-best-practices/`.
- Laravel application with Laravel Boost bootstrap and guidelines. Follow the project's Laravel conventions, add tests for behaviour changes, do not create documentation unless requested, do not change dependencies without approval, and never commit secrets.
- Verify: `php artisan test`.

## patupa

- Repository: `https://github.com/Onezsolo/patupa.git` (`main`)
- Rule sources: `patupa/AGENTS.md`, `patupa/CLAUDE.md`, `patupa/.ai/rules/COMMUNICATION.md`, `patupa/.ai/rules/index.md`, `patupa/.ai/rules/PATUCHAT.md`
- Claude skills: `.claude/skills/deploying-to-cloud/`, `infer-conventions/`, `laravel-best-practices/`, `tailwindcss-development/`, `testing-best-practices/`.
- The full mandatory rules live in those files. Read them in full before patupa work. Summary:
  - Interaction rule: treat the user as a coequal professional; be direct and evidence-based; state assumptions and trade-offs; challenge weak assumptions.
  - Memory: read `docs/ai-memory/INDEX.md` before tasks; read `docs/implementation-notes.md` before changing provider routing, order statuses, wallet/refund flows, themes or authentication; update the memory docs after tasks. Never store credentials, secrets or customer personal data. Code is the source of truth.
  - Delivery: after implementation, commit the intended code, tests and memory docs; never stage unrelated files, generated assets or secrets. Give exact host commands, push to `origin/main` before giving the host pull command, and if the user holds the push, provide the local push command. This is the project's standing workflow; it applies inside patupa after the user has assigned implementation work and the relevant tests pass.
  - Hosting: the PATUtrade VPS is reserved for PATUtrade. Do not deploy PATUpaa there and do not recreate the removed PATUpaa storefront/staging deployment.
  - Provider catalog: fetch and group the provider catalog, let an admin select plans, persist provider codes, use update-only routine sync, keep one DataBundle per network+size, and treat `provider_products` as the only routing source. Do not create a separate PATUpaa network for multiple provider offers. New provider mappings are inactive until enabled; mappings are soft-deleted as tombstones so sync cannot recreate them.
  - Public service pages: every customer-facing service ships with a public marketing page under `/services/...`, a named route, SEO metadata and JSON-LD, a sitemap entry, a public navigation/home link and focused tests. The authenticated page is additional to the public page, never a replacement. Do not launch a service only behind login.
  - UI flexibility: fluid layouts; `min-w-0` on grid/flex children; responsive forms and tables; existing layout/theme classes; check roughly 360px, 768px and 1280px; keep detail pages compact.
  - Laravel Boost guidelines and PATUpaa engineering decisions apply.
- Verify: `php artisan test`, `php artisan patupaa:health-audit` (host deployment check).

## patupaa-worker

- Repository: `https://github.com/Onezsolo/patupa.git` (`feature/patu-dialer`)
- Rule sources: `patupaa-worker/AGENTS.md`, `patupaa-worker/CLAUDE.md`
- Claude skills: `.claude/skills/deploying-to-cloud/`, `infer-conventions/`, `laravel-best-practices/`, `tailwindcss-development/`, `testing-best-practices/`.
- This is a separate working copy of the patupa remote for the PATU Dialer worker, not the main `patupa` checkout. Do not mix changes between the two folders.
- The patupa project rules in the main `patupa` folder apply where relevant; keep the worker's own AGENTS/CLAUDE rules authoritative inside this checkout.
- Verify: `php artisan test`.

## Projects without a rule file

If a project has no `AGENTS.md` or rule source, the house rules apply, plus the project's README and the active plan. Do not invent project-specific rules. Add an `AGENTS.md` when the project gains its own policy.
